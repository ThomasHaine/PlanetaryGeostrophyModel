using Symbolics
using Gridap
using Gridap.FESpaces
using GridapGmsh
using Gridap.ReferenceFEs
using Profile
using ProfileView
using BenchmarkTools

@variables I        # Placeholder variable for imaginary unit, otherwise Symbolics.jl computes things like sqrt(im) as a numerical value.
@variables z::Real ξ::Real
@variables x::Real y::Real
@variables H(x,y)::Real  
@variables f::Real ν::Real ϕ::Real ϵ::Real
root_iϕ = I^(1//2) * ϕ
@variables κ::Real ψ::Real γ::Real α::Real
∂x = Differential(x)
∂y = Differential(y)

function build_Symbolics_fn(expr,varnames)
	vars = [Symbolics.Variable(Symbol(n)) for n in varnames]							# Extract Symbolics variables from variable names
	I_vars = filter(v -> string(v) == "I", Symbolics.get_variables(expr))				# Check if imaginary unit variable is present and substitute
	if !isempty(I_vars)
    	tmp1 = substitute(expr, Dict(first(I_vars) => im))
	else
	    tmp1 = expr
	end
	tmp2 = expand_derivatives(tmp1)														# Expand derivatives
	tmp3vec = build_function(tmp2, vars; expression=Val{false})
	
	# Wrap function to throw an error if it's called with multiple scalar arguments rather than a vector:
	function tmp3(args::AbstractVector)
    	length(args) == length(vars) || throw(ArgumentError("Input must be vector of length $(length(vars))."))
    	tmp3vec(args)
	end
	tmp3(args...) = throw(MethodError(tmp3, args))
	return tmp3
end

# Define the parameter values
f_val = 1.0
ϵ_val = 0.95
ν_val = 0.06
κ_val = ν_val
γ_val = 0.2
α_val = 0.3
H_val(x,y)    = 1.0 - x^2 - y^2
B_val(x,y,ξ)  = α * ξ

# Compute compound parameter:
ϕ_val = sqrt(f_val / ν_val) / ϵ_val
ψ_val = sqrt(γ_val / κ_val) / ϵ_val

# Define dictionaries for substitutions:
param_values = Dict(f=>f_val, ϵ=>ϵ_val, ν=>ν_val, ϕ=>ϕ_val, γ=>γ_val, α=>α_val, κ=>κ_val, ψ=>ψ_val)
fn_values    = Dict(H=>H_val(x,y))

function define_A_fn()
    A = (I/f) * (H + (1 - exp(2 * root_iϕ * H))/(root_iϕ * (1 + exp(2 * root_iϕ * H))))
    return A
end

function define_B_fn()
    Latex_Bxb_term = α * γ * (exp(ψ * H) - exp(3 * ψ * H))/(κ * ϵ^2 * ψ^3 * (1 + exp(2 * ψ * H))^2)
    Latex_Bxb_term = Latex_Bxb_term * (∂x(H) + I*∂y(H))
    Latex_int_result = exp(root_iϕ * H) * (
        ((1 - exp(- (ψ - root_iϕ)*H))/( ψ - root_iϕ)) +
        ((1 - exp(- (ψ + root_iϕ)*H))/( ψ + root_iϕ)) +
        (2/root_iϕ) * (exp(-root_iϕ * H) - exp(root_iϕ * H)) +
        ((1 - exp(  (ψ + root_iϕ)*H))/(-ψ - root_iϕ)) + 
        ((1 - exp(  (ψ - root_iϕ)*H))/(-ψ + root_iϕ)) +
        ((exp((-ψ + root_iϕ) * H) - exp((ψ + root_iϕ) * H))/ψ)
        )
    Latex_int_result = Latex_int_result + (1/ψ)*(exp(-ψ * H) - exp(ψ * H)) + 2*H*(1 + exp(2*root_iϕ * H))
    Latex_Bxb_term = Latex_Bxb_term * Latex_int_result 
    B = -I * Latex_Bxb_term / (f * (1 + exp(2 * root_iϕ * H)))
    return B
end

function rand_Point()
    while true
        v = rand(2) .* 2 .- 1      # random vector in [-1, 1] × [-1, 1]
        if norm(v) < 0.95
            return Point(v)
        end
    end
end
println("Benchmarking: rand_Point():")
tmp = @benchmark rand_Point()
display(tmp)
println()

# 1. Define the mesh
# model = GmshDiscreteModel("unit_circle_v0.3.msh")           # High res
model = GmshDiscreteModel("unit_circle_v0.2.msh")           # Med res
# model = GmshDiscreteModel("unit_circle_v0.1.msh")           # Low res
Ω = Triangulation(model)
order = 2   # Order of the finite element space
dΩ = Measure(Ω, order)

# 2. Define the finite element space (piecewise linear, Dirichlet zero BC)
order = 2
reffe = ReferenceFE(lagrangian, Float64, order)
V     = TestFESpace(model, reffe; conformity=:H1, dirichlet_tags="boundary")
U     = TrialFESpace(V)

# 3. Define the coefficients of the elliptic equation:
A_fn_tmp0 = substitute(substitute(define_A_fn(),param_values),fn_values)
A_fn_tmp = build_Symbolics_fn(A_fn_tmp0, [x, y])
A_fn(xx) = (typeof(xx[1]) <: Real ? A_fn_tmp([xx[1],xx[2]]) : 1.0)     # Might get called with non-Float argument
println("Benchmarking: A_fn($rand_Point()):")
tmp = @benchmark A_fn($rand_Point())
display(tmp)
println()

B_fn_tmp0 = substitute(substitute(define_B_fn(),param_values),fn_values)
B_fn_tmp = build_Symbolics_fn(B_fn_tmp0, [x, y])
B_fn(xx) = (typeof(xx[1]) <: Real ? B_fn_tmp([xx[1],xx[2]]) : 0.0)     # Might get called with non-Float argument
println("Benchmarking: B_fn($rand_Point()):")
tmp = @benchmark B_fn($rand_Point())
display(tmp)
println()

# 4. Define weak form (variational formulation)
a(u,v) = ∫( real( (∇(v) ⋅ VectorValue( 1.0, -1im)) * (A_fn * (∇(u) ⋅ VectorValue(1.0, 1im))) ) )dΩ
l(v)   = ∫( real( (∇(v) ⋅ VectorValue(-1.0,  1im)) *  B_fn ) )dΩ

# 5. Assemble and solve
op = AffineFEOperator(a, l, U, V)
psurf = Gridap.solve(op)

## Solve 2nd Gridap problem for the stream function (Poisson equation):
# 7. Define the source term:
reffe_vector = ReferenceFE(lagrangian, VectorValue{2,Float64}, order)
V_vec = TestFESpace(model, reffe_vector; conformity=:H1, dirichlet_tags="boundary")
@time "gradpsurf_projection = interpolate(∇(psurf), V_vec)" gradpsurf_projection = interpolate(∇(psurf), V_vec)
println("Benchmarking: g = gradpsurf_projection():")
tmp = @benchmark gradpsurf_projection($(rand_Point()))
display(tmp)
println()

function C_fn(x)
    A = A_fn(x)
    B = B_fn(x)
    g = gradpsurf_projection(x)
    C = A*(g[1] + 1im*g[2]) + B
    return C
end
println("Benchmarking: C_fn($rand_Point()):")
tmp = @benchmark C_fn($rand_Point())
display(tmp)
println()

# 8. Define weak form (variational formulation)
a(u,v) = ∫( ∇(v) ⋅ ∇(u))dΩ
@time "l(v)   = ∫( - real( (∇(v) ⋅ VectorValue(1im, 1.0)) *  C_fn ) )dΩ" l(v)   = ∫( - real( (∇(v) ⋅ VectorValue(1im, 1.0)) *  C_fn ) )dΩ

# 9. Assemble and solve
@time "op = AffineFEOperator(a, l, U, V)" op = AffineFEOperator(a, l, U, V)
@profview  AffineFEOperator(a, l, U, V)


# Faster assembly of complex-valued function uing cached intermediate functions:
ReA_fe = interpolate(x -> real(A_fn(x)), U)
ImA_fe = interpolate(x -> imag(A_fn(x)), U)
ReB_fe = interpolate(x -> real(B_fn(x)), U)
ImB_fe = interpolate(x -> imag(B_fn(x)), U)
AV_fe = (ReA_fe + 1im*ImA_fe)
BV_fe = (ReB_fe + 1im*ImB_fe)
dot_gradp = gradpsurf_projection ⋅ VectorValue(1, 1im)
CCC_fe = AV_fe * dot_gradp + BV_fe   # This is okay
println()
@time "l2(v) = ∫( real( (∇(v) ⋅ VectorValue(1im, 1.0)) * CCC_fe ) )dΩ" l2(v) = ∫( real( (∇(v) ⋅ VectorValue(1im, 1.0)) * CCC_fe ) )dΩ
@time "op2 = AffineFEOperator(a, l, U, V)" op2 = AffineFEOperator(a, l2, U, V)
# @profview AffineFEOperator(a, l2, U, V)
@time "Psi = Gridap.solve(op)" Psi = Gridap.solve(op2)

# 10. Visualization with Paraview: 
writevtk(Ω,"Gridap_MWE2_solution",cellfields=["Psi"=>Psi, "psurf"=>psurf])
