using Plots
# Parameters
x1, y1 = -1.0, 0.0
x2, y2 = 1.0, 0.0
xs, ys = 0.0, 0.0
R = 2.0            # domain radius
p = 4              # boundary steepness
σ = 1.0            # basin width
H_saddle = 0.4

# Interior modulation
gauss(x, y, xc, yc) = exp(-((x - xc)^2 + (y - yc)^2)/σ^2)

# Function whose max is exactly 1 at basins and is H_saddle at strait.
function interior(x, y)
    g1 = gauss(x, y, x1, y1)
    g2 = gauss(x, y, x2, y2)
    gs = gauss(x, y, xs, ys)
    # Find weights such that:
    # at (x1,y1): g1=1, g2~0, gs~exp(-((x1-xs)^2 + (y1-ys)^2)/σ^2)
    # at (x2,y2): g2=1, g1~0, gs~exp(-((x2-xs)^2 + (y2-ys)^2)/σ^2)
    # at (xs,ys): gs=1, g1=g2=exp(-((xs-x1)^2 + (ys-y1)^2)/σ^2)
    # Coefficients: a for basin, b for strait
    # We'll use: h = a*(g1+g2) + b*gs
    # So set up a system:
    # At (x1,y1): h = a*1 + b*gs1 = 1
    # At (x2,y2): h = a*1 + b*gs2 = 1
    # At (xs,ys): h = a*(g1s+g2s) + b*1 = H_saddle
    gs1 = gauss(x1, y1, xs, ys)
    gs2 = gauss(x2, y2, xs, ys)
    g1s = gauss(xs, ys, x1, y1)
    g2s = gauss(xs, ys, x2, y2)
    # System:
    # a*1 + b*gs1 = 1
    # a*1 + b*gs2 = 1
    # a*(g1s+g2s) + b*1 = H_saddle
    # Solve for a, b
    A = [1 gs1; 1 gs2; (g1s+g2s) 1]
    bvec = [1, 1, H_saddle]
    coeffs = A \ bvec
    a, b = coeffs
    return a*(g1 + g2) + b*gs
end

function H(x, y)
    r = sqrt(x^2 + y^2)
    if r >= R
        return 0.0
    end
    f_boundary = 1.0 - (r/R)^p
    return f_boundary * interior(x, y)
end

# Show depth at key points
println("Depth at basin 1 center: ", H(x1, y1))     # Should be 1
println("Depth at basin 2 center: ", H(x2, y2))     # Should be 1
println("Depth at strait: ", H(xs, ys))             # Should be H_saddle
println("Depth at boundary: ", H(R, 0.0))           # Should be 0

# Plotting
xgrid = range(-R, R, length=200)
ygrid = range(-R, R, length=200)
Z = [H(xi, yi) for yi in ygrid, xi in xgrid]
contourf(xgrid, ygrid, Z, title="Idealized Ocean Depth Surface", levels=20)
# scatter!([x1,x2,xs], [y1,y2,ys], m=(10, [:blue :blue :red]), label="Basins & Strait")