// Test Arctic Basin Geometry
// This file is used to create a geometry for the Arctic Basin
// It defines a cylindrical structure with specific parameters and points
// The geometry is defined using GMSH syntax and includes circles, lines, and surfaces
// The final volume is created by combining surfaces and defining physical groups
// The geometry is suitable for simulations or visualizations in GMSH
// ArcticBasin.geo
// twnh Jul 2025

SetFactory("OpenCASCADE");

// Parameters
R  = 1.0;    // Top circle radius
H  = -1.0;   // Cylinder height (negative = 'down')
dH = 0.2*H;  // Rim height (negative)
r  = R*0.6;  // Bottom circle radius
WP_theta = Pi/10; // Warming patch angle (rad)

// ===== Top Rim Patch (sector of big circle) =====
Point(1) = {R, 0, 0}; // Just for referencing start/end of sector
outTopRim[] = Extrude {0, 0, dH} { 
  Curve{
    Circle(1) = {0, 0, 0, R, 0, WP_theta}; 
  }; 
};
// outTopRim[1]: surface of vertical wall

Physical Surface("WarmingPatch") = {outTopRim[1]};

// ===== Wall (complementary sector) =====
outWall[] = Extrude {0, 0, dH} {
  Curve{
    Circle(2) = {0, 0, 0, R, WP_theta, 0};
  };
};

Physical Surface("Wall") = {outWall[1]};

// ===== Top Inner Circle Patch (small circle on z=0) =====
outTopInner[] = Extrude {0, 0, dH} {
  Curve{
    Circle(3) = {0, 0, 0, r, 0, WP_theta};
  };
};
// outTopInner[1]: inner wall vertical patch

Physical Surface("TopInner") = {outTopInner[1]};

// ===== Slope Patch (patch between outTopRim[0] and outTopInner[0]) =====
// Connect the rim's top edge to the inner circle's top edge with ruled surface (loft)
Ruled Surface(100) = {outTopRim[0], outTopInner[0]};
Physical Surface("Slope") = {100};

// ===== Bottom Patch (at z=H) : sector of small circle =====
Circle(11) = {0, 0, H, r, 0, WP_theta};
Circle(12) = {0, 0, H, r, WP_theta, 0};
Curve Loop(13) = {11,12};
Surface(14) = {13};
Physical Surface("Bottom") = {14};

// =============== CREATING THE VOLUME ==================
// All faces up to here form a closed boundary.

Surface Loop(500) = {outTopRim[1], outWall[1], outTopInner[1], 100, 14}; // wall, warming patch, inner top, slope, bottom
Volume(501) = {500};
Physical Volume("Domain") = {501};

// Optionally:
// Mesh.CharacteristicLengthMin = 0.05;
// Mesh.CharacteristicLengthMax = 0.2;