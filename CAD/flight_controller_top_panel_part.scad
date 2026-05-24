use <./flight_controller_box_params.scad>;
use <./flight_controller_face_panel_base.scad>;
use <./flight_controller_vert_screw_holes.scad>;

module flight_controller_top_panel(hole_x, hole_y, post_diameter, bore_diameter, z_pos, case_floor, fn) {
    translate([0, 0, z_pos])
        difference(){
            flight_controller_face_panel_base(hole_x, hole_y, post_diameter, bore_diameter, case_floor, fn);
            flight_controller_vert_screw_holes(hole_x, hole_y, bore_diameter, case_floor, fn);
        };
}

module flight_controller_top_panel_part() {
    params = flight_controller_box_params();
    hole_x = find(params, "hole_x");
    hole_y = find(params, "hole_y");
    post_diameter = find(params, "post_diameter");
    bore_diameter = find(params, "bore_diameter");
    //case_z = find(params, "case_z");
    case_floor = find(params, "case_floor");
    fn = find(params, "fn");
    flight_controller_top_panel(hole_x, hole_y, post_diameter, bore_diameter, 0, case_floor, fn);
}

flight_controller_top_panel_part();
