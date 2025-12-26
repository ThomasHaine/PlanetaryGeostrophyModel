using Plots

z = -1:0.01:0             # range of z, with step 0.01
y = 0.5 .* (exp.(4.0 .* z) .- 1.0)               # element-wise exp(-z)

plot(y, z, ylabel="z", xlabel="exp(-z)", title="Plot of exp(-z) from z = -1 to 0")