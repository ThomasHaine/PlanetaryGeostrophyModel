// Define parameters for the cylinder
r = 1.0;      // Radius of the cylinder
h = 5.0;      // Height of the cylinder

// Define points for the top and bottom circles
Point(1) = {0, 0, 0, 1.0};  // Bottom center point
Point(2) = {r, 0, 0, 1.0};   // Point on the bottom circle
Point(3) = {0, r, 0, 1.0};   // Point on the bottom circle
Point(4) = {-r, 0, 0, 1.0};  // Point on the bottom circle
Point(5) = {0, -r, 0, 1.0};  // Point on the bottom circle
Point(6) = {0, 0, h, 1.0};   // Top center point
Point(7) = {r, 0, h, 1.0};   // Point on the top circle
Point(8) = {0, r, h, 1.0};   // Point on the top circle
Point(9) = {-r, 0, h, 1.0};  // Point on the top circle
Point(10) = {0, -r, h, 1.0}; // Point on the top circle

// Define circles for the bases
Line(1) = {2, 3};  // Bottom circle
Line(2) = {3, 4};
Line(3) = {4, 5};
Line(4) = {5, 2};

Line(5) = {7, 8};  // Top circle
Line(6) = {8, 9};
Line(7) = {9, 10};
Line(8) = {10, 7};

// Create line loops for the bottom and top circles
Line Loop(1) = {1, 2, 3, 4};  // Bottom loop
Line Loop(2) = {5, 6, 7, 8};  // Top loop

// Define surfaces for the top and bottom faces
Plane Surface(1) = {1}; // Bottom surface
Plane Surface(2) = {2}; // Top surface

// Create lateral surface using surfaces created by the triangles
Surface Loop(3) = {1, 2};  // Combine the two surfaces
Extrude {0, 0, h} { Surface{3}; }; // Extrude the surface loop to create the cylinder

// Assign physical groups (optional)
Physical Surface("BottomSurface") = {1}; // Bottom surface group
Physical Surface("TopSurface") = {2};    // Top surface group
Physical Volume("CylinderVolume") = {3}; // Volume of the cylinder