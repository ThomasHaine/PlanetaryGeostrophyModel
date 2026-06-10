using SymPy
im = SymPy.im  # SymPy's imaginary unit
using Plots
using Statistics
using Infiltrator

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

# Define viscosity profile here:
ν = ν₀                                              # Constant viscosity profile

uv_params = (f, ϵ, ν)

# Define the $B(z)$ source term here:
f_val  = 1
ϵ_val  = 1
ν₀_val = 1

# Compute compound parameter:
ϕ_val = sqrt(f_val / ν₀_val) / ϵ_val

# Define dictionaries for substitutions:
param_values = Dict(f=>f_val, ϵ=>ϵ_val, ν₀=>ν₀_val, ϕ=>ϕ_val)
sqrt_values  = Dict("(-I)^(13/2)"=>"exp(-I*13*pi//4)","(-I)^(9/2)"=>"exp(-I*9*pi//4)","(-I)^(5/2)"=>"exp(-I*5*pi//4)","sqrt(-I)"=>"exp(-I*pi//4)")                    # sqrt(-I) = exp(-I*pi/4) etc. (principal value)

# Define specific case values here:
dpsdx_val = 1      # ∂/∂x pₛ(x,y) = 1
Hfn = 1            # H(x,y) = 1
case_values  = Dict("Derivative(pₛ(x, y), x)"=>dpsdx_val,"Derivative(pₛ(x, y), y)"=>0,"H(x, y)"=>Hfn) 
nothing


