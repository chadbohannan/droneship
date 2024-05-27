
fn = 20;
hole_spc = 12;
h = 7;
w = 10;
l = 70;


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
        // body attachemnt pin hole
        translate([l, 0, 0])
            cylinder(h=h, d=3, $fn=fn);
    }
    
}

module motor_mount_arm_part() {
    translate([-l,0,0])
    difference(){
        mount_arm();
        rotate([0,0,45])
            motor_holes();

        
        translate([65, -hole_spc/2, 0])
            cylinder(h, 1, 1, $fn=fn);
        translate([65, hole_spc/2, 0])
            cylinder(h, 1, 1, $fn=fn);
    }
}

motor_mount_arm_part();