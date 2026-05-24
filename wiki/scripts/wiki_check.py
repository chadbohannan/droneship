#!/usr/bin/env python3
"""
wiki_check.py — drone wiki maintenance utility

Usage:
  wiki_check.py [check...]   run named checks (default: all)

Checks:
  stubs        articles marked *(stub)* or in wiki/stubs/
  broken       broken markdown links
  deadlinks    external URLs returning non-200 or unreachable
  orphans      articles with no incoming links
  sparse       articles below word/section thresholds
  crosslinks   articles with few outgoing cross-links
  unlinted     articles missing <!-- linted: --> comment
  report       full report (all checks, summary table)
"""

import re
import sys
import urllib.request
import urllib.error
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# ── config ────────────────────────────────────────────────────────────────────

WIKI_ROOT   = Path(__file__).parent.parent
ARTICLE_DIR = WIKI_ROOT / "wiki" / "articles"
STUB_DIR    = WIKI_ROOT / "wiki" / "stubs"
INDEX       = WIKI_ROOT / "INDEX.md"

SPARSE_MIN_WORDS    = 150   # below this → sparse
SPARSE_MIN_SECTIONS = 2     # h2 headings below this → sparse
CROSSLINK_MIN_OUT   = 2     # outgoing article links below this → poorly linked
ORPHAN_MIN_IN       = 1     # incoming links below this → orphan

ANSI = {
    "red":    "\033[31m",
    "yellow": "\033[33m",
    "green":  "\033[32m",
    "cyan":   "\033[36m",
    "bold":   "\033[1m",
    "reset":  "\033[0m",
}

def c(color, text):
    return f"{ANSI[color]}{text}{ANSI['reset']}"

# ── helpers ───────────────────────────────────────────────────────────────────

def all_articles():
    """Yield every .md file under wiki/articles/ and wiki/stubs/."""
    for d in (ARTICLE_DIR, STUB_DIR):
        if d.exists():
            yield from d.rglob("*.md")

def rel(path: Path) -> str:
    """Path relative to wiki root for display."""
    return str(path.relative_to(WIKI_ROOT))

LINK_RE = re.compile(r'\[([^\]]*)\]\(([^)#\s][^)]*)\)')
LINK_WITH_FRAG_RE = re.compile(r'\[([^\]]*)\]\(([^)\s]+)\)')

def heading_anchors(path: Path) -> set[str]:
    """Return the set of valid anchor slugs for all headings in a markdown file."""
    anchors = set()
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        m = re.match(r'^#{1,6}\s+(.*)', line)
        if m:
            slug = m.group(1).strip().lower()
            slug = re.sub(r'[^\w\s-]', '', slug)
            slug = re.sub(r'[\s]+', '-', slug)
            anchors.add(slug)
    return anchors

def md_links(path: Path):
    """Yield (link_text, resolved_target_path) for every local .md link in a file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    for m in LINK_RE.finditer(text):
        raw = m.group(2)
        if raw.startswith("http://") or raw.startswith("https://"):
            continue
        # strip fragment
        raw = raw.split("#")[0]
        if not raw:
            continue
        target = (path.parent / raw).resolve()
        yield m.group(1), target

def md_links_with_anchors(path: Path):
    """Yield (link_text, resolved_target_path, anchor_or_None) for every local link."""
    text = path.read_text(encoding="utf-8", errors="replace")
    for m in LINK_WITH_FRAG_RE.finditer(text):
        raw = m.group(2)
        if raw.startswith("http://") or raw.startswith("https://"):
            continue
        parts = raw.split("#", 1)
        file_part = parts[0]
        anchor = parts[1] if len(parts) > 1 else None
        if not file_part:
            continue
        target = (path.parent / file_part).resolve()
        yield m.group(1), target, anchor

def md_external_links(path: Path):
    """Yield (link_text, url) for every external http(s) link in a file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    for m in LINK_RE.finditer(text):
        raw = m.group(2)
        if raw.startswith("http://") or raw.startswith("https://"):
            yield m.group(1), raw

