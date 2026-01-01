function define_H_parameters(xc, r, hp, hm)
	# Set up and solve the linear system to find the coefficients of the quartic polynomial
	# H(x,0) = a4*x^4 + a3*x^3 + a2*x^2 + a1*x + a0
	# such that:
	# H(-r,0) = 0
	# H(0,0) = hp
	# H(xc/2,0) = hm
	# H(xc,0) = hp
	# H(xc+r,0) = 0
	# This gives 5 equations for the 5 unknown coefficients [a4, a3, a2, a1, a0].
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
	# Evaluate H(x,y) = P(x)*(1 - y^2), where P(x) is the quartic polynomial
	# defined by the coefficients in param_vec
    x4, x3, x2, x1, x0 = param_vec
    return (x4*x^4 + x3*x^3 + x2*x^2 + x1*x + x0) * (1 - y^2)
end

function compute_Cassini_oval(b, num_points)
	θs = range(0, 2π, length=num_points)
	points = []
	for θ in θs
		# Solve r^4 - 2*a^2*cos(2θ)*r^2 + (a^4 - b^4) = 0 for r >= 0
		r_poly = Polynomial([1 - b^4, 0, -2*cos(2*θ), 0, 1])
		rts = roots(r_poly) 
		rs = [real(r) for r in rts if isreal(r) && real(r) > 0]
		if length(rs) == 0
			error("No positive real root found for the given parameter: b=$b")
		end
		r = minimum(rs)  # Choose the smallest positive root
		push!(points,[r * cos(θ),r * sin(θ)])
	end
	return reduce(hcat, points)'
end	

# function compute_Cassini_oval_H(x, y, hi_b)
# 	factor = 1.0
# 	θ = atan(y, x)
# 	this_r = sqrt(x^2 + y^2)
# 	this_b = (this_r^4 - 2*factor*cos(2*θ)*this_r^2 + 1)^(1/4)
# 	H = hi_b - this_b
# 	return H
# end

# function H_cassini(x, y)
# 	H_saddle=0.5
# 	β=1.0
#     b = sqrt(sqrt(((x-1)^2 + y^2)*((x+1)^2 + y^2)))  # Cassini oval b(x,y)
#     expa = exp(- (1/β)^2)
#     expb = exp(- (b/(β))^2)
#     scale = 1 - expa
#     return H_saddle + (1 - H_saddle) * (expb - expa) / scale
# end

# function H_cassini(x, y, hi_b)
# # Cassini oval-based bathymetry function that is smooth and goes to zero at b = hi_b and has a saddle point at the origin and has a maximum value of 1.0 at (x,y) = (±1,0)
# 	H_saddle=0.5
# 	β = 1.0
# 	a = 1.0
# #     b = sqrt(sqrt(((x-a)^2 + y^2)*((x+a)^2 + y^2))) # Cassini oval "radius"
# #     # Gaussian "step"
# #     f(xb) = exp( - (xb/(β*a))^2 )
# #     f0, fa, fb = f(0.0), f(a), f(hi_b)
# #     if b >= hi_b
# #         return 0.0
# #     else
# #         term1 = (f(b) - fa) / (f0 - fa)
# #         term2 = (f(b) - fb) / (f0 - fb)
# #         return H_saddle + (1-H_saddle)*term1 * term2
# #     end
# # end

# # function H_cassini_gaussian(x, y; a=1.0, hi_b=1.6, H_saddle=0.5, β=1.0)
# # function H_cassini_gaussian_monotonic(x, y; a=1.0, hi_b=1.6, H_saddle=0.5, β=1.0)
# # function H_cassini_gaussian_monotonic(x, y; a=1.0, hi_b=1.6, H_saddle=0.5, β=1.0)
#     b = sqrt(sqrt(((x-a)^2 + y^2)*((x+a)^2 + y^2)))
#     f(bv) = exp( - (bv/(β*a))^2 )
#     f0, fa, fhi = f(0.0), f(a), f(hi_b)
#     # Lagrange 3-point interpolation
#     t0 = ((f(b) - fa)*(f(b) - fhi))/((f0 - fa)*(f0 - fhi))
#     t1 = ((f(b) - f0)*(f(b) - fhi))/((fa - f0)*(fa - fhi))
#     H = 1.0 * t0 + H_saddle * t1
#     return b >= hi_b ? 0.0 : H
# end


function H_cassini_gaussian_monotonic(x, y, hi_b)
	a=1.0
	H_saddle=0.5
	β=1.5

    b = sqrt(sqrt(((x-a)^2 + y^2)*((x+a)^2 + y^2)))
    f(bv) = exp( - (bv/(β*a))^2 )
    s0, sa, shi = f(0.0), f(a), f(hi_b)
    if b >= hi_b
        return 0.0
    elseif f(b) >= sa
        # foci to saddle region
        return 1 - (1-H_saddle) * ((s0 - f(b)) / (s0 - sa))
    else
        # saddle to boundary region
        return H_saddle * ((shi - f(b)) / (shi - sa))
    end
end

function H_cassini_gaussian_smooth(x, y, hi_b)
	a=1.0
	H_saddle=0.5
	β=1.0
    b = sqrt(sqrt(((x-a)^2 + y^2)*((x+a)^2 + y^2)))
    f(bv) = exp( - (bv/(β*a))^2 )
    fb0, fba, fbhi = f(0.0), f(a), f(hi_b)
    t = (f(b) - fbhi) / (fb0 - fbhi)
    t0 = 1.0           # t at b = 0 (foci)
    t1 = (fba - fbhi) / (fb0 - fbhi) # t at b = a (saddle)
    t2 = 0.0           # t at b = hi_b (boundary)
    h0 = 1.0           # value at foci
    h1 = H_saddle      # value at saddle
    h2 = 0.0           # value at boundary
    # Quadratic interpolation
    H = h0 * ((t - t1)*(t - t2))/((t0 - t1)*(t0 - t2)) +
        h1 * ((t - t0)*(t - t2))/((t1 - t0)*(t1 - t2))
    return H
end

function H_cassini_gaussian_smootherstep(x, y, hi_b)
	a=1.0
	β=4
    b = sqrt(sqrt(((x - a)^2 + y^2) * ((x + a)^2 + y^2)))
    f(bv) = exp( - (bv/(β*a))^2 )
    t = (f(0.0) - f(b)) / (f(0.0) - f(hi_b))
    S = 1 - 10t^3 + 15t^4 - 6t^5
    return S
end

function H_cassini_gaussian_smootherstep_saddle(x, y, hi_b; a=1.0, β=1.0, H_saddle=0.8)
    b = sqrt(sqrt(((x - a)^2 + y^2) * ((x + a)^2 + y^2)))
    f(bv) = exp(- (bv/(β*a))^2)
    t = (f(0.0) - f(b)) / (f(0.0) - f(hi_b))
    t_a = (f(0.0) - f(a)) / (f(0.0) - f(hi_b))
    S = 1 - 10*t^3 + 15*t^4 - 6*t^5
    S_a = 1 - 10*t_a^3 + 15*t_a^4 - 6*t_a^5
    # Monotonic affine blend
    H = (S - S_a)/(1 - S_a) + H_saddle * (1 - S)/(1 - S_a)
    return H
end