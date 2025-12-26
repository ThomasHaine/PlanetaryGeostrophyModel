// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// The geometry is defined using GMSH syntax and the OpenCASCADE kernel. 
// Getting this right was tricky, but it is now working as intended. See mwe_openCASCADE_{errors,works}.geo for more details.
//
// twnh Jul 2025

SetFactory("OpenCASCADE");
Geometry.OCCUnionUnify = 0;     // This set by default I think.

// Parameters for the Arctic Basin geometry
// R  = 1000000;      // Radius of the top circles
// H  = -2000.0;      // Height of the cylinder
R  = 1.0;          // Radius of the top circles
H  = -0.5;         // Height of the cylinder
dH = 0.2*H;        // Height of the top rim
r  = R*0.6;        // Radius of the bottom circle
WP_theta = Pi/6 ;  // Angle for the warming patch

// Compute the coordinates for the warming patch
WP_r = R*Sqrt(2)*Sqrt(1 - Cos(WP_theta/2)); // Radius of the wall patch
WP_x = R*Cos(WP_theta/2); // X coordinate of the wall patch
WP_y = R*Sin(WP_theta/2); // Y coordinate of the wall patch

// Main cylinder
Cylinder(1) = {0, 0,  0, 0, 0,dH, R};
// Top circle to define the freshening patch and cooling patch
Cylinder(2) = {0,0,-dH/2,0,0,dH,r,2*Pi};
BooleanIntersection(10) = { Volume{1}; }{ Volume{2}; Delete; };
BooleanUnion { Volume{10}; Delete; }{ Volume{1}; Delete; }
// Side cylinder for the warming patch
Cylinder(3) = {WP_x,WP_y,-dH/2,0,0,2*dH,WP_r,2*Pi};
BooleanIntersection(11) = { Volume{1}; }{ Volume{3}; Delete; };
BooleanUnion { Volume{11}; Delete; }{ Volume{1}; Delete; }
// Deep part of the basin
Cone(20)    = {0, 0, dH, 0, 0, H, R, r };
BooleanUnion { Volume{20}; Delete; }{ Volume{1}; Delete; }

Physical Surface("Slope") = {1};
Physical Surface("WarmingPatch") = {3,7};
Physical Surface("Wall") = {2,4};
Physical Surface("Bottom") = {5};
Physical Surface("FresheningPatch") = {6};
Physical Surface("CoolingPatch") = {8};
Physical Volume("ArcticBasin") = {1};