lc = 1e-1;

Point(1) = {0, -1.0000, 0, lc};
Point(2) = {0, 1.0000,  0, lc};
Point(3) = {1.9015, 1.6190, 0, lc};
Point(4) = {1.9015, -1.6190, 0, lc};
Point(101) = {1,0,0,lc};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};
Line(101) = {1, 101};
Line(102) = {101, 2};

Curve Loop(101) = {101, 102, 2, 3, 4};
Curve Loop(102) = {101, 102, -1};
Curve Loop(1) = {1:4};
Plane Surface(101) = {101};
Plane Surface(102) = {102};
Physical Surface("Patch1") = {101};
Physical Surface("Patch2") = {102};

Extrude {0, 0, -1.0} { Curve{1:5}; }
Physical Surface("Walls1") = {110,114,118};
Physical Surface("Wall2") = {106};

Curve Loop(202) = {107,111,115,103};
Plane Surface(302) = {202};
Physical Surface("Bottom") = {302};

Surface Loop(1) = {101, 102, 106, 110, 114, 118};
Volume(1) = {1};
Physical Volume("Domain") = {1};//+
Recombine Surface {102, 101, 302, 110, 114, 118, 106};
