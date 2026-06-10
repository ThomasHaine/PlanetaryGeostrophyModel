SetFactory("Built-in");
radius = 1.0;
MeshSize = 0.05;

Point(1) = {0, 0, 0, MeshSize};           // Center
Point(2) = {radius, 0, 0, MeshSize};      // x = +radius
Point(3) = {0, radius, 0, MeshSize};      // y = +radius
Point(4) = {-radius, 0, 0, MeshSize};     // x = -radius
Point(5) = {0, -radius, 0, MeshSize};     // y = -radius

Circle(1) = {2, 1, 3}; // +x to +y
Circle(2) = {3, 1, 4}; // +y to -x
Circle(3) = {4, 1, 5}; // -x to -y
Circle(4) = {5, 1, 2}; // -y to +x

Line Loop(10) = {1, 2, 3, 4};
Plane Surface(11) = {10};

Physical Surface("domain") = {11};
Physical Curve("boundary") = {1, 2, 3, 4};
