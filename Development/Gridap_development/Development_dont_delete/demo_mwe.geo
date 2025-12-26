Point(1) = {-1, 0, 0, 1.0};
Point(7) = {-1.4, 0, 0, 1.0};
Point(10) = {-1, 0.4, 0, 1.0};
Point(13) = {-1, -0.4, 0, 1.0};
Point(14) = {0.6, 0, 0, 1.0};
Point(15) = {1.1, 0, 0, 1.0};
Point(16) = {0.9, 0, 0, 1.0};
Point(17) = {0.6, 0.5, 0, 1.0};
Point(18) = {0.6, 0.3, 0, 1.0};
Point(19) = {0.6, -0.3, 0, 1.0};
Point(20) = {0.3, 0, 0, 1.0};
Point(21) = {0.6, -0.5, 0, 1.0};

Line(1) = {10, 17};
Line(2) = {13, 21};

Circle(3) = {10, 1, 7};
Circle(4) = {7, 1, 13};
Circle(5) = {21, 14, 15};
Circle(6) = {15, 14, 17};
Circle(7) = {16, 14, 18};
Circle(8) = {18, 14, 20};
Circle(9) = {20, 14, 19};
Circle(10) = {19, 14, 16};

Curve Loop(1) = {1, -6, -5, -2, -4, -3};
Curve Loop(2) = {8, 9, 10, 7};

Plane Surface(1) = {1, 2};
Plane Surface(10) = {1};
Plane Surface(20) = {2};

Extrude {0, 0, 0.1} {
  Surface{10}; 
}

Physical Surface("Bottom") = {1};
Physical Surface("Patch") = {20};
Physical Volume("volume") = {1};