def _check_url(url: str, timeout: int = 10) -> tuple[str, int | None, str]:
    """Return (url, status_code_or_None, error_message)."""
    req = urllib.request.Request(url, method="HEAD",
                                 headers={"User-Agent": "drone-wiki-checker/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return url, r.status, ""
    except urllib.error.HTTPError as e:
        # Some servers reject HEAD; retry with GET
        if e.code in (401, 403, 405):
            req2 = urllib.request.Request(url, method="GET",
                                          headers={"User-Agent": "drone-wiki-checker/1.0"})
            try:
                with urllib.request.urlopen(req2, timeout=timeout) as r:
                    return url, r.status, ""
            except urllib.error.HTTPError as e2:
                return url, e2.code, str(e2)
            except Exception as e2:
                return url, None, str(e2)
        return url, e.code, str(e)
    except Exception as e:
        return url, None, str(e)

def word_count(path: Path) -> int:
    text = path.read_text(encoding="utf-8", errors="replace")
    # strip code blocks and html comments before counting
    text = re.sub(r'```.*?```', '', text, flags=re.DOTALL)
    text = re.sub(r'<!--.*?-->', '', text, flags=re.DOTALL)
    return len(text.split())

def section_count(path: Path) -> int:
    return sum(1 for l in path.read_text(encoding="utf-8", errors="replace").splitlines()
               if re.match(r'^## ', l))

def is_stub(path: Path) -> bool:
    if path.is_relative_to(STUB_DIR):
        return True
    # only check the title line (first # heading), not body text
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("# "):
            return "*(stub)*" in line
    return False

def has_linted(path: Path) -> bool:
    return '<!-- linted:' in path.read_text(encoding="utf-8", errors="replace")

# ── build link graph ──────────────────────────────────────────────────────────

def build_graph():
    """
    Returns:
      articles   : set of resolved Paths for all articles
      outgoing   : {src_path: [target_path, ...]}   (only targets that exist)
      incoming   : {target_path: [src_path, ...]}
      broken     : {src_path: [(link_text, raw_target_path, anchor_or_None), ...]}
    """
    articles  = set(all_articles())
    outgoing  = defaultdict(list)
    incoming  = defaultdict(list)
    broken    = defaultdict(list)
    anchor_cache: dict[Path, set[str]] = {}

    def get_anchors(p: Path) -> set[str]:
        if p not in anchor_cache:
            anchor_cache[p] = heading_anchors(p)
        return anchor_cache[p]

    for src in articles:
        for text, target, anchor in md_links_with_anchors(src):
            if target in articles:
                outgoing[src].append(target)
                incoming[target].append(src)
                if anchor and anchor not in get_anchors(target):
                    broken[src].append((text, target, anchor))
            elif not target.is_file():
                broken[src].append((text, target, None))

    # also parse INDEX.md for incoming links (counts toward orphan detection)
    if INDEX.exists():
        for text, target in md_links(INDEX):
            if target in articles:
                incoming[target].append(INDEX)

    return articles, outgoing, incoming, broken

# ── checks ────────────────────────────────────────────────────────────────────

def check_stubs(articles):
    results = sorted(p for p in articles if is_stub(p))
    print(c("bold", f"\n── Stubs ({len(results)}) ──────────────────────────────"))
    if not results:
        print(c("green", "  none"))
    for p in results:
        print(f"  {c('yellow', rel(p))}")
    return results

def check_deadlinks(articles, workers=12):
    """Check all external URLs across every article; report non-200 / unreachable."""
    # Collect unique URLs with their source files
    url_sources: dict[str, list[tuple[Path, str]]] = defaultdict(list)
    for src in articles:
        for text, url in md_external_links(src):
            url_sources[url].append((src, text))

    if not url_sources:
        print(c("bold", "\n── Dead External Links (0) ──────────────────────────"))
        print(c("green", "  none"))
        return {}

    print(c("bold", f"\n── Dead External Links ──────────────────────────────"))
    print(f"  checking {len(url_sources)} unique URLs across {len(articles)} articles…")

    dead: dict[str, tuple[int | None, str, list[tuple[Path, str]]]] = {}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(_check_url, url): url for url in url_sources}
        for future in as_completed(futures):
            url, status, err = future.result()
            if status is None or status >= 400:
                dead[url] = (status, err, url_sources[url])

    if not dead:
        print(c("green", "  all OK"))
    else:
        for url in sorted(dead):
            status, err, sources = dead[url]
            label = str(status) if status else "unreachable"
            print(f"  {c('red', label)}  {url}")
            for src, text in sources:
                print(f"    in {c('yellow', rel(src))}  [{text}]")
            if err and not status:
                print(f"    error: {err}")
    return dead

def check_broken(broken):
    total = sum(len(v) for v in broken.values())
    print(c("bold", f"\n── Broken Links ({total}) ──────────────────────────────"))
    if not broken:
        print(c("green", "  none"))
    for src in sorted(broken):
        for text, target, anchor in broken[src]:
            print(f"  {c('red', rel(src))}")
            if anchor:
                print(f"    [{text}] → {c('yellow', rel(target))}#{c('red', anchor)}  (anchor not found)")
            else:
                print(f"    [{text}] → {c('red', rel(target))}  (file not found)")
    return broken

def check_orphans(articles, incoming):
    results = sorted(
        p for p in articles
        if not is_stub(p) and len(incoming.get(p, [])) < ORPHAN_MIN_IN
    )
    print(c("bold", f"\n── Orphans — no incoming links ({len(results)}) ──────────"))
    if not results:
        print(c("green", "  none"))
    for p in results:
        print(f"  {c('yellow', rel(p))}")
    return results

def check_sparse(articles):
    results = []
    for p in sorted(articles):
        if is_stub(p):
            continue
        wc = word_count(p)
        sc = section_count(p)
        if wc < SPARSE_MIN_WORDS or sc < SPARSE_MIN_SECTIONS:
            results.append((p, wc, sc))
    print(c("bold", f"\n── Sparse Articles ({len(results)}) ──────────────────────"))
    print(f"  thresholds: >{SPARSE_MIN_WORDS} words, >{SPARSE_MIN_SECTIONS} ## sections")
    if not results:
        print(c("green", "  none"))
    for p, wc, sc in results:
        flags = []
        if wc  < SPARSE_MIN_WORDS:    flags.append(c("yellow", f"{wc} words"))
        if sc  < SPARSE_MIN_SECTIONS: flags.append(c("yellow", f"{sc} sections"))
        print(f"  {rel(p)}  —  {', '.join(flags)}")
    return results

def check_crosslinks(articles, outgoing):
    results = []
    for p in sorted(articles):
        if is_stub(p):
            continue
        out = [t for t in outgoing.get(p, []) if t != p]
        if len(out) < CROSSLINK_MIN_OUT:
            results.append((p, out))
    print(c("bold", f"\n── Poorly Cross-Linked (<{CROSSLINK_MIN_OUT} outgoing links) ({len(results)}) ──"))
    if not results:
        print(c("green", "  none"))
    for p, out in results:
        print(f"  {c('yellow', rel(p))}  —  {len(out)} outgoing link(s)")
    return results

def check_unlinted(articles):
    results = sorted(
        p for p in articles
        if not is_stub(p) and not has_linted(p)
    )
    print(c("bold", f"\n── Unlinted Articles ({len(results)}) ────────────────────"))
    if not results:
        print(c("green", "  none"))
    for p in results:
        print(f"  {c('cyan', rel(p))}")
    return results

def report_summary(articles, stubs, broken_map, dead_map, orphans, sparse, crosslinks, unlinted):
    total_broken = sum(len(v) for v in broken_map.values())
    non_stubs = [p for p in articles if not is_stub(p)]
    print(c("bold", "\n── Summary ────────────────────────────────────────────"))
    rows = [
        ("Total articles",         len(articles),    False),
        ("  non-stub",             len(non_stubs),   False),
        ("  stubs",                len(stubs),        True),
        ("Broken links",           total_broken,      True),
        ("Dead external links",    len(dead_map),     True),
        ("Orphan articles",        len(orphans),      True),
        ("Sparse articles",        len(sparse),       True),
        ("Poorly cross-linked",    len(crosslinks),   True),
        ("Unlinted articles",      len(unlinted),     True),
    ]
    for label, val, warn in rows:
        color = ("green" if val == 0 else "red") if warn else "yellow"
        print(f"  {label:<26} {c(color, str(val))}")

# ── link-graph report ─────────────────────────────────────────────────────────

def top_linked(articles, incoming, n=10):
    print(c("bold", f"\n── Most-linked articles (top {n}) ──────────────────────"))
    ranked = sorted(articles, key=lambda p: len(incoming.get(p, [])), reverse=True)
    for p in ranked[:n]:
        count = len(incoming.get(p, []))
        print(f"  {count:3}  {rel(p)}")

# ── main ──────────────────────────────────────────────────────────────────────

ALL_CHECKS = ["stubs", "broken", "deadlinks", "orphans", "sparse", "crosslinks", "unlinted"]

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not args or "report" in args:
        run = ALL_CHECKS + ["summary", "top"]
    else:
        run = args

    print(c("bold", f"Drone Wiki — maintenance report"))
    print(f"Root: {WIKI_ROOT}")

    articles, outgoing, incoming, broken_map = build_graph()

    stubs      = check_stubs(articles)      if "stubs"      in run else []
    _broken    = check_broken(broken_map)   if "broken"     in run else {}
    dead_map   = check_deadlinks(articles)  if "deadlinks"  in run else {}
    orphans    = check_orphans(articles, incoming) if "orphans" in run else []
    sparse     = check_sparse(articles)     if "sparse"     in run else []
    crosslinks = check_crosslinks(articles, outgoing) if "crosslinks" in run else []
    unlinted   = check_unlinted(articles)   if "unlinted"   in run else []

    if "summary" in run or not args:
        report_summary(articles, stubs, broken_map, dead_map, orphans, sparse, crosslinks, unlinted)

    if "top" in run or not args:
        top_linked(articles, incoming)

    print()

if __name__ == "__main__":
    main()
