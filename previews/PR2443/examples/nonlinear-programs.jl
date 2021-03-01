# Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors    #src
# This Source Code Form is subject to the terms of the Mozilla Public License   #src
# v.2.0. If a copy of the MPL was not distributed with this file, You can       #src
# obtain one at https://mozilla.org/MPL/2.0/.                                   #src

# # Nonlinear programs

# These examples use the following packages:

using JuMP
import Ipopt
import Random
import Statistics
import Test

# ## The Rosenbrock function

# A nonlinear example of the classical Rosenbrock function.

function example_rosenbrock()
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    @variable(model, x)
    @variable(model, y)
    @NLobjective(model, Min, (1 - x)^2 + 100 * (y - x^2)^2)
    optimize!(model)

    Test.@test termination_status(model) == MOI.LOCALLY_SOLVED
    Test.@test primal_status(model) == MOI.FEASIBLE_POINT
    Test.@test objective_value(model) ≈ 0.0 atol = 1e-10
    Test.@test value(x) ≈ 1.0
    Test.@test value(y) ≈ 1.0
    return
end

example_rosenbrock()

# ## Maximum likelihood estimation

# Use nonlinear optimization to compute the maximum likelihood estimate (MLE) of
# the parameters of a normal distribution, a.k.a., the sample mean and variance.

function example_mle(; verbose = true)
    n = 1_000
    Random.seed!(1234)
    data = randn(n)
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    @variable(model, μ, start = 0.0)
    @variable(model, σ >= 0.0, start = 1.0)
    @NLobjective(
        model,
        Max,
        n / 2 * log(1 / (2 * π * σ^2)) - sum((data[i] - μ)^2 for i = 1:n) / (2 * σ^2)
    )
    optimize!(model)
    if verbose
        println("μ             = ", value(μ))
        println("mean(data)    = ", Statistics.mean(data))
        println("σ^2           = ", value(σ)^2)
        println("var(data)     = ", Statistics.var(data))
        println("MLE objective = ", objective_value(model))
    end
    Test.@test value(μ) ≈ Statistics.mean(data) atol = 1e-3
    Test.@test value(σ)^2 ≈ Statistics.var(data) atol = 1e-2
    ## You can even do constrained MLE!
    @NLconstraint(model, μ == σ^2)
    optimize!(model)
    Test.@test value(μ) ≈ value(σ)^2
    if verbose
        println()
        println("With constraint μ == σ^2:")
        println("μ                         = ", value(μ))
        println("σ^2                       = ", value(σ)^2)
        println("Constrained MLE objective = ", objective_value(model))
    end
    return
end

example_mle()

# ## The clnlbeam problem

# Based on an AMPL model by Hande Y. Benson
#
# Copyright (C) 2001 Princeton University
# All Rights Reserved

# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted, provided that
# the above copyright notice appear in all copies and that the copyright notice
# and this permission notice appear in all supporting documentation.

# Source: H. Maurer and H.D. Mittelman, "The non-linear beam via optimal control
# with bound state variables", Optimal Control Applications and Methods 12, pp.
# 19-31, 1991.

function example_clnlbeam()
    N = 1000
    h = 1/N
    alpha = 350
    model = Model(Ipopt.Optimizer)
    @variables(model, begin
           -1 <= t[1:(N + 1)] <= 1
        -0.05 <= x[1:(N + 1)] <= 0.05
                 u[1:(N + 1)]
    end)
    @NLobjective(
        model,
        Min,
        sum(
            0.5 * h * (u[i + 1]^2 + u[i]^2) +
            0.5 * alpha * h * (cos(t[i + 1]) + cos(t[i]))
            for i = 1:N
        ),
    )
    @NLconstraint(
        model,
        [i = 1:N],
        x[i + 1] - x[i] - 0.5 * h * (sin(t[i + 1]) + sin(t[i])) == 0,
    )
    @constraint(
        model,
        [i = 1:N],
        t[i + 1] - t[i] - 0.5 * h * u[i + 1] - 0.5 * h * u[i] == 0,
    )
    optimize!(model)
    println("""
    termination_status = $(termination_status(model))
    primal_status      = $(primal_status(model))
    objective_value    = $(objective_value(model))
    """)
    Test.@test termination_status(model) == MOI.LOCALLY_SOLVED  #src
    Test.@test primal_status(model) == MOI.FEASIBLE_POINT  #src
    Test.@test objective_value(model) ≈ 350.0  #src
    return
end

example_clnlbeam()