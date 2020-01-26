use <./flight_controller_box_params.scad>;
use <./includes/rounded_cube.scad>;
use <./flight_controller_vert_screw_holes.scad>;

module pi_cutout() {
    pi_x = 65;
    pi_y = 95;
    pi_z = 26;
    translate([-pi_x/2, -pi_y/2, 12])
        rounded_cube([pi_x,pi_y,pi_z], radius=3);
}

module vertical_posts(hole_x, hole_y, bore_diameter, post_diameter, case_z, case_floor, fn) {
    difference() {
        union(){
            translate([hole_x/2, hole_y/2, case_floor])
                cylinder(d=post_diameter, h=case_z, $fn=fn);
            
            translate([-hole_x/2, hole_y/2, case_floor])
                cylinder(d=post_diameter, h=case_z, $fn=fn);
            
            translate([-hole_x/2, -hole_y/2, case_floor])
                cylinder(d=post_diameter, h=case_z, $fn=fn);
            
            translate([hole_x/2, -hole_y/2, case_floor])
                cylinder(d=post_diameter, h=case_z, $fn=fn);
        }
        union() {
            height = case_z + 2 * case_floor;
            flight_controller_vert_screw_holes(hole_x, hole_y, bore_diameter, height, fn);
            pi_cutout();
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

module flight_controller_wall_body(hole_x, hole_y, post_diameter, bore_diameter, case_z, case_floor, case_wall_thickness, case_wall_height, fn) {
    case_x = hole_x + post_diameter;
    case_y = hole_y + post_diameter;
    side_walls(case_x, case_y, hole_x, hole_y, case_floor, case_wall_thickness, case_wall_height, post_diameter);
    vertical_posts(hole_x, hole_y, bore_diameter, post_diameter, case_z, case_floor, fn);
}

module flight_controller_wall_body_part() {
    params = flight_controller_box_params();
    hole_x = find(params, "hole_x");
    hole_y = find(params, "hole_y");
    post_diameter = find(params, "post_diameter");
    bore_diameter = find(params, "bore_diameter");
    case_z = find(params, "case_z");
    case_floor = find(params, "case_floor");
    case_wall_thickness = find(params, "case_wall_thickness");
    case_wall_height = find(params, "case_wall_height");
    fn = find(params, "fn");
    flight_controller_wall_body(hole_x, hole_y, post_diameter, bore_diameter, case_z, case_floor, case_wall_thickness, fn);
}

flight_controller_wall_body_part();
