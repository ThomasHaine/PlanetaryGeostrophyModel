using Zygote
using Surrogates

num_samples = 1024

# Defining the function
f = x -> log(x[1]) * x[1]^2 + x[1]^3 + x[2]^3*sin(x[2])

# Sampling points from the function
lb = [1.0, 1.0]
ub = [10.0, 10.0]
x = sample(num_samples, lb, ub, SobolSample())
y = f.(x)

# Constructing the surrogate
my_radial_basis = RadialBasis(x, y, lb, ub)

# Compute gradients at a given point
function compute_gradients(my_pt)
	df_dx = Zygote.gradient(my_radial_basis, my_pt)[1]
	exact_derivative = Zygote.gradient(f, my_pt)[1]
	display("Approximate derivative at (x,y)=$(my_pt): $df_dx")
	display("Exact derivative at       (x,y)=$(my_pt): $exact_derivative")
end

# Derivatives using random point: works
my_pt = Tuple(((ub .- lb) .* rand(2)) .+ lb)
compute_gradients(my_pt)

# Derivatives using point from sample: gives (NaN, NaN)
my_pt = x[1]
compute_gradients(my_pt)