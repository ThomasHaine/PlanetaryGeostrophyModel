// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// The geometry is defined using GMSH syntax and the OpenCASCADE kernel. 
// Getting this right was tricky, but it is now working as intended. See mwe_openCASCADE_{errors,works}.geo for more details.
//
// twnh Jul 2025

SetFactory("OpenCASCADE");
Geometry.OCCUnionUnify = 0;     // This set by default I think.

// Parameters for the Arctic Basin geometry
R  = 1.0;          // Radius of the top circles
H  = -0.5;         // Height of the cylinder
dH = 0.2*H;        // Height of the top rim
r  = R*0.6;        // Radius of the bottom circle
WP_theta = Pi/6 ;  // Angle for the warming patch
lcar1 = 0.075;     // Mesh size for the domain. 0.1 gives about 7000 tetrahedra, 0.075 gives about 18000 tetrahedra, and 0.05 gives about 49,000 tetrahedra.

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

MeshSize{ PointsOf{ Volume{:}; } } = lcar1;

Physical Surface("Slope") = {1};
Physical Surface("WarmingPatch") = {3,7};
Physical Surface("Wall") = {2,4};
Physical Surface("Bottom") = {5};
Physical Surface("FresheningPatch") = {6};
Physical Surface("CoolingPatch") = {8};
Physical Volume("ArcticBasin") = {1};

Mesh 1;
Mesh 2;
// Mesh 3;             // Comment out to generate the bounding surface mesh only.
Save "ArcticBasin10.msh";