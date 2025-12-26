// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and the OpenCASCADE kernel. 
// Getting this right was tricky, but it is now working as intended. See mwe_openCASCADE_{errors,works}.geo for more details.
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jul 2025

SetFactory("OpenCASCADE");

// Parameters for the Arctic Basin geometry
R  = 1.0;      // Radius of the top circles
H  = -1.0;     // Height of the cylinder
dH = 0.2*H;    // Height of the top rim
r  = R*0.6;    // Radius of the bottom circle

Cylinder(1) = {0, 0,  0, 0, 0,dH, R};
Cylinder(2) = {0,0,-dH/2,0,0,dH,r,2*Pi};
BooleanIntersection(10) = { Volume{1}; }{ Volume{2}; Delete; };
Geometry.OCCUnionUnify = 0;
BooleanUnion { Volume{10}; Delete; }{ Volume{1}; Delete; }

Cone(20)    = {0, 0, dH, 0, 0, H, R, r };
BooleanUnion { Volume{20}; Delete; }{ Volume{1}; Delete; }

Physical Surface("Slope", 22) = {1};
Physical Surface("Bottom") = {2};
Physical Surface("Wall", 19) = {3};
Physical Surface("FresheningPatch", 21) = {4};
Physical Surface("CoolingPatch") = {5};
Physical Volume("ArcticBasin", 23) = {1};