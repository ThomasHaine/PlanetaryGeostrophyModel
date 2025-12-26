SetFactory("OpenCASCADE");
Mesh.CharacteristicLengthMin = 0.1;
Mesh.CharacteristicLengthMax = 0.1;
Rectangle(1) = {-0.5,-0.5, 0, 1, 1};
Disk(2) = {0.75, 0, 0, 0.75, 0.75};
BooleanFragments{ Surface{1,2}; Delete; }{}
Mesh 2; // Force GMSH to mesh
