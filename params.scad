
function ducted_motor_mount_params() = [
    ["mounting_pin_diameter", 3], // 3mm metal screw
    ["mounting_block_height", 7], // mounting pin block hieght, through-hole length
    ["mounting_block_width", 10], // mounting pin block square width
    ["motor_mount_hole_space_3800kv", 12], // distance between adjacent holes in 3800kV motor
    ["mounting_arm_pin_to_motor_length", 58], // distance from motor center to mounting pin center
    ["shroud_height", 43.5], // case_z - 1.5
    ["shroud_radius", 51], // shroud radius, inner diameter, bottom edge
    ["counter_sink_depth", 2],
    ["fn", 60],
];  


function flight_controller_box_params() = [
    ["hole_x", 110],
    ["hole_y", 110],
    ["post_diameter", 10],
    ["bore_diameter", 3],
    ["case_z", 45],
    ["case_floor_thickness", 3],
    ["case_wall_thickness", 12],
    ["case_wall_height", 10],
    ["motor_mount_width", 10],
    ["motor_mount_height", 3],
    ["fn", 20],
];

// usage: find(params, "hole_x");
function find(h,k)= h[search([k], h, 1)[0]][1];
