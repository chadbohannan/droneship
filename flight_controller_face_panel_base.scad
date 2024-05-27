use <./flight_controller_vert_screw_holes.scad>;

module flight_controller_face_panel_base(hole_x, hole_y, post_diameter, bore_diameter, case_floor_thickness, z_pos, fn) {
    translate([0,0,0])
        difference() {
            hull() {
            translate([hole_x/2, hole_y/2, 0])
                    cylinder(d=post_diameter, h=case_floor_thickness, $fn=fn);
                
                translate([-hole_x/2, hole_y/2, 0])
                    cylinder(d=post_diameter, h=case_floor_thickness, $fn=fn);
                
                translate([-hole_x/2, -hole_y/2, 0])
                    cylinder(d=post_diameter, h=case_floor_thickness, $fn=fn);
                
                translate([hole_x/2, -hole_y/2, 0])
                    cylinder(d=post_diameter, h=case_floor_thickness, $fn=fn);
        }
        flight_controller_vert_screw_holes(hole_x, hole_y, bore_diameter, case_floor, fn);      
    }
}
