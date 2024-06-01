
fn = 60;
hole_spc = 12;
h = 7;
w = 10;
l = 58;

shroud_height = 35;
shroud_radius = 52;

module fan_blade() {
    translate([0,0,20])
        difference() {
            cylinder(h = 6, r = 49.001, $fn=fn);
            cylinder(h = 6, r = 50, $fn=fn);            
        }
}

module fan_shroud() {
    difference() {
        cylinder(h = shroud_height, r = shroud_radius +1, $fn=fn);
        translate([0,0,-0.05])
            cylinder(h = shroud_height+0.1, r = shroud_radius , $fn=fn);
    }
}

module motor_holes() {
    translate([0, -hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([0, -hole_spc/2, 0])
        #cylinder(2, 2, 2, $fn=fn);
    
    translate([0, hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([0, hole_spc/2, 0])
        cylinder(2, 2, 2, $fn=fn);
    
    translate([-hole_spc/2, 0, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([-hole_spc/2, 0, 0])
        cylinder(2, 2, 2, $fn=fn);
    
    translate([hole_spc/2, 0, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([hole_spc/2, 0, 0])
        cylinder(2, 2, 2, $fn=fn);
    
    //motor bearing
    cylinder(h, 2, 2, $fn=fn);
}

module mount_arm() {
    difference() {
        union(){
            cylinder(h, 10, 10, $fn=fn);
            translate([-l+5, 0, h/2])
                scale([1,0.7,1])
                    rotate([0,90,0])
                        cylinder(h=2*l-4, d=h, $fn=fn);
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
    // translate origin from motor centor to part mount
    rotate([180,0,0])
    translate([-l,0,-h])
        union() {
            //fan_blade();
            fan_shroud();
            difference(){
                mount_arm();
                rotate([0,0,45])
                    motor_holes();
            }
        }
}

motor_mount_arm_part();
