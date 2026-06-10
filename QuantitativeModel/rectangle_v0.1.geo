SetFactory("Built-in");

// Parameters
W = 2;     // Total width
H = 1;     // Total height
lc = 0.04; // Characteristic length (mesh size)

// Corner points
Point(1) = {-W/2, -H/2, 0, lc}; // Lower left
Point(2) = { W/2, -H/2, 0, lc}; // Lower right
Point(3) = { W/2,  H/2, 0, lc}; // Upper right
Point(4) = {-W/2,  H/2, 0, lc}; // Upper left

// Lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Line loop and surface
Line Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// Optional: Physical Groups
Physical Surface("domain") = {1};
Physical Line("boundary") = {1,2,3,4};