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
triangles = dt.triangles

# filter out ghost triangles (any index < 0)
filtered_triangles = [tri for tri in triangles if all(ti -> ti >= 0, tri)]

remapped_node_ids = [reduce(vcat, [[ti for ti in tri] for tri in filtered_triangles])]

# All nodes from points_xy (tags 1:N)
node_tags = collect(1:length(points_xy))
node_coords = Float64[]
for p in points_xy
    append!(node_coords, [p[1], p[2], 0.0])
end

element_tags = collect(1:length(filtered_triangles))

tag = model.occ.addRectangle(xmin, ymin, 0.0, xmax-xmin, ymax-ymin)
model.occ.synchronize()
entity_dim = 2
entity_tag = tag

model.mesh.addNodes(entity_dim, entity_tag, node_tags, node_coords)
element_type = model.mesh.getElementType("triangle", 1)

model.mesh.addElements(entity_dim, entity_tag,
    [element_type],
    [element_tags],
    remapped_node_ids
)
model.occ.synchronize()

# gmsh.fltk.run()


gmsh.write("reservoir.msh")

gmsh.finalize()