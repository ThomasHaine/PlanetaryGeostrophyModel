using SymPy
im = SymPy.im  # SymPy's imaginary unit
using Plots
using Statistics

# Geometry symbolic parameters:
z, ξ   = symbols("z ξ",   real=true, negative=true) # Vertical coordinate and source location (both in [-H,0])
x, y   = symbols("x y",   real=true)                # Horizontal coordinates
H      = SymFunction("H", real=true, positive=true) # Domain depth H(x)
geometry_params = (H(x,y), z, ξ)

# Frictional thermal wind equation symbolic parameters:
f, ϵ   = symbols("f ϵ",   real=true, positive=true) # Coriolis parameter and Ekman number
ν₀, ϕ  = symbols("ν₀ ϕ",  real=true, positive=true) # Viscosity parameters
τˣ, τʸ = symbols("τˣ τʸ", real=true)                # Surface wind stress components
τs     = τˣ + im * τʸ                               # Complex surface wind stress

# Define viscosity here:
ν = ν₀                                              # Constant viscosity profile
uv_params = (f, ϵ, ν)

# Define the parameter values
f_val  = 1
ϵ_val  = 1
ν₀_val = 0.0001
display("Non-dimensional Ekman-layer depth:")
display(sqrt(2*ν₀_val/f_val))

# Compute compound parameter:
ϕ_val = sqrt(f_val / ν₀_val) / ϵ_val

# Define dictionaries for substitutions:
param_values = Dict(f=>f_val, ϵ=>ϵ_val, ν₀=>ν₀_val, ϕ=>ϕ_val)

# Define specific case values here:
pₛ = SymFunction("pₛ")                               # Surface pressure function pₛ(x,y)
dpsdx_val = 1      # ∂/∂x pₛ(x,y) = 1
Hfn = 1            # H(x,y) = 1
case_values  = Dict(sympy.Derivative(pₛ(x, y), x)=>dpsdx_val,sympy.Derivative(pₛ(x, y), y)=>0,H(x, y)=>Hfn) 

