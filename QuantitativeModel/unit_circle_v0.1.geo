SetFactory("Built-in");

Point(1) = {0, 0, 0, 0.04};        // Center
Point(2) = {1.0, 0, 0, 0.04};      // x = +1
Point(3) = {0, 1.0, 0, 0.04};      // y = +1
Point(4) = {-1.0, 0, 0, 0.04};     // x = -1
Point(5) = {0, -1.0, 0, 0.04};     // y = -1

Circle(1) = {2, 1, 3}; // +x to +y
Circle(2) = {3, 1, 4}; // +y to -x
Circle(3) = {4, 1, 5}; // -x to -y
Circle(4) = {5, 1, 2}; // -y to +x

Line Loop(10) = {1, 2, 3, 4};
Plane Surface(11) = {10};

Physical Surface("domain") = {11};
Physical Curve("boundary") = {1, 2, 3, 4};
