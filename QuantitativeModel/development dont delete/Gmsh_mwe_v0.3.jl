using Gmsh
using GridapGmsh
using Gridap
using DelaunayTriangulation

gmsh.initialize()
model = gmsh.model
occ = model.occ
gmsh.option.setNumber("General.Terminal", 1)
gmsh.option.setNumber("Geometry.OCCUnionUnify",0)     # This is important. 
model.add("Reservoir")

# Parameters
xc = 2.5
r  = 1.0
res = 0.05
xmin, xmax = -r, xc + r
ymin, ymax = -r, r
nx, ny = 128, 64
# nx, ny = 32, 16

function H(x, y)
    # 2.0 + 0.8 * sin(pi * x / xmax) * cos(pi * y / ymax)
    H_tmp = max(0.0,(1.0 - ((x-(xc/2))/((xc+2)/2))^2 - y^2))
    return H_tmp
end

Xs = collect(range(xmin, xmax, length=nx))
Ys = collect(range(ymin, ymax, length=ny))

points_xy = []
for j in 1:ny, i in 1:nx
    x = Xs[i]
    y = Ys[j]
    if H(x, y) > 0.0
        push!(points_xy, (x, y))
    end
end

# Delaunay triangulation (coords_mat has shape Npoints × 2)
coords_mat = hcat((collect(p) for p in points_xy)...)
dt = triangulate(coords_mat)

# Get convex hull from DelaunayTriangulation
hull = get_convex_hull_vertices(dt)  # Nx2 array; indices into points_xy

# Add points
boundary_element_tags = []
for (x,y) in points_xy[hull]
    push!(boundary_element_tags,model.occ.addPoint(x,y,0.0,res,-1))
end

# Create lines between points in hull
line_tags = []
num_hull_points = size(hull, 1)
for i in 1:num_hull_points-1
    p1_tag = boundary_element_tags[i]
    p2_tag = boundary_element_tags[mod1(i+1, num_hull_points)]
    line_tag = model.occ.addLine(p1_tag, p2_tag, -1)
    push!(line_tags, line_tag)
end
model.occ.synchronize()

# Close the loop
cl_tag = model.occ.addCurveLoop(line_tags)

# Add a plane surface which is bounded by this curve loop
ps_tag = model.occ.addPlaneSurface([cl_tag])
# model.occ.synchronize()

# Get curves that form the boundary of surface ps_tag
boundary_curves = gmsh.model.getBoundary([(2,ps_tag)])
boundary_curve_tags = [c[2] for c in boundary_curves if c[1] == 1]  # keep just lines
boundary_phys_tag = gmsh.model.addPhysicalGroup(1, boundary_curve_tags)
model.occ.synchronize()
gmsh.model.setPhysicalName(1, boundary_phys_tag, "boundary")

# Optionally, do the same for the surface
surface_phys_tag = model.addPhysicalGroup(2, [ps_tag])
model.setPhysicalName(2, surface_phys_tag, "surface")

model.occ.synchronize()
# gmsh.fltk.run()

# model.mesh.generate(1)
model.mesh.generate(2)
gmsh.write("reservoir.msh")
gmsh.finalize()