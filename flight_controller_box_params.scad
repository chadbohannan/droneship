
function flight_controller_box_params() = [
    ["hole_x", 67],
    ["hole_y", 97],
    ["post_diameter", 8],
    ["bore_diameter", 3],
    ["case_z", 45],
    ["case_floor", 1.5],
    ["case_wall_thickness", 2],
    ["case_wall_height", 20],
    ["fn", 20],
];

// usage: find(params, "hole_x");
function find(h,k)= h[search([k], h, 1)[0]][1];
