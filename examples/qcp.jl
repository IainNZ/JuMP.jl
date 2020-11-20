# # QCP: basic example

# A simple quadratically constrained program based on an [example from Gurobi](https://www.gurobi.com/documentation/9.0/examples/qcp_c_c.html).

using JuMP, Ipopt, Test

function example_qcp(; verbose = true)
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    @variable(model, x)
    @variable(model, y >= 0)
    @variable(model, z >= 0)
    @objective(model, Max, x)
    @constraint(model, x + y + z == 1)
    @constraint(model, x * x + y * y - z * z <= 0)
    @constraint(model, x * x - y * z <= 0)
    optimize!(model)
    if verbose
        print(model)
        println("Objective value: ", objective_value(model))
        println("x = ", value(x))
        println("y = ", value(y))
    end
    @test termination_status(model) == MOI.LOCALLY_SOLVED
    @test primal_status(model) == MOI.FEASIBLE_POINT
    @test objective_value(model) ≈ 0.32699 atol = 1e-5
    @test value(x) ≈ 0.32699 atol = 1e-5
    @test value(y) ≈ 0.25707 atol = 1e-5
end

example_qcp(verbose = false)
