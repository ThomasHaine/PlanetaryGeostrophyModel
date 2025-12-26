using SymPy
using QuadGK

function eval_terms(args)
    total = 0.0
    for term in args
        if typeof(term) <: SymPy.Sym  # If term involves SymPy
            if !!term.has(SymPy.sympy.Integral)
                # It's something like coefficient * Integral(...)
                # Parse the coefficient and the integral part
                if isa(term, SymPy.Mul)
                    coeff, intpart = term.args
                else
                    # If not Mul, it's just an Integral
                    coeff = 1.0
                    intpart = term
                end

                # Get the function, integration variable, and limit
                f = intpart.args[0]                      # The function, still Symbolic
                var = intpart.args[1][0]                 # Variable of integration
                # bounds = intpart.args[1][1:]             # Lower and upper limit
                lower  = intpart.args[1][1]              # Lower limit
                upper  = intpart.args[1][2]              # Upper limit

                # Try converting f to a Julia function
                # WARNING: This can fail for "funky" symbolic expressions;
                # for common expressions it works.
                # We need to replace SymPy symbols with Julia values

                # Build a Julia callable for the integrand
                j_func = SymPy.Lambda(var, f)
                # Now, integrate numerically via quadgk over the bounds
                result, error = quadgk(x -> j_func(x), float(lower), float(upper))
                total += float(coeff) * result
            else
                # Just a number, add it
                total += float(term)
            end
        else
            # Native Julia float, just add it
            total += term
        end
    end
    return total
end

# Example usage --- assuming tmp.args is your tuple (as in your post)
result = eval_terms(tmp.args)
println("Numerical value: ", result)