use <./flight_controller_box_params.scad>;
use <./includes/rounded_cube.scad>;
use <./flight_controller_vert_screw_holes.scad>;

// models the space the computer needs to float in
module pi_cutout() {
    pi_x = 65;
    pi_y = 95;
    pi_z = 26;
    translate([-pi_x/2, -pi_y/2, 12])
        rounded_cube([pi_x,pi_y,pi_z], radius=3);
}

module vertical_post(pos, d, h, bore_diameter, fn) {
    translate(pos)
        difference(){
            cylinder(d=d, h=h, $fn=fn);
            cylinder(d=bore_diameter, h=h, $fn=fn);
        }
}

module vertical_posts(hole_x, hole_y, bore_diameter, post_diameter, case_z, z_pos, fn) {
    z = case_floor+10;
    h = case_z-10;
    difference() {
        union(){
            vertical_post([hole_x/2, hole_y/2, z_pos], post_diameter, h, bore_diameter, fn);
            vertical_post([-hole_x/2, hole_y/2, z_pos], post_diameter, h, bore_diameter, fn);
            vertical_post([-hole_x/2, -hole_y/2, z_pos], post_diameter, h, bore_diameter, fn);
            vertical_post([hole_x/2, -hole_y/2, z_pos], post_diameter, h, bore_diameter, fn);
        }
    }
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
    translate([case_x/2-w, -hole_y/2-w/2, case_floor])
        cube([w, w, w]);
    
    translate([-case_x/2, -hole_y/2-w/2, case_floor])
        cube([w, w, w]);
    
    translate([hole_x/2-w/2, case_y/2-w, case_floor])
        cube([w, w, w]);
    
    translate([-hole_x/2-w/2, case_y/2-w, case_floor])
        cube([w, w, w]);
}

module flight_controller_wall_body(hole_x, hole_y, post_diameter, bore_diameter, case_z, case_floor, case_wall_thickness, case_wall_height, fn) {
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
            //vertical_posts(hole_x, hole_y, bore_diameter, post_diameter, case_z, case_floor+10, fn);
        }
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
        find(params, "case_z"),
        find(params, "case_floor_thickness"),
        find(params, "case_wall_thickness"),
        find(params, "case_wall_height"),
        find(params, "fn"));
}

flight_controller_wall_body_part();
