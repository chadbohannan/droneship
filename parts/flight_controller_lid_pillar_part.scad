use <./flight_controller_box_params.scad>;
use <./flight_controller_wall_body_part.scad>;

module flight_controller_lid_pillar_part() {
    params = flight_controller_box_params();
    hole_x = find(params, "hole_x");
    hole_y = find(params, "hole_y");
    post_diameter = find(params, "post_diameter");
    bore_diameter = find(params, "bore_diameter");
    case_z = find(params, "case_z");
    case_floor = find(params, "case_floor_thickness");
    case_wall_thickness = find(params, "case_wall_thickness");
    case_wall_height = find(params, "case_wall_height");
    fn = find(params, "fn");
    
    top_plate_mounting_face(
        [0, 0, 0],
        post_diameter,
        case_z-case_wall_height,
        bore_diameter,
        fn);
}

flight_controller_lid_pillar_part();
