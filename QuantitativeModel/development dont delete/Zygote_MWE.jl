using Zygote
using Surrogates

num_samples = 10

# Defining the function
f = x -> log(x) * x^2 + x^3

# Sampling points from the function
lb = 1.0
ub = 10.0
x = sample(num_samples, lb, ub, SobolSample())
y = f.(x)

# Constructing the surrogate
my_radial_basis = RadialBasis(x, y, lb, ub)

# Predicting at x=5.4
approx = my_radial_basis(5.4)
exact = f(5.4)
display("Approximation at x=5.4: $approx")
display("Exact value at x=5.4: $exact")

# Derivatives using Zygote
df_dx = Zygote.gradient(my_radial_basis, 5.4)[1]
exact_derivative = Zygote.gradient(f, 5.4)[1]
display("Approximate derivative at x=5.4: $df_dx")
display("Exact derivative at x=5.4: $exact_derivative")