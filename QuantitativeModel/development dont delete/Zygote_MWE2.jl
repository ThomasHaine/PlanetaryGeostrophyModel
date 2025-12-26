using Zygote
using Surrogates

num_samples = 256

# Defining the function
f = x -> log(x[1]) * x[1]^2 + x[1]^3 + x[2]^3*sin(x[2])

# Sampling points from the function
lb = [1.0, 1.0]
ub = [10.0, 10.0]
x = sample(num_samples, lb, ub, SobolSample())
y = f.(x)

# Constructing the surrogate
my_radial_basis = RadialBasis(x, y, lb, ub)

# Predicting at x=5.4
my_pt = (5.4,1.8)
approx = my_radial_basis(my_pt)
exact = f(my_pt)
display("Approximation at (x,y)=$(my_pt): $approx")
display("Exact value at   (x,y)=$(my_pt): $exact")

# Derivatives using Zygote
df_dx = Zygote.gradient(my_radial_basis, my_pt)[1]
exact_derivative = Zygote.gradient(f, my_pt)[1]

display("Approximate derivative at (x,y)=$(my_pt): $df_dx")
display("Exact derivative at       (x,y)=$(my_pt): $exact_derivative")