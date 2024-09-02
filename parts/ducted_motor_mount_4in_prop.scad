use <../models/stealth_2207_2450kV.scad>;
use <../params.scad>;


module fan_shroud(shroud_height, shroud_radius, fn) {
    r1 = shroud_radius +0;
    r2 = shroud_radius +2;  
    difference() {
        cylinder(h = shroud_height, r1 = r1+1, r2 = r2+1, $fn=fn);
        translate([0,0,-0.05])
            cylinder(h = shroud_height+0.1, r1 = r1, r2= r2, $fn=fn);
        
        // very large radius trim of the top-side to lighten ducting
        translate([-shroud_radius,100,398])
            rotate([90,0,0])
                cylinder(h=200, r= 370, $fn=100);
        
        /* wire throughhole routes wires across threaded bolt end
        translate([shroud_radius-3,0,12.5])
            rotate([0,90,0])
                cylinder(h=7, d=5, $fn=fn);
        */
    }
}


module mount_arm(h, w, l, fn) {
    // x,y center is the motor bearing
    difference() {
        union(){
            cylinder(h, 12, 12, $fn=fn); // motor mounting plate
            translate([-l+6.2, 0, h/2])
                scale([1,1,0.5])
                    rotate([0,90,0])
                        cylinder(h=2*l-6, d1=h, d2=2*h, $fn=fn); // beam
            translate([l, 0, 0])
                rotate([0,0,45])
                    translate([-w/2, -w/2, 0])
                        cube([w, w, h]); // mounting pin block
            
        }
        translate([l, 0, 0])
            cylinder(h=h, d=3, $fn=fn); // mounting pin through-hole
        
        translate([l-3,0,-4])
                rotate([0,-70,0])
                    cylinder(h=40, d=6, $fn=fn); // wiring through-hole
    }  
}

module top_plate_mounting_face(pos, d, bore_diameter, l, shroud_height, shroud_radius, fn) {
    r1 = shroud_radius +0;
    r2 = shroud_radius +2;
    difference(){
        translate(pos)
            translate([-10, 0, -3])
                rotate([0,30,0])
                    cylinder(d=d*2, h=20, $fn=fn); // top-plate mounting face
        translate([0,0,33])
            union() {
                cylinder(d=bore_diameter, h=shroud_height-33, $fn=fn); // top-plate mounting through-hole
                cylinder(d=bore_diameter+2, h=shroud_height-36.6, $fn=fn); // top-plate mounting counter-sink
            }
        translate([-l,0,0])
            cylinder(h = shroud_height+0.01, r1 = r1, r2= r2, $fn=fn); // primary ducting cutout
        translate([-13,-10, shroud_height])
            cube([25,20,10]); // top-plate mounting face cut-out
    }
}


module motor_mount_arm_part(params) {
    fn = find(params, "fn");
    h = find(params, "mounting_block_height"); // mounting pin block height, through-hole length 
    w = find(params, "mounting_block_width"); 
    l = find(params, "mounting_arm_pin_to_motor_length");// distance from motor center to mounting pin center
    hole_spc = 12;
    post_diameter = find(params, "mounting_block_height");
    bore_diameter = find(params, "mounting_pin_diameter");
    shroud_radius = find(params, "shroud_radius");
    shroud_height = find(params, "shroud_height");
    
    z_pos = 33.5; // shroud_height - 10
    top_plate_mounting_face([-2, 0, z_pos], post_diameter, bore_diameter, l, shroud_height, shroud_radius, fn);
    
    // translate origin from motor centor to part mount
    rotate([0,0,0])
    translate([-l,0,0])
        union() {
            fan_shroud(shroud_height, shroud_radius);
            
            difference(){
                mount_arm(h, w, l, fn);
                translate([0,0,h]) #stealth_2207_2450kV_motor(h, fn);
            }
        }
}

motor_mount_arm_part(ducted_motor_mount_params());
