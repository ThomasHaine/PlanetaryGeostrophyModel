using Gmsh
using GridapGmsh
using Gridap

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
nx, ny = 126, 64

function H(x, y)
    # 2.0 + 0.8 * sin(pi * x / xmax) * cos(pi * y / ymax)
    H_tmp = max(0.0,(1.0 - ((x-(xc/2))/((xc+2)/2))^2 - y^2))
    return H_tmp
end

Xs = range(xmin, xmax, length=nx)
Ys = range(ymin, ymax, length=ny)

tag = occ.addRectangle(xmin, ymin, 0.0, xmax-xmin, ymax-ymin)
occ.synchronize()
entity_dim = 2 # surface
entity_tag = tag

# Prepare node coordinates and tags
node_tags = []
node_coords = Float64[]
for j in 1:ny
    for i in 1:nx
        x = Xs[i]
        y = Ys[j]
        z = -H(x, y)
        # if(z < 0.0)
            global_index = (j-1)*nx + i
            push!(node_tags, global_index)
            append!(node_coords, [x, y, z])
        # end
    end
end

node_tags = collect(node_tags)
node_coords = collect(node_coords)

# Add nodes to mesh
model.mesh.addNodes(entity_dim, entity_tag, node_tags, node_coords)

# Prepare connectivity (triangles)
element_type = model.mesh.getElementType("triangle", 1)
# Get number of nodes per element for triangle
npe = model.mesh.getElementProperties(element_type)[2]

element_tags = []
node_ids = []

for j in 1:ny-1
    for i in 1:nx-1
        # node indices in the grid (row-wise ordering)
        n1 = (j-1)*nx + i
        n2 = (j-1)*nx + i+1
        n3 = j*nx + i+1
        n4 = j*nx + i

        # Two triangles per grid cell
        # Triangle 1: n1, n2, n3
        push!(element_tags, length(element_tags)+1)
        append!(node_ids, [n1, n2, n3])

        # Triangle 2: n1, n3, n4
        push!(element_tags, length(element_tags)+1)
        append!(node_ids, [n1, n3, n4])
    end
end

element_tags = collect(element_tags)
node_ids = collect(node_ids)

# Add elements to mesh
model.mesh.addElements(entity_dim, entity_tag,
    [element_type],         # element types
    [element_tags],         # element tags (IDs for elements)
    [node_ids],             # node indices for elements
)




# model.mesh.generate(3)
gmsh.write("reservoir.msh")

gmsh.finalize()