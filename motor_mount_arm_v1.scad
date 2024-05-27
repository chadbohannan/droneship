
fn = 20;
hole_spc = 12;
h = 7;

module motor_holes() {
    translate([0, -hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([0, -hole_spc/2, h-2])
        cylinder(2, 2, 2, $fn=fn);
    
    translate([0, hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([0, hole_spc/2, h-2])
        cylinder(2, 2, 2, $fn=fn);
    
    translate([-hole_spc/2, 0, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([-hole_spc/2, 0, h-2])
        cylinder(2, 2, 2, $fn=fn);
    
    translate([hole_spc/2, 0, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([hole_spc/2, 0, h-2])
        cylinder(2, 2, 2, $fn=fn);
    
    //motor bearing
    cylinder(h, 2, 2, $fn=fn);
}

module mount_arm() {
    w = 10;
    l = 70;
    difference() {
        union(){
            cylinder(h, 10, 10, $fn=fn);
            translate([0, -2, 0])
                cube([l, 4, h]);
            translate([l, 0, 0])
                rotate([0,0,45])
                    translate([-w/2, -w/2, 0])
                    cube([w, w, h]); // 18mm 
        }
        translate([l, 0, 0])
            cylinder(h=h, r=1.5, $fn=fn);
        /*
        translate([54, -8.3, 0])
            cylinder(h=h, r=6.32, $fn=fn);
        translate([55, 8.3, 0])
            cylinder(h=h, r=6.32, $fn=fn);
        */
    }
    
}


difference(){
    mount_arm();
    rotate([0,0,45])
        motor_holes();

    
    translate([65, -hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([65, hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    
    
}