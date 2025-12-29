using Gmsh
using GridapGmsh
using Gridap
using DelaunayTriangulation
using LinearAlgebra

function define_H_parameters(xc, r, hp, hm)
    coeff_matrix = [  (  -r)^4   (  -r)^3   (  -r)^2 (  -r) 1;
                        0          0          0        0    1;
                      (xc/2)^4   (xc/2)^3   (xc/2)^2 (xc/2) 1;
                      (xc  )^4   (xc  )^3   (xc  )^2 (xc  ) 1;
                      (xc+r)^4   (xc+r)^3   (xc+r)^2 (xc+r) 1;
                    ]
    @info "Rank of coeff_matrix = $(rank(coeff_matrix)) (should be 5)"
    rhs_vector = [0.0; hp; hm; hp; 0.0]
    param_vec = coeff_matrix\rhs_vector
    return param_vec
end

function compute_H(x, y, param_vec)
    x4, x3, x2, x1, x0 = param_vec
    return (x4*x^4 + x3*x^3 + x2*x^2 + x1*x + x0) * (1 - y^2)
end

function build_geometry_and_mesh(H, xc, r, res, GmshMeshFileName)
	gmsh.initialize()
	model = gmsh.model
	occ = model.occ
	gmsh.option.setNumber("General.Terminal", 1)
	gmsh.option.setNumber("Geometry.OCCUnionUnify", 0)     # This is important. 
	model.add("Reservoir")

	# Parameters
	xmin, xmax = -r, xc + r
	ymin, ymax = -r, r
	nx, ny = 256, 128

    Xs = collect(range(xmin, xmax, length = nx))
	Ys = collect(range(ymin, ymax, length = ny))
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

	# Add points from convex hull to Gmsh model
	boundary_element_tags = []
	for (x, y) in points_xy[hull]
		push!(boundary_element_tags, occ.addPoint(x, y, 0.0, res, -1))
	end

	# Add lines between points to form the boundary
	line_tags = []
	num_hull_points = size(hull, 1)
	for i in 1:(num_hull_points-1)
		p1_tag = boundary_element_tags[i]
		p2_tag = boundary_element_tags[mod1(i+1, num_hull_points)]
		line_tag = occ.addLine(p1_tag, p2_tag, -1)
		push!(line_tags, line_tag)
	end
	occ.synchronize()

	# Close the loop
	cl_tag = occ.addCurveLoop(line_tags)

	# Add a plane surface which is bounded by this curve loop
	ps_tag = occ.addPlaneSurface([cl_tag])
	occ.synchronize()

	# Get curves that form the boundary of surface ps_tag
	boundary_curves = gmsh.model.getBoundary([(2, ps_tag)])
	boundary_curve_tags = [c[2] for c in boundary_curves if c[1] == 1]  # keep just lines
	boundary_phys_tag = gmsh.model.addPhysicalGroup(1, boundary_curve_tags)
	occ.synchronize()
	gmsh.model.setPhysicalName(1, boundary_phys_tag, "boundary")

	# Optionally, do the same for the surface
	surface_phys_tag = model.addPhysicalGroup(2, [ps_tag])
	model.setPhysicalName(2, surface_phys_tag, "surface")

	occ.synchronize()
	# gmsh.fltk.run()

	model.mesh.generate(2)
	gmsh.write(GmshMeshFileName)
	gmsh.finalize()
    @info "Gmsh mesh written to $GmshMeshFileName with resolution $res"
end