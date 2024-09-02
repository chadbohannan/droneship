

module fan_blade(fn) {
    difference() {
        cylinder(h = 6, r = 49.001, $fn=fn);
        cylinder(h = 6, r = 50, $fn=fn);            
    }
}

module motor_housing(fn) {
    cylinder(d = 27, h = 11);
    translate([0,0,11]) cylinder(d1 = 27, d2=10, h = 2);
}

module motor_mount(d, fn) {
    rotate([0,0,45]) {
        hull(){
            translate([d/2,0,0]) cylinder(d=5, h = 2, $fn=fn);
            translate([-d/2,0,0]) cylinder(d=5, h = 2, $fn=fn);
        }
        hull(){
            translate([0,d/2,0]) cylinder(d=5, h = 2, $fn=fn);
            translate([0,-d/2,0]) cylinder(d=5, h = 2, $fn=fn);
        }
        translate([0,0,2]) cylinder(d=12, h=3);
    }
}

module pins(h, fn) {
    hole_spc = 16;
    rotate([0,0,45]) {
        translate([hole_spc/2,0,0]) {
            cylinder(d=3, h = h, $fn=fn); // through-hole
            cylinder(d=5, h = 3, $fn=fn); // 3mm countersync
        }
        translate([-hole_spc/2,0,0]){
            cylinder(d=3, h = h, $fn=fn);
            cylinder(d=5, h = 3, $fn=fn);
        }
        translate([0,hole_spc/2,0]){
            cylinder(d=3, h = h, $fn=fn);
            cylinder(d=5, h = 3, $fn=fn);
        }
        translate([0,-hole_spc/2,0]){
            cylinder(d=3, h = h, $fn=fn);
            cylinder(d=5, h = 3, $fn=fn);
        }
    }
}

module stealth_2207_2450kV_motor(h, fn) {
    translate([0,0,17]) fan_blade(fn);
    translate([0,0,4]) motor_housing(fn);
    motor_mount(16, fn);
    translate([0,0,-h]) pins(h, fn);
}

stealth_2207_2450kV_motor(7, 60);