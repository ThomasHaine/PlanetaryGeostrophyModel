using Gridap

# 1. Geometry and mesh
domain = (0,1,0,1)
partition = (20,20)
model = CartesianDiscreteModel(domain, partition)
Ω = Triangulation(model)
dΩ = Measure(Ω, 2)

# 2. FE spaces
order = 1
reffe = ReferenceFE(lagrangian, Float64, order)
V = TestFESpace(model, reffe; conformity=:H1, dirichlet_tags="boundary")
U = TrialFESpace(V)

# 3. Weak forms
function B_fn(x)
    # x[1]=x, x[2]=y
    return x[1] + im*x[2]^2
end

a(u,v) = ∫( real( ∇(v) ⋅ ∇(u) ) ) * dΩ
l(v)   = ∫( real( (
    ∇(v) ⋅ VectorValue(-1.0, 1im)
) * B_fn ) ) * dΩ

# l(v)   = ∫( (x,)->real( (∇(v)(x) ⋅ VectorValue(-1.0, 1im)) * B_fn(x) ) ) * dΩ


# 4. Assembling/solving
op = AffineFEOperator(a, l, U, V)
psurf = Gridap.solve(op)

# 5. Recover values for plotting
psurf_vals = psurf[]