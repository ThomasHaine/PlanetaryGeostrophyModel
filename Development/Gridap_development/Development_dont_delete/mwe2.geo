SetFactory("OpenCASCADE");

// Annulus in z=0
Disk(1)  = {0, 0, 0, 1};
Disk(2)  = {0, 0, 0, 0.6};
BooleanDifference(10) = { Surface{1}; Delete; }{ Surface{2}; };

// Extrude to make the volume
out1[] = Extrude {0, 0, -1} { Surface{10}; };

// Partition with y-z plane x=0
// This will split lateral wall "through the volume"
// out2[] = BooleanFragments{ Volume{out1[1]};}{ Plane{0,0,0, 1,0,0}; };

// Assign correct physical entities (use GUI to find new surface tags)
Physical Surface("InnerWall") = {2}; // inner lateral, check tag
Physical Surface("OuterWall") = {10}; 
Physical Volume("Domain") = {out1[1]};