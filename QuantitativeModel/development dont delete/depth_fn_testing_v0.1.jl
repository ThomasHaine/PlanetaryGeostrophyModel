using Symbolics, Plots, ForwardDiff

# Parameters
A1=5.0; σ1=2.0; x1=-3.0; y1=0.0
A2=6.0; σ2=1.5; x2=4.0; y2=-1.0
B=2.5; σx=1.0; σy=3.0; xs=0.5; ys=-0.3
S=7.0; n=4
@variables x y

H_sym = -A1 * exp(-((x - x1)^2 + (y - y1)^2) / σ1^2) \
     -A2 * exp(-((x - x2)^2 + (y - y2)^2) / σ2^2) \
     + B * exp(-((x - xs)^2) / σx^2 - ((y - ys)^2) / σy^2) \
     + S*(x^2 + y^2)^n

H_tmp = Symbolics.build_function(H_sym, [x, y]; expression=Val{false})
H(xx,yy) = H_tmp([xx,yy])

println("Depth at basin 1 center:", H(x1, y1))
println("Depth at basin 2 center:", H(x2, y2))
println("Depth at strait center:", H(xs, ys))
println("Depth at boundary (8,8):", H(8.0, 8.0))
println("Gradient at (0,0): ", ForwardDiff.gradient(z -> H(z...), [0.0, 0.0]))

xgrid = range(-8.0, 8.0, length=200)
ygrid = range(-8.0, 8.0, length=200)
Z = [H(xi, yi) for yi in ygrid, xi in xgrid]

contourf(xgrid, ygrid, Z, 
    title="Analytic Ocean Depth", 
    xlabel="x", ylabel="y", aspect_ratio=:equal, 
    fill=true, fillalpha=0.9, cbar=true)
scatter!([x1,x2,xs], [y1,y2,ys], m=(10, [:blue :blue :red]), label="Basins & Strait")