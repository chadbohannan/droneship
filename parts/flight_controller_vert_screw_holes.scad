
module flight_controller_vert_screw_holes(hole_x, hole_y, bore_diameter, height, fn) {
    translate([hole_x/2, hole_y/2, 0])
        cylinder(d=bore_diameter, h=height, $fn=fn);
    
    translate([-hole_x/2, hole_y/2, 0])
        cylinder(d=bore_diameter, h=height, $fn=fn);
    
    translate([-hole_x/2, -hole_y/2, 0])
        cylinder(d=bore_diameter, h=height, $fn=fn);
    
    translate([hole_x/2, -hole_y/2, 0])
        cylinder(d=bore_diameter, h=height, $fn=fn);
}