SetFactory("OpenCASCADE");
Cylinder(1) = {0,0,0,0,0,-1,1,2*Pi};
Cylinder(2) = {0,0,0.25,0,0,-0.5,0.5,2*Pi};
BooleanIntersection(10) = { Volume{1}; }{ Volume{2}; Delete; };
Geometry.OCCUnionUnify = 0;
BooleanUnion { Volume{10}; Delete; }{ Volume{1}; Delete; }
Physical Surface("Wall", 22) = {1};
Physical Surface("Bottom", 20) = {2};
Physical Surface("Patch1", 19) = {3};
Physical Surface("Patch2", 21) = {4};
Physical Volume("Domain", 23) = {1};