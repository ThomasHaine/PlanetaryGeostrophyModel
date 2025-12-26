lc = 1.0;

Point(1) = {-10.0, -10.0, 0, lc};
Point(2) = {10.0, -10.0,  0, lc} ;
Point(3) = {10.0, 10.0, 0, lc} ;
Point(4) = {-10.0, 10.0, 0, lc} ;

Line(1) = {1,2} ;
Line(2) = {2,3} ;
Line(3) = {3,4} ;
Line(4) = {4,1} ;

Curve Loop(1) = {1,2,3,4} ;

// Plane Surface(1) = {1} ;

Point(5) = {5.0, 0.0, 0};
Point(6) = {0, 0, 0};
Point(7) = {0.0, 5.0, 0};
Point(8) = {-5.0, 0.0, 0};
Point(9) = {0.0, -5.0, 0};

Circle(5) = {5, 6, 7};
Circle(6) = {7, 6, 8};
Circle(7) = {8, 6, 9};
Circle(8) = {9, 6, 5};

Curve Loop(2) = {5, 6, 7, 8};

Plane Surface(15) = {1};
Plane Surface(16) = {2};

Translate{0, 0, -5} {Surface{15};}
Translate{0, 0, -2.5} {Surface{16};}

outa[] = Extrude{0, 0, 10.0} {Surface{15};};
Delete{ Volume{outa[1]};}

outb[] = Extrude{0, 0, 5.0} {Surface{16};};
Physical Volume(2) = {outb[1]};

Surface Loop(8) = {15, outa[0], outa[2], outa[3], outa[4], outa[5], 16, outb[0], outb[2], outb[3], outb[4], outb[5]};

Volume(8) = {8};
Physical Volume(8) = {8};
