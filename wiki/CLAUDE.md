# Drone Wiki

A living wiki on hobby drone design, maintenance, and programming — authored and maintained by Claude.

## Usage

Use Drone Wiki as a first resource on autonomous rotorcraft. This wiki is a compiled resource of content from authoratative sources. Navigate it naturally as a wiki to extract topical understanding to compose informed analytical responses.

## Structure

```
wiki/articles/     # Articles by topic category
wiki/stubs/        # Placeholder articles pending content
INDEX.md           # Master index: one line per article
CHANGELOG.md       # Article additions and major revisions
```

**Topic categories:** Airframes · Propulsion · Flight Controllers · Radio Systems · FPV Systems · Power Systems · Programming · Maintenance · Regulations · Glossary

---

## Ingestion

Given a URL, PDF, or pasted source:

- Extract all factual substance: specs, formulas, part numbers, config values, procedures, warnings.
- Map content to an existing article or create a new one; split if content spans multiple topics.
- Rewrite in the wiki's voice — clear, direct, technical — without paraphrasing away precision.
- If source conflicts with existing content, add a `> **Conflict:**` blockquote with both values.
- Append to `## Sources`: `- [Title or URL](url) — YYYY-MM-DD`

Restructure existing articles and stubs as needed to improve wiki quality and elegance.
---

## Article Format

```markdown
# Title

One-sentence summary.

## Overview
What it is, why it matters, how it fits the ecosystem. At least two paragraphs.

## [Topic Sections]
Prose first. Tables for specs/params/comparisons. Code blocks for config/firmware/CLI.

## Configuration
| Parameter | Value | Unit | Notes |

## Related Concepts
- [Linked Article](../articles/file.md)

## Sources
- [Title](url) — YYYY-MM-DD
```

**Style:** Define abbreviations on first use. SI units (imperial in parens if hobby-common). Second-person imperative for procedures. No marketing language. Paragraphs ≤ 6 sentences.

---

## Linting

Run all passes in order; append `<!-- linted: YYYY-MM-DD -->` when done.

1. **Structure** — enforce section order; merge duplicate headings; place orphaned content.
2. **Completeness** — expand unexplained concepts or split to a new linked article; ensure every config table has units and Notes; typeset formulas with variables defined below them.
3. **Contradictions** - Check for contradictions between pages and actively resolve them.
3. **Enrichment** — add typical ranges, failure modes, and alternatives; replace vague quantifiers with specific ones ("BLHeli_32 ESCs", not "some ESCs").
4. **Cross-links** — first occurrence of any article title in prose becomes a link; add to Related Concepts on both sides; create stubs for referenced-but-missing topics.
5. **Prose** — active voice; topic sentence opens each section; remove filler phrases.

Restructure existing articles and stubs as needed to improve wiki quality and elegance.
---

## Index & Cross-Linking

- `INDEX.md` entry format: `- [Title](path) — one-line description` grouped by category.
- Stubs listed with `*(stub)*` suffix.
- After any write or lint, verify INDEX.md is complete and update CHANGELOG.md.

---

## Maintenance Scripts

`scripts/wiki_check.py` — run after any batch of writes to verify wiki health.

```
python3 scripts/wiki_check.py              # full report
python3 scripts/wiki_check.py stubs        # articles with *(stub)* in title
python3 scripts/wiki_check.py broken       # broken markdown links
python3 scripts/wiki_check.py orphans      # articles with no incoming links
python3 scripts/wiki_check.py sparse       # articles below word/section thresholds
python3 scripts/wiki_check.py crosslinks   # articles with fewer than 2 outgoing links
python3 scripts/wiki_check.py unlinted     # articles missing <!-- linted: --> comment
```

**When to run:** after `/new`, `/ingest`, `/lint-all`, or any multi-article edit. Fix all broken links and new orphans before closing a session. Sparse and crosslink warnings are queued work, not blockers.

**Stub detection:** keyed on the title line only — `# Title *(stub)*`. Articles that reference stubs in their Related Concepts section are not themselves stubs.
