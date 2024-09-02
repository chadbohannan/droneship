use <./params.scad>;
use <./parts/ducted_motor_mount_4in_prop.scad>;
use <./parts/flight_controller_wall_body_part.scad>;
use <./parts/flight_controller_floor_panel_part.scad>;
use<./parts/flight_controller_top_panel_part.scad>;
use<./parts/undermount_battery_part.scad>;


module complete_assembly() {
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
    
    pad = 0;
    translate([0, 0, -pad])
        flight_controller_floor_panel(
            hole_x,
            hole_y,
            post_diameter,
            bore_diameter,
            case_floor,
            fn);
    translate([0, 0, case_z + 2*pad])
        flight_controller_top_panel(
            hole_x,
            hole_y,
            post_diameter,
            bore_diameter,
            case_floor,
            fn);
    
    flight_controller_wall_body(
        hole_x,
        hole_y,
        post_diameter,
        bore_diameter,
        case_floor,
        case_wall_thickness,
        case_wall_height,
        fn);

/*
    top_plate_mounting_faces(
        hole_x,
        hole_y,
        bore_diameter,
        post_diameter,
        case_z-case_wall_height,
        case_floor+case_wall_height + pad,
        fn);
*/

    motor_mount_params = ducted_motor_mount_params();
    translate([hole_x/2 + pad, hole_y/2 + pad, case_floor])
        rotate([0,0,-135])
            motor_mount_arm_part(motor_mount_params);
    translate([hole_x/2 + pad, -hole_y/2 - pad, case_floor])
        rotate([0,0,135])
            motor_mount_arm_part(motor_mount_params);
    translate([-hole_x/2 - pad, hole_y/2 + pad, case_floor])
        rotate([0,0,-45])
            motor_mount_arm_part(motor_mount_params);
    translate([-hole_x/2 - pad, -hole_y/2 - pad, case_floor])
        rotate([0,0,45])
            motor_mount_arm_part(motor_mount_params);
}

complete_assembly();

undermount_battery_part();