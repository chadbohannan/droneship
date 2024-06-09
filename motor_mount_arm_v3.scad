
fn = 60;
hole_spc = 12;
h = 7;
w = 10;
l = 58;

shroud_height = 43.5;
shroud_radius = 52;

module fan_blade() {
    translate([0,0,20])
        difference() {
            cylinder(h = 6, r = 49.001, $fn=fn);
            cylinder(h = 6, r = 50, $fn=fn);            
        }
}

module fan_shroud() {
    r1 = shroud_radius +0;
    r2 = shroud_radius +2;
    difference() {
        cylinder(h = shroud_height, r1 = r1, r2 = r2, $fn=fn);
        translate([0,0,-0.05])
            cylinder(h = shroud_height+0.1, r1 = r1-1, r2= r2-1, $fn=fn);
        
    }
}

module motor_holes() {
    translate([0, -hole_spc/2, 0])
        cylinder(h, 1, 1, $fn=fn);
    translate([0, -hole_spc/2, 0])
        cylinder(2, 2, 2, $fn=fn);
    
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
            translate([-l+6.2, 0, h/2])
                scale([1,0.7,1])
                    rotate([0,90,0])
                        #cylinder(h=2*l-4, d=h, $fn=fn);
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

module vertical_post(pos, d, h, bore_diameter, fn) {
    r1 = shroud_radius +0;
    r2 = shroud_radius +1;
    difference(){
        translate(pos)
        translate([-10, 0, -3])
            rotate([0,30,0])
                cylinder(d=d*2, h=h, $fn=fn);
        translate([0,0,33])
            union() {
                cylinder(d=bore_diameter, h=shroud_height-33, $fn=fn);
                cylinder(d=bore_diameter+2, h=shroud_height-36.6, $fn=fn);
            }
        translate([-l,0,0])
            cylinder(h = shroud_height, r1 = r1, r2= r2, $fn=fn);
        translate([-13,-10, shroud_height])
            cube([25,20,10]);
    }
}


module motor_mount_arm_part() {
    post_diameter = 7;
    bore_diameter = 3;
    height = 20;
    z_pos = 33.5;
    vertical_post([-2, 0, z_pos], post_diameter, height, bore_diameter, fn);
    
    // translate origin from motor centor to part mount
    rotate([0,0,0])
    translate([-l,0,0])
        union() {
            #fan_blade();
            fan_shroud();
            
            difference(){
                mount_arm();
                rotate([0,0,45])
                    motor_holes();
            }
        }
}

motor_mount_arm_part();
