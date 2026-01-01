using Gmsh
using GridapGmsh
using Gridap
using DelaunayTriangulation
using LinearAlgebra
using Polynomials

using Infiltrator
using Plots

# Bathymetry function parameters:
x1, y1 = -1.0, 0.0; x2, y2 = 1.0, 0.0	# Basin centers:
xsaddle, ysaddle = 0.0, 0.0  # Saddle center:
R = 2.0            # domain radius
p = 2              # boundary steepness
σ = 1.0            # basin width
H_saddle = 0.9	   # depth at saddle point

function H_Gaussian(x, y)
# Function to compute depth H(x,y) with three Gaussian basins g(x,y) = a*g1(x,y) + b*g2(x,y) + c*gs(x,y)
	gauss(x, y, xc, yc) = exp(-((x - xc)^2 + (y - yc)^2)/σ^2)
	function find_weights()
    	# Find weights such that:
    	# at (x1,y1): 			g = a*g1 + b*g2 + c*gs = 1
		# at (x2,y2): 			g = a*g1 + b*g2 + c*gs = 1
		# at (xsaddle,ysaddle): g = a*g1 + b*g2 + c*gs = H_saddle
		g11 = gauss(x1, y1, x1, y1)
		g12 = gauss(x1, y1, x2, y2)
		g1s = gauss(x1, y1, xsaddle, ysaddle)
    	
		g21 = gauss(x2, y2, x1, y1)
		g22 = gauss(x2, y2, x2, y2)
		g2s = gauss(x2, y2, xsaddle, ysaddle)

		gs1 = gauss(xsaddle, ysaddle, x1, y1)
		gs2 = gauss(xsaddle, ysaddle, x2, y2)
		gss = gauss(xsaddle, ysaddle, xsaddle, ysaddle)

    	A = [g11 g12 g1s; g21 g22 g2s; gs1 gs2 gss]
    	bvec = [1, 1, H_saddle]				
    	coeffs = A \ bvec
    	return coeffs
	end

	weights = find_weights()
    r = sqrt(x^2 + y^2)
    f_boundary = 1.0 - (r/R)^p
    return f_boundary * (weights[1]*gauss(x, y, x1, y1) + weights[2]*gauss(x, y, x2, y2) + weights[3]*gauss(x, y, xsaddle, ysaddle))
end

function compute_boundary_points(R)
	thetas = range(0, 2π, length=128)
	xb = R * cos.(thetas)
	yb = R * sin.(thetas)
	pts = hcat(xb, yb)
	return pts
end

function build_geometry_and_mesh(H, res, GmshMeshFileName)
	gmsh.initialize()
	model = gmsh.model
	occ = model.occ
	gmsh.option.setNumber("General.Terminal", 1)
	gmsh.option.setNumber("Geometry.OCCUnionUnify", 0)     # This is important. 
	model.add("Reservoir")

	# Parameters
	# nx, ny = 256, 128
	nx, ny = 32, 16
	
	# Boundary points:
	boundary_pts = compute_boundary_points(R)
	xmin, xmax = minimum(boundary_pts[:,1]), maximum(boundary_pts[:,1])
	ymin, ymax = minimum(boundary_pts[:,2]), maximum(boundary_pts[:,2])
	@info "Boundary x-range: [$xmin, $xmax], y-range: [$ymin, $ymax]"

	# Generate points inside the domain where H(x,y) > 0
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

	# Add points from boundary to Gmsh model
	boundary_element_tags = []
	for pt in eachrow(boundary_pts)
    	push!(boundary_element_tags, occ.addPoint(pt[1], pt[2], 0.0, res, -1))
	end

	# Add lines between points to form the boundary
	line_tags = []
	num_bdy_points = size(boundary_pts, 1)
	for i in 1:(num_bdy_points-1)
		p1_tag = boundary_element_tags[i]
		p2_tag = boundary_element_tags[mod1(i+1, num_bdy_points)]
		line_tag = occ.addLine(p1_tag, p2_tag, -1)
		push!(line_tags, line_tag)
	end
	occ.synchronize()

	# Add points at the bottom of the reservoir
	bottom_element_tags = []
	for (x, y) in points_xy
		push!(bottom_element_tags, occ.addPoint(x, y, -H(x,y), res, -1))
	end
	occ.synchronize()
	# gmsh.fltk.run()

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


	model.mesh.generate(2)
	gmsh.write(GmshMeshFileName)
	gmsh.finalize()
    @info "Gmsh mesh written to $GmshMeshFileName with resolution $res"
end