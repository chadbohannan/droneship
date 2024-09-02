
module lipo_battery() {
    length = 74;
    height = 35;
    width = 34;
    tail_len = 80;
    tail_width = 10;
    tail_thickness = 5;
    translate([-length/2, -width/2, -height/2]){
        cube([length, width, height]);
        translate([length, width/2-tail_width/2, height-tail_thickness])
            cube([tail_len, tail_width, tail_thickness]);
    }
}

lipo_battery();