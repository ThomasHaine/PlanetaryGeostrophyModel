SetFactory("OpenCASCADE");

length = 10;
height = 6;

// Step 1: Create the rectangle
Rectangle(1) = {0, 0, 0, length, height, 0};

// Step 2: Draw the splitting line
Line(2) = {length/2, 0, 0, length/2, height, 0};

// Step 3: Split the surface
Split Surface {1} With Line {2};

// Step 4: Two new surfaces created: typically 2 and 3
Physical Surface("Left") = {2};
Physical Surface("Right") = {3};