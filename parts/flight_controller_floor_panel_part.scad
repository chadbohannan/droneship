use <../params.scad>;
use <../includes/rounded_cube.scad>;
use <./flight_controller_face_panel_base.scad>;
use <./flight_controller_vib_isolation_mount_holes.scad>;
use <./flight_controller_vert_screw_holes.scad>;

// models the space the computer needs to float in
module pi_model(fn) {
    pi_x = 56;
    pi_y = 85;
    pi_z = 22;
    x = 48;
    y = 78;
    y_in = 20;
    translate([-pi_x/2, -pi_y/2, 9])
        rounded_cube([pi_x,pi_y,pi_z], radius=3);
    translate([x/2, y/2-y_in, 3])
        cylinder(h=6, d=4.5, $fn=6);
    translate([-x/2, y/2-y_in, 3])
        cylinder(h=6, d=4.5, $fn=6);
    translate([x/2, -y/2, 3])
        cylinder(h=6, d=4.5, $fn=6);
    translate([-x/2, -y/2, 3])
        cylinder(h=6, d=4.5, $fn=6);
    
    translate([x/2, y/2-y_in, 0])
        cylinder(h=6, d=3, $fn=fn);
    translate([-x/2, y/2-y_in, 0])
        cylinder(h=6, d=3, $fn=fn);
    translate([x/2, -y/2, 0])
        cylinder(h=6, d=3, $fn=fn);
    translate([-x/2, -y/2, 0])
        cylinder(h=6, d=3, $fn=fn);
}

module flight_controller_floor_panel(hole_x, hole_y, post_diameter, bore_diameter, case_floor, fn) {

    difference() {
        flight_controller_face_panel_base(hole_x, hole_y, post_diameter, bore_diameter, case_floor, fn);
        union(){
            flight_controller_vib_isolation_mount_holes(case_floor, fn);
            flight_controller_vert_screw_holes(hole_x, hole_y, bore_diameter, case_floor, fn);
        }
        translate([0, hole_y/2-10, 0])
            #cube([25, 6, 8], true);
        translate([0, -(hole_y/2-10), 0])
            #cube([25, 6, 8], true);
        
        translate([hole_x/2-10, 0, 0])
            #cube([6, 25, 8], true);
        translate([-(hole_x/2-10), 0, 0])
            #cube([6, 25, 8], true);   
        
        #pi_model(fn);
        rotate([0,0,180]) pi_model(fn);
    }
}

module flight_controller_floor_panel_part() {
    params = flight_controller_box_params();
    flight_controller_floor_panel(
        find(params, "hole_x"),
        find(params, "hole_y"),
        find(params, "post_diameter"),
        find(params, "bore_diameter"),
        find(params, "case_floor_thickness"),
        find(params, "fn"));
}

flight_controller_floor_panel_part();
