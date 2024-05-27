
function flight_controller_box_params() = [
    ["hole_x", 80],
    ["hole_y", 110],
    ["post_diameter", 10],
    ["bore_diameter", 3],
    ["case_z", 45],
    ["case_floor_thickness", 1.5],
    ["case_wall_thickness", 12],
    ["case_wall_height", 10],
    ["motor_mount_width", 10],
    ["motor_mount_height", 3],
    ["fn", 20],
];

// usage: find(params, "hole_x");
function find(h,k)= h[search([k], h, 1)[0]][1];
