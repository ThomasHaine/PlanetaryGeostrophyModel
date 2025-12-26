SetFactory("OpenCASCADE");

// Parameters
R = 1.0;
H = -1.0;

// Make disk and extrude
Disk(1) = {0, 0, 0, R};

out1[] = Extrude {0, 0, H} { Surface {1}; }; 
Printf("Extruded tags '%g', '%g', '%g'", out1[0], out1[1], out1[2]);    // see t3.geo for example

// Assign Physicals
Physical Surface("Top") = {1};        // top disk
Physical Surface("Bottom") = {out1[0]}; // bottom disk
Physical Volume("Domain") = {out1[1]}; // The volume—USE THIS
Physical Surface("Wall") = {out1[2]}; // lateral wall

// --- Done. No need to define Surface Loop or Volume by hand here. ---
