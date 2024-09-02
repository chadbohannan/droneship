module fan_blade(fn) {
    difference() {
        cylinder(h = 6, r = 49.001, $fn=fn);
        cylinder(h = 6, r = 50, $fn=fn);            
    }
}