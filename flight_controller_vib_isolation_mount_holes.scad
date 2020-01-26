
module flight_controller_vib_isolation_mount_holes(case_floor, fn) {
    cm_x = 43 /2;
    cm_y = 54 /2;

    translate([ cm_x, 0,0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([-cm_x, 0,0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([0, cm_y, 0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([0,-cm_y, 0])
        cylinder(d=3, h=case_floor, $fn=fn);
    
    s1 = 10;
    translate([ s1, s1,0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([-s1, s1,0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([s1, -s1, 0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([-s1,-s1, 0])
        cylinder(d=3, h=case_floor, $fn=fn);

    s2 = 15;
    translate([ s2, s2,0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([-s2, s2,0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([s2, -s2, 0])
        cylinder(d=3, h=case_floor, $fn=fn);
    translate([-s2,-s2, 0])
        cylinder(d=3, h=case_floor, $fn=fn);
    
    cylinder(d=16, h=case_floor, $fn=fn);
}
