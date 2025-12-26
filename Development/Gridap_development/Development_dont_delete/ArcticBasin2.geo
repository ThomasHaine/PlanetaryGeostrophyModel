// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and includes circles, lines, and surfaces
// The final volume is created by combining surfaces and defining physical groups
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jul 2025

SetFactory("OpenCASCADE");

// Parameters for the Arctic Basin geometry
R  = 1.0;      // Radius of the top circles
H  = -1.0;     // Height of the cylinder
dH = H;        // Height of the top rim
r  = R*0.6;    // Radius of the bottom circle

Disk(1) = {0, 0, 0, R};
out1[] = Extrude {0, 0, dH} { Surface {1}; } ;
Printf("Extruded tags '%g', '%g', '%g'", out1[0], out1[1], out1[2]);
// out1[0] is the bottom disk, out1[1] is the volume, out1[2] is the lateral wall

// Define cooling patch and freshening patch
Disk(20) = {0, 0, 0, r};
// out2[] = Extrude {0, 0, dH} { Surface {20}; } ;
// Printf("Extruded tags '%g', '%g', '%g'", out2[0], out2[1], out2[2]);
// out2[0] is the bottom disk, out2[1] is the volume, out2[2] is the lateral wall

BooleanDifference(42) = { Surface{1}; Delete; }{ Surface{20}; };

// BooleanUnion(11) = { Volume{out1[1]}; Delete; }{ Volume{out2}; Delete; };  // Delete the original cylinder and cone after union;
// Difference operation to create the cooling patch

Physical Surface("CoolingPatch") = {20};
Physical Surface("FresheningPatch") = {42};
Physical Surface("Wall") = {out1[2]};
Physical Surface("Bottom") = {out1[0]};
Physical Volume("Domain") = {out1[1]};  This causes an error in gridap.