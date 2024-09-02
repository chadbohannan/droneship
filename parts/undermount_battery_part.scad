use<../models/ovonic_1550mAh_4S_lipo.scad>;

// TODO create a battery basket to sling under the flight control deck
module undermount_battery_part() {
    translate([0, 20, -20])
        lipo_battery();
    translate([0, -20, -20])
        lipo_battery();
}

 