function compute_Guv(uv_params, geometry_params, param_values)
    # Setup symbols and parameters:
    f, ϵ, ν = uv_params
    H, z, ξ = geometry_params
    uv      = SymFunction("uv")
    A       = symbols("A",real=true)                                            # Unknown coefficient in the Green's function solution

    #0. Define the ODE for d/dz(uv(z)) = uv(z):
    ode = Eq(im * f * uv(z) + ϵ^2 * diff(diff(ν * uv(z),z),z), 0)
    
    # 1. Solve for $G_- (z)$ on $-H \le z \le \xi$:
    Gₘ = dsolve(ode, uv(z), ics = Dict(uv(z).subs(z,-H(x,y))=>0)).rhs
    @assert simplify(ode.lhs.subs(uv(z),Gₘ)) == 0                               # Check solution
    # Replace constant names because otherwise they can interfere with the constants from the next dsolve below.
    const_names = collect([string(s) for s in Gₘ.free_symbols if occursin(r"^C\d+", string(s))])
    Gₘ = Gₘ.subs(const_names[1],A)
    @assert simplify(Gₘ.subs(z,-H(x,y))) == 0                                   # Check bottom BC

    # 2. Solve for $G_+(z)$ on  $\xi \le z \le 0$:
    Gₚ = dsolve(ode, uv(z), ics = Dict(diff(uv(z),z).subs(z,0)=>0)).rhs
    @assert simplify(ode.lhs.subs(uv(z),Gₚ)) == 0                               # Check solution
    @assert simplify(diff(Gₚ,z).subs(z,0)) == 0                                 # Check surface BC

    # 3. Compute Wronskian $W(z)$:
    W = Gₘ * diff(Gₚ, z) - Gₚ * diff(Gₘ, z)

    # 4. Compute Green's function $G(z; \xi)$:
    Gm = Gₘ * Gₚ.subs(z,ξ) / (ν.subs(z,ξ) * W.subs(z,ξ))
    Gp = Gₘ.subs(z,ξ) * Gₚ / (ν.subs(z,ξ) * W.subs(z,ξ))

    # Check continuity and jump condition:
    @assert Gm.subs(z,ξ) - Gp.subs(z,ξ) == 0
    @assert simplify(diff(Gm, z).subs(z,ξ) - diff(Gp, z).subs(z,ξ)) + 1/ν.subs(z,ξ) == 0

    # #5. Define piecewise Green's function:
    G = sympy.Piecewise((Gm, Le(z,ξ)), (Gp, Ge(z,ξ)))
    
    # Check boundary conditions:
    @assert simplify(diff(G,z).subs(z,0).subs(ξ,-H//2)) == 0
    @assert simplify(G.subs(z,-H(x,y)).subs(ξ,-H//2)) == 0

    # Final simplify (to cancel constants). Avoid simplify in general because it's not always reproducible.
    G = simplify(G)
    return G
end

Guv_sym = compute_Guv(uv_params,geometry_params,param_values) 
display("Full Guv(x,ξ):")
display(Guv_sym)

Guv = Guv_sym.subs(f,ϕ^2 * ϵ^2 * ν₀)
display("Simplified Guv(z,ξ)")
display(Guv)

Guv0 = Guv.subs(ξ,0)
display("Simplified Guv(z,0)")
display(Guv0)

tmp  = diff(Guv, z)
tmp2 = tmp.subs(z, -H(x,y))
dGuv_dz_at_bottom = tmp2.args[1].args[1]
display("Simplified d/dz Guv(z,ξ) @ z = -H(x,y)")
display(dGuv_dz_at_bottom)

tmp = integrate(expand(Guv), (z, -H(x,y), 0)).args[1].args[1]
max_obj = sympy.Max(ξ, -H(x, y))
Guv_int_wrt_z = tmp.subs(max_obj, ξ)
display("Simplified integral Guv(z,ξ) wrt z = -H(x,y) to 0")
display(factor(Guv_int_wrt_z))

Guv_int_wrt_z0 = Guv_int_wrt_z.subs(ξ,0)
display("Simplified integral Guv(z,ξ) wrt z = -H(x,y) to 0 @ ξ = 0")
display(Guv_int_wrt_z0)
tmp = integrate(expand(Guv), (ξ, -H(x,y), 0)).args[1].args[1]
max_obj = sympy.Max(z, -H(x, y))
Guv_int_wrt_ξ = tmp.subs(max_obj, z)
display("Simplified integral Guv(z,ξ) wrt ξ = -H(x,y) to 0")
display(simplify(factor(Guv_int_wrt_ξ)))

𝔲1 = Guv_int_wrt_ξ * (diff(pₛ(x,y),x) + im * diff(pₛ(x,y),y))
display("Pressure-driven flow field 𝔲₁(x,y,z):")
display(𝔲1)

𝔲2 = Guv0 * τs / (ν*ϵ^2)
display("Stress-driven   flow field 𝔲₂(x,y,z):")
display(simplify(𝔲2))
𝔲 = 𝔲1 + 𝔲2

tmp = integrate(expand(Guv_int_wrt_ξ),(z,-H(x,y),0))
𝔘1 = (tmp.args[1] + tmp.args[2].args[1].args[1])*(diff(pₛ(x,y),x) + im * diff(pₛ(x,y),y))
display("Pressure-driven flow field 𝔘₁(x,y):")
display(simplify(𝔘1))

𝔘2 = Guv_int_wrt_z0 * τs / (ν*ϵ^2)
display("Stress-driven   flow field 𝔘₂(x,y):")
display(simplify(𝔘2))
𝔘 = 𝔘1 + 𝔘2
tmp    = integrate(𝔲,(z,-H(x, y),0))
int_𝔲  = tmp.args[1] + tmp.args[2].args[1].args[1]
res    = int_𝔲 - 𝔘
@assert res == 0

τb1 = ν * (integrate(expand(dGuv_dz_at_bottom),(ξ,-H(x,y),0)).args[1].args[1]) * (diff(pₛ(x,y),x) + im * diff(pₛ(x,y),y))
display("Pressure-driven bottom stress ν d/dz u(x,y,z) @ z = -H:")
display(simplify(τb1))

dGuv_dz_at_bottom_and_top = dGuv_dz_at_bottom.subs(ξ,0)
τb2 =  ν * dGuv_dz_at_bottom_and_top * τs / (ϵ^2)
display("Stress-driven   bottom stress ν d/dz u(x,y,z) @ z = -H")
display(simplify(τb2))
τb = τb1 + τb2

lhs = im * f * 𝔘
rhs = H(x,y)*(diff(pₛ(x,y),x) + im * diff(pₛ(x,y),y))- ϵ^2 * τb + τs
final_eqn = Eq(lhs, rhs)
println()
display("Final equation linking surface pressure pₛ(x,y) to windstress:")
display(final_eqn)

eqn = expand(final_eqn.lhs - final_eqn.rhs)
deriv_obj = sympy.Derivative(pₛ(x,y),x)
xxx = symbols("xxx", real=true)
eqn = eqn.subs(deriv_obj, xxx)
eqn = eqn.subs(case_values)
sol = solve(Eq(eqn,0), xxx)[1]
sol_num = complex(numerator(  sol).subs(param_values).n())
sol_den = complex(denominator(sol).subs(param_values).n())
sol = complex(sol_num / sol_den)
println()
display("Solution for ∂/∂x pₛ(x):")
display(sol)

function solve_taux_tauy(rhs, eqn, var1, var2)
    u, v = real(rhs), imag(rhs)
    a = real(eqn.coeff(var1))
    b = imag(eqn.coeff(var1))
    c = real(eqn.coeff(var2))
    d = imag(eqn.coeff(var2))
    eq1 = a*var1 + c*var2 ~ u
    eq2 = b*var1 + d*var2 ~ v
    this_sol = solve((eq1, eq2), (var1, var2))
    @assert abs(eqn.subs(Dict(var1=>this_sol[var1],var2=>this_sol[var2])).n()) - rhs < 1e-10            # Check the solution works
    return this_sol[var1], this_sol[var2]
end
τˣ_sol, τʸ_sol = solve_taux_tauy(dpsdx_val, expand(sol), τˣ,τʸ)
display("Windstress components (τˣ, τʸ):")
display("τˣ = $τˣ_sol, τʸ = $τʸ_sol")
    
𝔘_val = 𝔘.subs(case_values)
𝔘_val = 𝔘_val.subs(param_values)
𝔘_val = 𝔘_val.subs(Dict(τˣ=>τˣ_sol,τʸ=>τʸ_sol))
Uval  = float(real(𝔘_val))
Vval  = float(imag(𝔘_val))
display("Resulting flow field 𝔘(x,y) when ∂/∂x pₛ = 1, ∂/∂y pₛ = 0, H(x,y) = 1:")
display("U = $Uval, V = $Vval")

𝔲_val = 𝔲.subs(case_values)
𝔲_val = 𝔲_val.subs(param_values)
𝔲_val = 𝔲_val.subs(Dict(τˣ=>τˣ_sol,τʸ=>τʸ_sol))
𝔲_fld(zz) = 𝔲_val.subs(z,zz).n()
zvals = range(-Hfn, 0, length=512)
uvals = [𝔲_fld(z) for z in zvals]
sum_uvals = sum(uvals) * (Hfn / length(zvals))
display("Vertical integral of 𝔲(z) from z = -H to 0:")
display(sum_uvals)

bottom_stress = τb.subs(case_values)
bottom_stress = bottom_stress.subs(param_values)
bottom_stress = bottom_stress.subs(Dict(τˣ=>τˣ_sol,τʸ=>τʸ_sol)).n()
display("Bottom stress ν d/dz u(x,y,z) @ z = -H:")
display(bottom_stress)

# Check force balance:
@assert abs(im * f_val *float(𝔘_val) - Hfn * dpsdx_val + ϵ_val^2 * bottom_stress - (τˣ_sol + im * τʸ_sol)) < 1e-14
plt1 = plot()   # Start with empty plot
plot( real.(uvals), zvals, label="u", lw=2, color=:blue, linestyle=:solid)
plot!(imag.(uvals), zvals, label="v", lw=2, color=:red, linestyle=:solid)
plot!( [Uval, Uval], [-Hfn, 0], label="U", lw = 2, color=:blue, linestyle=:dash)
plot!( [Vval, Vval], [-Hfn, 0], label="V", lw = 2, color=:red, linestyle=:dash)
ylabel!("z")
xlabel!("flow field value")
title!("Flow field (u(z), v(z)) and depth-integrated values (U, V)")
plt1
savefig("VerticalProfiles.pdf")

# Plot balance of terms in the final equation:
term_names = ["Coriolis force", "Pressure gradient force", "Minus Bottom Stress", "Wind Stress"]
terms = [im * f_val * float(𝔘_val), Hfn * dpsdx_val, -ϵ_val^2 * bottom_stress, (τˣ_sol + im * τʸ_sol)]
start = [0, 0, terms[2] , terms[2] + terms[3]]
colors = [:red, :blue, :green, :orange]   # Assign each a color
plt2 = plot()   # Start with empty plot
axis_lims = (-0.25,1.25)
for i in eachindex(terms)
    quiver!(
        [real(start[i])], [imag(start[i])],
        quiver=([real(terms[i])], [imag(terms[i])]),
        arrow=true, aspect_ratio=:equal, color=colors[i], label=term_names[i], xlims=axis_lims, ylims=axis_lims
    )
    scatter!([real(start[i] + terms[i])], [imag(start[i] + terms[i])], color=colors[i], label=term_names[i], markerstrokewidth=0)
end

plot!(legend=:topleft, xlabel="x-component", ylabel="y-component", aspect_ratio=:equal, title="Term Balance in Final Equation")
plt2    # Show the plot
savefig("TermBalance.pdf")