use <./flight_controller_box_params.scad>;
use <./flight_controller_face_panel_base.scad>;
use <./flight_controller_vib_isolation_mount_holes.scad>;
use <./flight_controller_vert_screw_holes.scad>;

module flight_controller_floor_panel(hole_x, hole_y, post_diameter, bore_diameter, z_pos, case_floor, fn) {
    translate([0, 0, z_pos])
        difference() {
            flight_controller_face_panel_base(hole_x, hole_y, post_diameter, bore_diameter, case_floor, fn);
            union(){
                flight_controller_vib_isolation_mount_holes(case_floor, fn);
                flight_controller_vert_screw_holes(hole_x, hole_y, bore_diameter, case_floor, fn);
            }
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
