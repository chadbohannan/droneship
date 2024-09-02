use <../params.scad>;
use <../includes/rounded_cube.scad>;
use <./flight_controller_vert_screw_holes.scad>;



module vertical_hole(pos, bore_diameter, h, fn) {
    translate(pos)
        cylinder(d=bore_diameter, h=h, $fn=fn);
}

module vertical_holes(hole_x, hole_y, z_pos, bore_diameter, height, fn) {
    vertical_hole([hole_x/2, hole_y/2, z_pos], bore_diameter, height, fn);
    vertical_hole([-hole_x/2, hole_y/2, z_pos], bore_diameter, height, fn);
    vertical_hole([-hole_x/2, -hole_y/2, z_pos], bore_diameter, height, fn);
    vertical_hole([hole_x/2, -hole_y/2, z_pos], bore_diameter, height,  fn);
}

module top_plate_mounting_face(pos, d, h, bore_diameter, fn) {
    translate(pos)
        difference(){
            cylinder(d=d, h=h, $fn=fn);
            cylinder(d=bore_diameter, h=h, $fn=fn);
        }
}

module top_plate_mounting_faces(hole_x, hole_y, bore_diameter, post_diameter, height, z_pos, fn) {
    top_plate_mounting_face([hole_x/2, hole_y/2, z_pos], post_diameter, height, bore_diameter, fn);
    top_plate_mounting_face([-hole_x/2, hole_y/2, z_pos], post_diameter, height, bore_diameter, fn);
    top_plate_mounting_face([-hole_x/2, -hole_y/2, z_pos], post_diameter, height, bore_diameter, fn);
    top_plate_mounting_face([hole_x/2, -hole_y/2, z_pos], post_diameter, height, bore_diameter, fn);
}

module side_walls(case_x, case_y, hole_x, hole_y, case_floor, case_wall_thickness, case_wall_height, post_diameter) {
    translate([case_x/2-case_wall_thickness, -hole_y/2, case_floor])
        cube([case_wall_thickness, case_y-post_diameter, case_wall_height]);
    
    translate([-case_x/2, -hole_y/2, case_floor])
        cube([case_wall_thickness, case_y-post_diameter, case_wall_height]);
    
    translate([-hole_x/2, -case_y/2, case_floor])
        cube([case_x-post_diameter, case_wall_thickness, case_wall_height]);
    
    translate([-hole_x/2, case_y/2-case_wall_thickness, case_floor])
        cube([case_x-post_diameter, case_wall_thickness, case_wall_height]);
}

module lift_arm_mount_recess(case_x, case_y, hole_x, hole_y, case_floor, case_wall_thickness) {
    w = 10;
    h = 7;
    translate([case_x/2-w, -hole_y/2-w/2, case_floor])
        cube([w, w, h]);
    
    translate([-case_x/2, -hole_y/2-w/2, case_floor])
        cube([w, w, h]);
    
    translate([hole_x/2-w/2, case_y/2-w, case_floor])
        cube([w, w, h]);
    
    translate([-hole_x/2-w/2, case_y/2-w, case_floor])
        cube([w, w, h]);
}

module flight_controller_wall_body(hole_x, hole_y, post_diameter, bore_diameter, case_floor, case_wall_thickness, case_wall_height, fn) {
    case_x = hole_x + post_diameter;
    case_y = hole_y + post_diameter;
    difference() {
        union() {
            side_walls(case_x,
                case_y,
                hole_x,
                hole_y,
                case_floor,
                case_wall_thickness,
                case_wall_height,
                post_diameter);
            top_plate_mounting_faces(hole_x, hole_y, bore_diameter, post_diameter, 3, case_floor+7, fn);
        }
        vertical_holes(hole_x, hole_y, case_floor+7, bore_diameter, 3, fn);
        lift_arm_mount_recess(case_x, case_y, hole_x, hole_y, case_floor, case_wall_thickness);
    }
}

module flight_controller_wall_body_part() {
    params = flight_controller_box_params();
    flight_controller_wall_body(
        find(params, "hole_x"),
        find(params, "hole_y"),
        find(params, "post_diameter"),
        find(params, "bore_diameter"),
        find(params, "case_floor_thickness"),
        find(params, "case_wall_thickness"),
        find(params, "case_wall_height"),
        find(params, "fn"));
}

flight_controller_wall_body_part();
