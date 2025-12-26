SetFactory("Built-in");

// Parameters
resolution = 0.1; // Mesh resolution
r = 1.0;         // Circle radius
xc = 2.5;        // Center of 2nd circle (x)
corridorWidth = 0.25;  // Width of the corridor
corridorLength = xc - r; // x-distance from 1st circle edge to 2nd circle center
corr_h = corridorWidth/2;
int_pt = Sqrt(r^2 - corr_h^2);

// --- First Circle Points
Point(1) = {0, 0, 0, resolution};                 // Center 1
Point(20) = {int_pt, corr_h, 0, resolution};
Point(21) = {int_pt,-corr_h, 0, resolution};
Point(3) = {0, r, 0, resolution};                 // +y
Point(4) = {-r, 0, 0, resolution};                // -x
Point(5) = {0, -r, 0, resolution};                // -y

// --- Second Circle Points
Point(6) = {xc, 0, 0, resolution};                // Center 2
Point(7) = {xc + r, 0, 0, resolution};            // +x
Point(8) = {xc, r, 0, resolution};                // +y
Point(10) = {xc, -r, 0, resolution};              // -y
Point(90) = {xc - int_pt, corr_h, 0, resolution};
Point(91) = {xc - int_pt,-corr_h, 0, resolution};

// ---- First Circle Arcs
Circle(1) = {20, 1, 3};
Circle(2) = {3, 1, 4};
Circle(3) = {4, 1, 5};
Circle(4) = {5, 1, 21};

// ---- Second Circle Arcs
Circle(5) = {7, 6, 8};
Circle(6) = {8, 6, 90};
Circle(7) = {91, 6, 10};
Circle(8) = {10, 6, 7};

// --- Lines (corridor and connectors)
Line(9) = {90, 20};   // upper corridor edge
Line(10) = {91, 21};  // lower corridor edge

// ---- Outer Line Loops (full boundary)
Line Loop(20) = {1, 2, 3, 4, -10, 7, 8, 5, 6, 9};
Plane Surface(21) = {20};
Physical Surface("domain") = {21};
Physical Curve("boundary") = {1,2,3,4,5,6,7,8,9,10};