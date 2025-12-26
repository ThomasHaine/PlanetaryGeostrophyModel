SetFactory("OpenCASCADE");

// From: https://onelab.info/pipermail/gmsh/2019/013275.html

//Volume of cuboid excluding electrodes
CUBOIDELECTRODEVOLUME = 102;
//Surface of cuboid and electrode surface
CUBOIDELECTRODESURFACE = 104;

TORUSSURFACE = 105;
CYLINDERSURFACE = 106;

Mesh.CharacteristicLengthFactor = 0.4;

bwx = 1;
bwy = 1;
bwz = 0.5;
Box(1) = {-0.5*bwx, -0.5*bwy, -0.5*bwz, bwx, bwy, bwz};

//Electrodes
trlo = 0.1;
trhi = 0.25;
tz = 0.1;
Torus(2) = {0, 0, tz, trhi, trlo, 2*Pi};
SL2[] = Boundary{Volume{2};};

For i In {0:#SL2[]-1}
   Printf("SL2: %g",SL2[i]);
EndFor

BooleanDifference(50) = { Volume{1}; Delete; }{ Volume{2}; Delete; };

cdia = 0.9;
cD = 0.05;
cgap = 0.2;
Cylinder(3) = {0, 0, -0.5*cgap-cD, 0, 0, cD, 0.5*cdia, 2*Pi};
SL3[] = Boundary{Volume{3};};

For i In {0:#SL3[]-1}
   Printf("SL3: %g",SL3[i]);
EndFor

BooleanDifference(51) = { Volume{50}; Delete; }{ Volume{3}; Delete; };

SL51[] = Boundary{Volume{51};};

For i In {0:#SL51[]-1}
   Printf("SL51: %g",SL51[i]);
EndFor

Physical Surface(TORUSSURFACE) = {SL2[]};
Physical Surface(CYLINDERSURFACE) = {SL3[]};
Physical Surface(CUBOIDELECTRODESURFACE) = {SL51[]};
Physical Volume(CUBOIDELECTRODEVOLUME) = {51};