function compute_Guv(uv_params, geometry_params, param_values)
    # Setup symbols and parameters:
    f, ϵ, ν = uv_params
    H, z, ξ = geometry_params
    uv      = SymFunction("uv")
    A       = symbols("A",     real=true)                      # Unknown coefficient in the Green's function solution

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
    Gₚ = dsolve(ode, uv(z), ics = Dict(diff(uv(z),z).subs(z,0)=>0)).rhs         # This is where surface forcing would go.
    @assert simplify(ode.lhs.subs(uv(z),Gₚ)) == 0                               # Check solution
    @assert simplify(diff(Gₚ,z).subs(z,0)) == 0                                 # Check surface BC

    # 3. Compute Wronskian $W(z)$:
    W = simplify(Gₘ * diff(Gₚ, z) - Gₚ * diff(Gₘ, z))

    # 4. Compute Green's function $G(z; \xi)$:
    Gm = simplify(Gₘ * Gₚ.subs(z,ξ) / (ν.subs(z,ξ) * W.subs(z,ξ)))
    Gp = simplify(Gₘ.subs(z,ξ) * Gₚ / (ν.subs(z,ξ) * W.subs(z,ξ)))

    # Check continuity and jump condition:
    @assert Gm.subs(z,ξ) - Gp.subs(z,ξ) == 0
    @assert simplify(diff(Gm, z).subs(z,ξ) - diff(Gp, z).subs(z,ξ)) + 1/ν.subs(z,ξ) == 0

    # #5. Define piecewise Green's function:
    G = simplify(sympy.Piecewise((Gm, Le(z,ξ)), (Gp, Ge(z,ξ))))
    
    # Check boundary conditions:
    @assert simplify(diff(G,z).subs(z,0).subs(ξ,-H//2)) == 0
    @assert simplify(G.subs(z,-H(x,y)).subs(ξ,-H//2)) == 0

    return G
end

# Be careful with this function!!!
# It's more powerful than the .subs() method, but is more risky.
function tom_subs(expr,param_values)
    new_expr_str = string(expr)
    for (k, v) in param_values
        new_expr_str = replace(new_expr_str, string(k) => string(v))
    end
    return sympify(new_expr_str)
end

function get_var_in_expr(var,expr)
    filter(s -> string(s) == var, collect(expr.free_symbols))[1]
end

Guv_sym = compute_Guv(uv_params,geometry_params,param_values) 
display("Full Guv(x,ξ):")
display(Guv_sym)

pₛ = SymFunction("pₛ")                               # Surface pressure function 

tmp = tom_subs(Guv_sym,Dict("f"=>"ϕ^2 * ϵ^2 * ν₀"))               # THIS IS FRAGILE!!!  The order of these substitutions matters!
tmp = tom_subs(tmp,Dict("sqrt(ν₀*ϕ^2*ϵ^2)/(sqrt(ν₀)*ϵ)"=>"ϕ"))
Guv = tom_subs(tmp,Dict("sqrt(ν₀*ϕ^2*ϵ^2)"=>"ϕ*sqrt(ν₀)*ϵ"))
display("Simplified Guv(z,ξ)")
display(Guv)

z_var = get_var_in_expr("z" ,Guv)
Guv0  = tom_subs(Guv,Dict("ξ"=>0))
Guv0  = simplify(Guv0.args[1].args[1])
display("Simplified Guv(z,0)")
display(Guv0)

tmp5  = diff(Guv, z_var)
tmp6 = tom_subs(tmp5,Dict(z_var=>"-H(x,y)"))
dGuv_dz_at_bottom = simplify(tmp6.args[1].args[1])
display("Simplified d/dz Guv(z,ξ) @ z = -H(x,y)")
display(dGuv_dz_at_bottom)

x_var  = get_var_in_expr("x" ,Guv)
y_var  = get_var_in_expr("y" ,Guv)
z_var  = get_var_in_expr("z" ,Guv)
xi_var = get_var_in_expr("ξ" ,Guv)
tmp7 = integrate(expand(Guv), (z_var, -H(x_var,y_var), 0))
expr = tmp7.args[1].args[1]
expr = tom_subs(expr,Dict("Max(ξ, -H(x, y))"=>xi_var))
expr = tom_subs(expr,Dict("Min(0, ξ)"=>xi_var))
# Guv_int_wrt_z = simplify(factor(expr))
Guv_int_wrt_z = factor(expr)
display("Simplified integral Guv(z,ξ) wrt z = -H(x,y) to 0")
display(Guv_int_wrt_z)

xi_var = get_var_in_expr("ξ" ,Guv_int_wrt_z)
Guv_int_wrt_z0 = tom_subs(Guv_int_wrt_z,Dict(xi_var=>0))
Guv_int_wrt_z0 = simplify(factor(Guv_int_wrt_z0))
display("Simplified integral Guv(z,ξ) wrt z = -H(x,y) to 0 @ ξ = 0")
display(Guv_int_wrt_z0)
@infiltrate()


xi_var = get_var_in_expr("ξ" ,Guv)
tmp7 = integrate(expand(Guv), (xi_var, -H(x_var,y_var), 0))
expr = tmp7.args[1].args[1]
expr = tom_subs(expr,Dict("Max(z, -H(x, y))"=>"z"))
expr = tom_subs(expr,Dict("Min(0, z)"=>"z"))
Guv_int_wrt_ξ = simplify(factor(expr))
display("Simplified integral Guv(z,ξ) wrt ξ = -H(x,y) to 0")
display(Guv_int_wrt_ξ)

x_var  = get_var_in_expr("x" ,Guv_int_wrt_ξ)
y_var  = get_var_in_expr("y" ,Guv_int_wrt_ξ)
𝔲1 = Guv_int_wrt_ξ * (diff(pₛ(x_var,y_var),x_var) + im * diff(pₛ(x_var,y_var),y_var))
display("Pressure-driven flow field 𝔲₁(x,y,z):")
display(𝔲1)

nu_var = get_var_in_expr("ν₀" ,Guv)
𝔲2 = simplify(Guv0 * τs / (nu_var*ϵ^2))
display("Stress-driven   flow field 𝔲₂(x,y,z):")
display(𝔲2)
𝔲 = simplify(𝔲1 + 𝔲2) ;

x_var = get_var_in_expr("x" ,Guv_int_wrt_ξ)
y_var = get_var_in_expr("y" ,Guv_int_wrt_ξ)
z_var = get_var_in_expr("z" ,Guv_int_wrt_ξ)
tmp = integrate(expand(Guv_int_wrt_ξ),(z_var,-H(x_var,y_var),0))
𝔘1 = simplify(tmp.args[1] + tmp.args[2].args[1].args[1])*(diff(pₛ(x_var,y_var),x_var) + im * diff(pₛ(x_var,y_var),y_var))
display("Pressure-driven flow field 𝔘₁(x,y):")
display(𝔘1)

nu_var = get_var_in_expr("ν₀" ,Guv_int_wrt_z0)
𝔘2 = simplify(Guv_int_wrt_z0 * τs / (nu_var*ϵ^2))
display("Stress-driven   flow field 𝔘₂(x,y):")
display(𝔘2)
𝔘 = simplify(𝔘1 + 𝔘2) 
𝔘 = simplify(sympify(string(𝔘))) ;

x_var𝔲 = get_var_in_expr("x",𝔲)
y_var𝔲 = get_var_in_expr("y",𝔲)
z_var𝔲 = get_var_in_expr("z",𝔲)
tmp    = integrate(𝔲,(z_var𝔲,-H(x_var𝔲, y_var𝔲),0))
int_𝔲  = simplify(tmp.args[1] + tmp.args[2].args[1].args[1])
int_𝔲  = simplify(sympify(string(int_𝔲)))
res    = int_𝔲 - 𝔘
@assert res == 0

x_var = get_var_in_expr("x",dGuv_dz_at_bottom)
y_var = get_var_in_expr("y",dGuv_dz_at_bottom)
integrand = dGuv_dz_at_bottom * (diff(pₛ(x_var,y_var),x_var) + im * diff(pₛ(x_var,y_var),y_var))
xi_var = get_var_in_expr("ξ" ,integrand)
τb1 = simplify(integrate(expand(integrand),(xi_var,-H(x_var,y_var),0)).args[1].args[1]) 
display("Pressure-driven bottom stress ν d/dz u(x,y,z) @ z = -H:")
display(τb1)

nu_var = get_var_in_expr("ν₀" ,dGuv_dz_at_bottom)
dGuv_dz_at_bottom_and_top = tom_subs(dGuv_dz_at_bottom,Dict(xi_var=>"0"))  
τb2 = simplify(dGuv_dz_at_bottom_and_top * τs / (nu_var*ϵ^2))
display("Stress-driven   bottom stress ν d/dz u(x,y,z) @ z = -H")
display(τb2)
τb = simplify(τb1 + τb2) ;

lhs = im * f * 𝔘
x_var = get_var_in_expr("x",lhs)
y_var = get_var_in_expr("y",lhs)
rhs = H(x_var,y_var)*(diff(pₛ(x_var,y_var),x_var) + im * diff(pₛ(x_var,y_var),y_var))- ϵ^2 * τb + τs
final_eqn = Eq(lhs, rhs)
println()
display("Final equation linking surface pressure pₛ(x,y) to windstress:")
display(final_eqn)

eqn = expand(final_eqn.lhs - final_eqn.rhs)
tmp = tom_subs(eqn,Dict("Derivative(pₛ(x, y), x)"=>"xxx"))
tmp = tom_subs(tmp,sqrt_values)
tmp = tom_subs(tmp,param_values)
tmp = tom_subs(tmp,case_values)
tmp = expand(tmp.n())
xxx_var = get_var_in_expr("xxx",tmp)
sol = solve(Eq(tmp,0), xxx_var)[1]
println()
display("Solution for ∂/∂x pₛ(x):")
display(simplify(sol))

function solve_taux_tauy(f, eqn, var1, var2)
    u, v = real(f), imag(f)
    a = real(eqn.coeff(var1))
    b = imag(eqn.coeff(var1))
    c = real(eqn.coeff(var2))
    d = imag(eqn.coeff(var2))
    eq1 = a*var1 + c*var2 ~ u
    eq2 = b*var1 + d*var2 ~ v
    sol = solve((eq1, eq2), (var1, var2))
    @assert abs(tom_subs(eqn,Dict(var1=>sol[var1],var2=>sol[var2]))) - f < 1e-10            # Check the solution works
    return sol[var1], sol[var2]
end
τˣ_sol, τʸ_sol = solve_taux_tauy(dpsdx_val, sol, get_var_in_expr("τˣ",sol),get_var_in_expr("τʸ",sol))
display("Windstress components (τˣ, τʸ):")
display("τˣ = $τˣ_sol, τʸ = $τʸ_sol")

tmp = tom_subs(𝔘,case_values)
tmp = tom_subs(tmp,sqrt_values)
tmp = tom_subs(tmp,Dict("τˣ"=>τˣ_sol,"τʸ"=>τʸ_sol))
𝔘_val = expand(tom_subs(tmp,param_values).n())
Uval  = float(real(𝔘_val))
Vval  = float(imag(𝔘_val))
display("Resulting flow field 𝔘(x,y) when ∂/∂x pₛ = 1, ∂/∂y pₛ = 0, H(x,y) = 1:")
display("U = $Uval, V = $Vval")

tmp = tom_subs(𝔲,case_values)
tmp = tom_subs(tmp,sqrt_values)
tmp = tom_subs(tmp,Dict("τˣ"=>τˣ_sol,"τʸ"=>τʸ_sol))
𝔲_val = expand(tom_subs(tmp,param_values).n())
# display("Resulting flow field 𝔲(x,y,z) when ∂/∂x pₛ = 1, ∂/∂y pₛ = 0, H(x,y) = 1:")
# display(𝔲_val)
𝔲_fld(z) = tom_subs(𝔲_val,Dict("z"=>z)).n()
zvals = range(-Hfn, 0, length=512)
uvals = [𝔲_fld(z) for z in zvals]
sum_uvals = sum(uvals) * (Hfn / length(zvals))
display("Vertical integral of 𝔲(z) from z = -H to 0:")
display(sum_uvals)
# @assert abs(sum_uvals - 𝔘_val) < 1e-10

plot( real.(uvals), zvals, label="u", lw=2)
plot!(imag.(uvals), zvals, label="v", lw=2)
plot!( [Uval, Uval], [-Hfn, 0], label="U", lw = 2)
plot!( [Vval, Vval], [-Hfn, 0], label="V", lw = 2)
ylabel!("z")
xlabel!("flow field value")
title!("Flow field (u(z), v(z)")


