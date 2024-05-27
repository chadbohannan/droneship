use <./flight_controller_box_params.scad>;
use <./flight_controller_wall_body_part.scad>;
use <./flight_controller_floor_panel_part.scad>;
use<./flight_controller_top_panel_part.scad>;
use<./motor_mount_arm_v2.scad>;

module flight_controll_box_assembly() {
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
      
    flight_controller_floor_panel(
        hole_x,
        hole_y,
        post_diameter,
        bore_diameter,
        case_floor,
        fn);
    flight_controller_top_panel(
        hole_x,
        hole_y,
        post_diameter,
        bore_diameter,
        case_z,
        case_floor,
        fn);    
    flight_controller_wall_body(
        hole_x,
        hole_y,
        post_diameter,
        bore_diameter,
        case_z,
        case_floor,
        case_wall_thickness,
        case_wall_height,
        fn);

    vertical_posts(
        hole_x,
        hole_y,
        bore_diameter,
        post_diameter,
        case_z,
        case_floor+7,
        fn);

    translate([hole_x/2, hole_y/2, case_floor])
        rotate([0,0,-135])
            motor_mount_arm_part();
    translate([hole_x/2, -hole_y/2, case_floor])
        rotate([0,0,135])
            motor_mount_arm_part();
    translate([-hole_x/2, hole_y/2, case_floor])
        rotate([0,0,-45])
            motor_mount_arm_part();
    translate([-hole_x/2, -hole_y/2, case_floor])
        rotate([0,0,45])
            motor_mount_arm_part();
}

flight_controll_box_assembly();
 