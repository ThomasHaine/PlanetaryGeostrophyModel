// Test geometry for straight continental slope for input to gmsh for meshing.
// twnh Jun '25

DefineConstant[
  N = {10, Name "Input/1Points "}
];
L=10;
H=1;
dH=0.2*H;
W=2;
dW=0.3;
h=L/N; 

// Top surface (sea level)
Point (1)  = {0, 0, 0, h};
Point (2)  = {L, 0, 0, h};
Point (3)  = {L, W, 0, h};
Point (4)  = {0, W, 0, h};

// Bottom surface
Point (5)  = {0, 0,-dH, h};
Point (6)  = {L, 0,-dH, h};
Point (7)  = {0,dW, -H, h};
Point (8)  = {L,dW, -H, h};
Point (9)  = {0, W, -H, h};
Point (10) = {L, W, -H, h};

// Point connections
Line (1)  = {1, 2};
Line (2)  = {2, 3};
Line (3)  = {3, 4};
Line (4)  = {4, 1};
Line (5)  = {5, 6};
Line (6)  = {7, 8};
Line (7)  = {9,10};
Line (8)  = {1, 5};
Line (9)  = {2, 6};
Line (10) = {4, 9};
Line (11) = {3,10};
Line (12) = {7, 9};
Line (13) = {8,10};
Line (14) = {5, 7};
Line (15) = {6, 8};


// Upper surface
Line Loop(21) = {1, 2, 3, 4};
Plane Surface(1) = {21};

// Sea floor; minus sign indicates reverse direction for that line element.
Line Loop(22) = {12, 7, -13, -6};
Plane Surface(2) = {22};

// Inflow wall
Line Loop(23) = {4, 8, 14, 12, -10};
Plane Surface(3) = {23};

// Outflow wall
Line Loop(24) = {9, 15, 13, -11, -2};
Plane Surface(4) = {24};

// Deep wall
Line Loop(25) = {3, 10, 7, -11};
Plane Surface(5) = {25};

// Shallow wall
Line Loop(26) = {1, 9, -5, -8};
Plane Surface(6) = {26};

// Continental slope
Line Loop(27) = {5, 15, -6, -14};
Plane Surface(7) = {27};


Surface Loop(30) = {1, 2, 3, 4, 5, 6, 7};
Volume(1) = {30};

Physical Line(1) = {1};
Physical Line(2) = {2};
Physical Line(3) = {3};
Physical Line(4) = {4};
Physical Line(5) = {5};
Physical Line(6) = {6};
Physical Line(7) = {7};
Physical Line(8) = {8};
Physical Line(9) = {9};
Physical Line(10) = {10};
Physical Line(11) = {11};
Physical Line(12) = {12};
Physical Line(13) = {13};
Physical Line(14) = {14};
Physical Line(15) = {15};


Physical Surface(1) = {1};
Physical Surface(2) = {2};
Physical Surface(3) = {3};
Physical Surface(4) = {4};
Physical Surface(5) = {5};
Physical Surface(6) = {6};
Physical Surface(7) = {7};

Physical Volume(1) = {1};

Physical Point(101) = {1};
Physical Point(102) = {2};
Physical Point(103) = {3};
Physical Point(104) = {4};
Physical Point(201) = {5};
Physical Point(202) = {6};
Physical Point(203) = {7};
Physical Point(204) = {8};
Physical Point(205) = {9};
Physical Point(206) = {10};
