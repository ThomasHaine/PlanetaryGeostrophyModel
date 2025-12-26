// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and includes circles, lines, and surfaces
// The final volume is created by combining surfaces and defining physical groups
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jul 2025

// This .geo file works.

SetFactory("OpenCASCADE");

// Parameters for the Arctic Basin geometry
// R  = 1.0e6;    // Radius of the top circles
// H  = -2000;    // Height of the cylinder
R  = 1.0;    // Radius of the top circles
H  = -1.0;    // Height of the cylinder
dH = 0.2*H;    // Height of the top rim
r  = R*0.6;    // Radius of the bottom circle
WP_theta = Pi/10; // Warming patch angle in radians

Disk(1) = {0, 0, 0, R};
Physical Surface("Top") = {1};        // top disk
out1[] = Extrude {0, 0, dH} { Surface {1}; } ;
Printf("Extruded tags '%g', '%g', '%g'", out1[0], out1[1], out1[2]);
// out1[0] is the bottom disk, out1[1] is the volume, out1[2] is the lateral wall
Physical Surface("Wall") = {out1[2]}; // lateral disk wall

Cone ( 10 ) = { 0, 0, dH, 0, 0, -1, R, r };
Physical Surface("Slope") = {4};
Physical Surface("Bottom") = {5};
// Physical Volume("Domain") = {out1[1],10};

// Define cooling patch and freshening patch
Disk(20) = {0, 0, 0, r};
// Physical Surface("CoolingPatch") = {20};
BooleanDifference(42) = { Surface{1};}{ Surface{20}; };
// Physical Surface("FresheningPatch") = {42};

// Define warming and salinification patch
out2[] = Extrude {{0,0,1}, {0,0,0}, WP_theta} { Line{2}; } ;    // Rotates the line by WP_theta radians
Printf("Extruded tags '%g', '%g', '%g', '%g'", out2[0], out2[1], out2[2], out2[3]);
// out2[0] is the rotated line, out2[1] is the created surface, out2[2] and out2[3] are the lateral walls
// Physical Surface("WarmingSalinificationPatch") = {out2[1]}; // lateral wall of the warming patch

Physical Volume("Domain") = {out1[1],10};