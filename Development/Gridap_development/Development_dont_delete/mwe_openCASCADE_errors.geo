SetFactory("OpenCASCADE");
// Mesh.SaveAll=1;

Disk(1)  = {0, 0, 0, 1};
Circle(10) = {0,0,0,0.6,0,2*Pi};

out1[] = Extrude {0, 0, -1} { Surface {1}; } ;

v() = BooleanFragments { Surface{1}; Delete; }{ Curve{10}; Delete; };

//**  I don't think this is needed, and it doesn't help.
//** Surface Loop(1) = Surface{:}; // make a single shell from all surfaces, assuming that the mesh is watertight
//** Volume(1) = {1}; // create a volume from the shell

Physical Surface("Patch1") = {v[1]};
Physical Surface("Patch2") = {v[0]};
// Physical Surface("Top") = {1};
Physical Surface("Wall")   = {out1[2]};
Physical Surface("Bottom") = {out1[0]};

Physical Volume("Domain") = {1};

// The failure is with gridapgmsh importing the mesh. Gmsh makes the mesh ok as far as I can tell.