#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at https://mozilla.org/MPL/2.0/.
#############################################################################
# JuMP
# An algebraic modeling language for Julia
# See https://github.com/jump-dev/JuMP.jl
#############################################################################

"""
    JuMP

An algebraic modeling language for Julia.

For more information, go to https://jump.dev.
"""
module JuMP

using LinearAlgebra
using SparseArrays

import MutableArithmetics
const _MA = MutableArithmetics

import MathOptInterface

"""
    MOI

Shorthand for the MathOptInterface package.
"""
const MOI = MathOptInterface

"""
    MOIU

Shorthand for the MathOptInterface.Utilities package.
"""
const MOIU = MOI.Utilities

"""
    MOIB

Shorthand for the MathOptInterface.Bridges package.
"""
const MOIB = MOI.Bridges

import Calculus
import DataStructures.OrderedDict
import ForwardDiff
include("_Derivatives/_Derivatives.jl")
using ._Derivatives

include("Containers/Containers.jl")

# Exports are at the end of the file.

# Deprecations for JuMP v0.18 -> JuMP v0.19 transition
Base.@deprecate(getobjectivevalue, JuMP.objective_value)
Base.@deprecate(getobjectivebound, JuMP.objective_bound)
Base.@deprecate(getvalue,          JuMP.value)
Base.@deprecate(getdual,           JuMP.dual)
Base.@deprecate(numvar,            JuMP.num_variables)
Base.@deprecate(numnlconstr,       JuMP.num_nl_constraints)
Base.@deprecate(setlowerbound,     JuMP.set_lower_bound)
Base.@deprecate(setupperbound,     JuMP.set_upper_bound)
Base.@deprecate(linearterms,       JuMP.linear_terms)

function writeLP(args...; kargs...)
    error("writeLP has been removed from JuMP. Use `write_to_file` instead.")
end
function writeMPS(args...; kargs...)
    error("writeMPS has been removed from JuMP. Use `write_to_file` instead.")
end

include("utils.jl")

const _MOIVAR = MOI.VariableIndex
const _MOICON{F,S} = MOI.ConstraintIndex{F,S}

"""
    optimizer_with_attributes(optimizer_constructor, attrs::Pair...)

Groups an optimizer constructor with the list of attributes `attrs`. Note that
it is equivalent to `MOI.OptimizerWithAttributes`.

When provided to the `Model` constructor or to [`set_optimizer`](@ref), it
creates an optimizer by calling `optimizer_constructor()`, and then sets the
attributes using [`set_optimizer_attribute`](@ref).

## Example

```julia
model = Model(
    optimizer_with_attributes(
        Gurobi.Optimizer, "Presolve" => 0, "OutputFlag" => 1
    )
)
```
is equivalent to:
```julia
model = Model(Gurobi.Optimizer)
set_optimizer_attribute(model, "Presolve", 0)
set_optimizer_attribute(model, "OutputFlag", 1)
```

## Note

The string names of the attributes are specific to each solver. One should
consult the solver's documentation to find the attributes of interest.

See also: [`set_optimizer_attribute`](@ref), [`set_optimizer_attributes`](@ref),
[`get_optimizer_attribute`](@ref).
"""
function optimizer_with_attributes(optimizer_constructor, args::Pair...)
    return MOI.OptimizerWithAttributes(optimizer_constructor, args...)
end

function with_optimizer(constructor; kwargs...)
    if isempty(kwargs)
        deprecation_message = """
`with_optimizer` is deprecated. Adapt the following example to update your code:
`with_optimizer(Ipopt.Optimizer)` becomes `Ipopt.Optimizer`.
"""
        Base.depwarn(deprecation_message, :with_optimizer)
        return constructor
    else
        deprecation_message = """
`with_optimizer` is deprecated. Adapt the following example to update your code:
`with_optimizer(Ipopt.Optimizer, max_cpu_time=60.0)` becomes `optimizer_with_attributes(Ipopt.Optimizer, "max_cpu_time" => 60.0)`.
"""
        Base.depwarn(deprecation_message, :with_optimizer_kw)
        params = [MOI.RawParameter(string(kw.first)) => kw.second for kw in kwargs]
        return MOI.OptimizerWithAttributes(constructor, params)
    end
end
function with_optimizer(constructor, args...; kwargs...)
    if isempty(kwargs)
        deprecation_message = """
`with_optimizer` is deprecated. Adapt the following example to update your code:
`with_optimizer(Gurobi.Optimizer, env)` becomes `() -> Gurobi.Optimizer(env)`.
"""
        Base.depwarn(deprecation_message, :with_optimizer_args)
        if !applicable(constructor, args...)
            error("$constructor does not have any method with arguments $args.",
                  " The first argument of `with_optimizer` should be callable with",
                  " the other argument of `with_optimizer`.")
        end
        return with_optimizer(() -> constructor(args...); kwargs...)
    else
        deprecation_message = """
`with_optimizer` is deprecated. Adapt the following example to update your code:
`with_optimizer(Gurobi.Optimizer, env, Presolve=0)` becomes `optimizer_with_attributes(() -> Gurobi.Optimizer(env), "Presolve" => 0)`.
"""
        Base.depwarn(deprecation_message, :with_optimizer_args_kw)
        if !applicable(constructor, args...)
            error("$constructor does not have any method with arguments $args.",
                  " The first argument of `with_optimizer` should be callable with",
                  " the other argument of `with_optimizer`.")
        end
        params = [MOI.RawParameter(string(kw.first)) => kw.second for kw in kwargs]
        return MOI.OptimizerWithAttributes(() -> constructor(args...), params)
    end
end

include("shapes.jl")

# Model

"""
    ModelMode

An enum to describe the state of the CachingOptimizer inside a JuMP model.
"""
@enum(ModelMode, AUTOMATIC, MANUAL, DIRECT)
@doc("`moi_backend` field holds a CachingOptimizer in AUTOMATIC mode.", AUTOMATIC)
@doc("`moi_backend` field holds a CachingOptimizer in MANUAL mode.", MANUAL)
@doc(
    "`moi_backend` field holds an AbstractOptimizer. No extra copy of the " *
    "model is stored. The `moi_backend` must support `add_constraint` etc.",
    DIRECT,
)

"""
    AbstractModel

An abstract type that should be subtyped for users creating JuMP extensions.
"""
abstract type AbstractModel end
# All `AbstractModel`s must define methods for these functions:
# num_variables, object_dictionary

"""
    Model

A mathematical model of an optimization problem.
"""
mutable struct Model <: AbstractModel
    # In MANUAL and AUTOMATIC modes, CachingOptimizer.
    # In DIRECT mode, will hold an AbstractOptimizer.
    moi_backend::MOI.AbstractOptimizer
    # List of shapes of constraints that are not `ScalarShape` or `VectorShape`.
    shapes::Dict{_MOICON, AbstractShape}
    # List of bridges to add in addition to the ones added in
    # `MOI.Bridges.full_bridge_optimizer`. With `BridgeableConstraint`, the
    # same bridge may be added many times so we store them in a `Set` instead
    # of, e.g., a `Vector`.
    bridge_types::Set{Any}
    # Hook into a solve call...function of the form f(m::Model; kwargs...),
    # where kwargs get passed along to subsequent solve calls.
    optimize_hook
    # TODO: Document.
    nlp_data
    # Dictionary from variable and constraint names to objects.
    obj_dict::Dict{Symbol, Any}
    # Number of times we add large expressions. Incremented and checked by
    # the `operator_warn` method.
    operator_counter::Int
    # Enable extensions to attach arbitrary information to a JuMP model by
    # using an extension-specific symbol as a key.
    ext::Dict{Symbol, Any}
end

"""
    Model(; caching_mode::MOIU.CachingOptimizerMode=MOIU.AUTOMATIC)

Return a new JuMP model without any optimizer; the model is stored the model in
a cache. The mode of the `CachingOptimizer` storing this cache is
`caching_mode`. Use [`set_optimizer`](@ref) to set the optimizer before
calling [`optimize!`](@ref).
"""
function Model(; caching_mode::MOIU.CachingOptimizerMode=MOIU.AUTOMATIC,
                 solver=nothing)
    if solver !== nothing
        error("The solver= keyword is no longer available in JuMP 0.19 and " *
              "later. See the JuMP documentation " *
              "(https://jump.dev/JuMP.jl/latest/) for latest syntax.")
    end
    universal_fallback = MOIU.UniversalFallback(MOIU.Model{Float64}())
    caching_opt = MOIU.CachingOptimizer(universal_fallback,
                                        caching_mode)
    return direct_model(caching_opt)
end

"""
    Model(optimizer_factory;
          caching_mode::MOIU.CachingOptimizerMode=MOIU.AUTOMATIC,
          bridge_constraints::Bool=true)

Return a new JuMP model with the provided optimizer and bridge settings. This
function is equivalent to:
```julia
    model = Model()
    set_optimizer(model, optimizer_factory,
                  bridge_constraints=bridge_constraints)
    return model
```
See [`set_optimizer`](@ref) for the description of the `optimizer_factory` and
`bridge_constraints` arguments.

## Examples

The following creates a model with the optimizer set to `Ipopt`:
```julia
model = Model(Ipopt.Optimizer)
```
"""
function Model(optimizer_factory;
               bridge_constraints::Bool=true, kwargs...)
    model = Model(; kwargs...)
    set_optimizer(model, optimizer_factory,
                  bridge_constraints=bridge_constraints)
    return model
end

"""
    direct_model(backend::MOI.ModelLike)

Return a new JuMP model using [`backend`](@ref) to store the model and solve it. 

As opposed to the [`Model`](@ref) constructor, no cache of the model is stored
outside of [`backend`](@ref) and no bridges are automatically applied to 
[`backend`](@ref).

## Notes

The absence of a cache reduces the memory footprint but, it is important to bear
in mind the following implications of creating models using this *direct* mode:

* When [`backend`](@ref) does not support an operation, such as modifying
  constraints or adding variables/constraints after solving, an error is
  thrown. For models created using the [`Model`](@ref) constructor, such
  situations can be dealt with by storing the modifications in a cache and
  loading them into the optimizer when `optimize!` is called.
* No constraint bridging is supported by default.
* The optimizer used cannot be changed the model is constructed.
* The model created cannot be copied.
"""
function direct_model(backend::MOI.ModelLike)
    @assert MOI.is_empty(backend)
    return Model(backend,
                 Dict{_MOICON, AbstractShape}(),
                 Set{Any}(),
                 nothing,
                 nothing,
                 Dict{Symbol, Any}(),
                 0,
                 Dict{Symbol, Any}())
end

Base.broadcastable(model::Model) = Ref(model)


"""
    backend(model::Model)

Return the lower-level MathOptInterface model that sits underneath JuMP. This
model depends on which operating mode JuMP is in (see [`mode`](@ref)), and
whether there are any bridges in the model.

If JuMP is in `DIRECT` mode (i.e., the model was created using
[`direct_model`](@ref)), the backend will be the optimizer passed to
[`direct_model`](@ref).

If JuMP is in `MANUAL` or `AUTOMATIC` mode, the backend is a
`MOI.Utilities.CachingOptimizer`.

This function should only be used by advanced users looking to access low-level
MathOptInterface or solver-specific functionality.
"""
backend(model::Model) = model.moi_backend

moi_mode(model::MOI.ModelLike) = DIRECT
function moi_mode(model::MOIU.CachingOptimizer)
    if model.mode == MOIU.AUTOMATIC
        return AUTOMATIC
    else
        return MANUAL
    end
end

"""
    mode(model::Model)

Return the `ModelMode` (`DIRECT`, `AUTOMATIC`, or `MANUAL`) of `model`.
"""
function mode(model::Model)
    # The type of `backend(model)` is not type-stable, so we use a function
    # barrier (`moi_mode`) to improve performance.
    return moi_mode(backend(model))
end

# Direct mode
moi_bridge_constraints(model::MOI.ModelLike) = false
function moi_bridge_constraints(model::MOIU.CachingOptimizer)
    return model.optimizer isa MOI.Bridges.LazyBridgeOptimizer
end

# Internal function.
function _try_get_solver_name(model_like)
    try
        return MOI.get(model_like, MOI.SolverName())::String
    catch ex
        if isa(ex, ArgumentError)
            return "SolverName() attribute not implemented by the optimizer."
        else
            rethrow(ex)
        end
    end
end

"""
    solver_name(model::Model)

If available, returns the `SolverName` property of the underlying optimizer.

Returns `"No optimizer attached"` in `AUTOMATIC` or `MANUAL` modes when no
optimizer is attached.

Returns `"SolverName() attribute not implemented by the optimizer."` if the
attribute is not implemented.
"""
function solver_name(model::Model)
    if mode(model) != DIRECT &&
        MOIU.state(backend(model)) == MOIU.NO_OPTIMIZER
        return "No optimizer attached."
    else
        return _try_get_solver_name(backend(model))
    end
end

"""
    bridge_constraints(model::Model)

When in direct mode, return `false`.
When in manual or automatic mode, return a `Bool` indicating whether the
optimizer is set and unsupported constraints are automatically bridged
to equivalent supported constraints when an appropriate transformation is
available.
"""
function bridge_constraints(model::Model)
    # The type of `backend(model)` is not type-stable, so we use a function
    # barrier (`moi_bridge_constraints`) to improve performance.
    return moi_bridge_constraints(backend(model))
end

function _moi_add_bridge(model::Nothing,
                        BridgeType::Type{<:MOI.Bridges.AbstractBridge})
    # No optimizer is attached, the bridge will be added when one is attached
    return
end
function _moi_add_bridge(model::MOI.ModelLike,
                        BridgeType::Type{<:MOI.Bridges.AbstractBridge})
    error("Cannot add bridge if `bridge_constraints` was set to `false` in the",
          " `Model` constructor.")
end
function _moi_add_bridge(bridge_opt::MOI.Bridges.LazyBridgeOptimizer,
                        BridgeType::Type{<:MOI.Bridges.AbstractBridge})
    MOI.Bridges.add_bridge(bridge_opt, BridgeType{Float64})
    return
end
function _moi_add_bridge(caching_opt::MOIU.CachingOptimizer,
                        BridgeType::Type{<:MOI.Bridges.AbstractBridge})
    _moi_add_bridge(caching_opt.optimizer, BridgeType)
    return
end


"""
     add_bridge(model::Model,
                BridgeType::Type{<:MOI.Bridges.AbstractBridge})

Add `BridgeType` to the list of bridges that can be used to transform
unsupported constraints into an equivalent formulation using only constraints
supported by the optimizer.
"""
function add_bridge(model::Model,
                    BridgeType::Type{<:MOI.Bridges.AbstractBridge})
    push!(model.bridge_types, BridgeType)
    # The type of `backend(model)` is not type-stable, so we use a function
    # barrier (`_moi_add_bridge`) to improve performance.
    _moi_add_bridge(JuMP.backend(model), BridgeType)
    return
end

"""
     print_bridge_graph([io::IO,] model::Model)

Print the hyper-graph containing all variable, constraint, and objective types
that could be obtained by bridging the variables, constraints, and objectives
that are present in the model.

Each node in the hyper-graph corresponds to a variable, constraint, or objective
type.
  * Variable nodes are indicated by `[ ]`
  * Constraint nodes are indicated by `( )`
  * Objective nodes are indicated by `| |`
The number inside each pair of brackets is an index of the node in the
hyper-graph.

Note that this hyper-graph is the full list of possible transformations. When
the bridged model is created, we select the shortest hyper-path(s) from this
graph, so many nodes may be un-used.

For more information, see Legat, B., Dowson, O., Garcia, J., and Lubin, M.
(2020).  "MathOptInterface: a data structure for mathematical optimization
problems." URL: [https://arxiv.org/abs/2002.03447](https://arxiv.org/abs/2002.03447)
"""
print_bridge_graph(model::Model) = print_bridge_graph(Base.stdout, model)

function print_bridge_graph(io::IO, model::Model)
    # The type of `backend(model)` is not type-stable, so we use a function
    # barrier (`_moi_print_bridge_graph`) to improve performance.
    return _moi_print_bridge_graph(io, backend(model))
end

function _moi_print_bridge_graph(
    io::IO, model::MOI.Bridges.LazyBridgeOptimizer
)
    return MOI.Bridges.print_graph(io, model)
end

function _moi_print_bridge_graph(io::IO, model::MOIU.CachingOptimizer)
    return _moi_print_bridge_graph(io, model.optimizer)
end

function _moi_print_bridge_graph(::IO, ::MOI.ModelLike)
    error(
        "Cannot print bridge graph if `bridge_constraints` was set to " *
        "`false` in the `Model` constructor."
    )
end

"""
    empty!(model::Model)::Model

Empty the model, that is, remove all variables, constraints and model
attributes but not optimizer attributes. Always return the argument.

Note: removes extensions data.
"""
function Base.empty!(model::Model)::Model
    # The method changes the Model object to, basically, the state it was when
    # created (if the optimizer was already pre-configured). The exceptions
    # are:
    # * optimize_hook: it is basically an optimizer attribute and we promise
    #   to leave them alone (as do MOI.empty!).
    # * bridge_types: for consistency with MOI.empty! for
    #   MOI.Bridges.LazyBridgeOptimizer.
    # * operator_counter: it is just a counter for a single-time warning
    #   message (so keeping it helps to discover inneficiencies).
    MOI.empty!(model.moi_backend)
    empty!(model.shapes)
    model.nlp_data = nothing
    empty!(model.obj_dict)
    empty!(model.ext)
    return model
end

"""
    num_variables(model::Model)::Int64

Returns number of variables in `model`.
"""
num_variables(model::Model)::Int64 = MOI.get(model, MOI.NumberOfVariables())

"""
    num_nl_constraints(model::Model)

Returns the number of nonlinear constraints associated with the `model`.
"""
function num_nl_constraints(model::Model)
    return model.nlp_data !== nothing ? length(model.nlp_data.nlconstr) : 0
end

"""
    object_dictionary(model::Model)

Return the dictionary that maps the symbol name of a variable, constraint, or
expression to the corresponding object.

Objects are registered to a specific symbol in the macros.
For example, `@variable(model, x[1:2, 1:2])` registers the array of variables
`x` to the symbol `:x`.

This method should be defined for any subtype of `AbstractModel`.
"""
object_dictionary(model::Model) = model.obj_dict

"""
    unregister(model::Model, key::Symbol)

Unregister the name `key` from `model` so that a new variable, constraint, or
expression can be created with the same key.

Note that this will not delete the object `model[key]`; it will just remove the
reference at `model[key]`. To delete the object, use
```julia
delete(model, model[key])
unregister(model, key)
```

See also: [`object_dictionary`](@ref).

## Examples

```jldoctest; setup=:(model = Model())
julia> @variable(model, x)
x

julia> @variable(model, x)
ERROR: An object of name x is already attached to this model. If
this is intended, consider using the anonymous construction syntax,
e.g., `x = @variable(model, [1:N], ...)` where the name of the object
does not appear inside the macro.

Alternatively, use `unregister(model, :x)` to first unregister the
existing name from the model. Note that this will not delete the object;
it will just remove the reference at `model[:x]`.
[...]

julia> num_variables(model)
1

julia> unregister(model, :x)

julia> @variable(model, x)
x

julia> num_variables(model)
2
```
"""
function unregister(model::AbstractModel, key::Symbol)
    delete!(object_dictionary(model), key)
    return
end

"""
    termination_status(model::Model)

Return the reason why the solver stopped (i.e., the MathOptInterface model
attribute `TerminationStatus`).
"""
function termination_status(model::Model)
    return MOI.get(model, MOI.TerminationStatus())::MOI.TerminationStatusCode
end

"""
    raw_status(model::Model)

Return the reason why the solver stopped in its own words (i.e., the
MathOptInterface model attribute `RawStatusString`).
"""
function raw_status(model::Model)
    return MOI.get(model, MOI.RawStatusString())
end

"""
    primal_status(model::Model; result::Int = 1)

Return the status of the most recent primal solution of the solver (i.e., the
MathOptInterface model attribute `PrimalStatus`) associated with the result
index `result`.

See also: [`result_count`](@ref).
"""
function primal_status(model::Model; result::Int = 1)
    return MOI.get(model, MOI.PrimalStatus(result))::MOI.ResultStatusCode
end

"""
    dual_status(model::Model; result::Int = 1)

Return the status of the most recent dual solution of the solver (i.e., the
MathOptInterface model attribute `DualStatus`) associated with the result
index `result`.

See also: [`result_count`](@ref).
"""
function dual_status(model::Model; result::Int = 1)
    return MOI.get(model, MOI.DualStatus(result))::MOI.ResultStatusCode
end

"""
    set_optimize_hook(model::Model, f::Union{Function,Nothing})

Set the function `f` as the optimize hook for `model`.

`f` should have a signature `f(model::Model; kwargs...)`, where the `kwargs` are
those passed to [`optimize!`](@ref).

## Notes

 * The optimize hook should generally modify the model, or some external state
   in some way, and then call `optimize!(model; ignore_optimize_hook = true)` to
   optimize the problem, bypassing the hook.
 * Use `set_optimize_hook(model, nothing)` to unset an optimize hook.

## Examples

```julia
model = Model()
function my_hook(model::Model; kwargs...)
    print(kwargs)
    return optimize!(model; ignore_optimize_hook = true)
end
set_optimize_hook(model, my_hook)
optimize!(model; test_arg = true)
```
"""
set_optimize_hook(model::Model, f) = (model.optimize_hook = f)

"""
    solve_time(model::Model)

If available, returns the solve time reported by the solver.
Returns "ArgumentError: ModelLike of type `Solver.Optimizer` does not support accessing
the attribute MathOptInterface.SolveTime()" if the attribute is
not implemented.
"""
function solve_time(model::Model)
    return MOI.get(model, MOI.SolveTime())
end

"""
    set_optimizer_attribute(model::Model, name::String, value)

Sets solver-specific attribute identified by `name` to `value`.

Note that this is equivalent to
`set_optimizer_attribute(model, MOI.RawParameter(name), value)`.

## Example

```julia
set_optimizer_attribute(model, "SolverSpecificAttributeName", true)
```

See also: [`set_optimizer_attributes`](@ref), [`get_optimizer_attribute`](@ref).
"""
function set_optimizer_attribute(model::Model, name::String, value)
    return set_optimizer_attribute(model, MOI.RawParameter(name), value)
end

"""
    set_optimizer_attribute(
        model::Model, attr::MOI.AbstractOptimizerAttribute, value
    )

Set the solver-specific attribute `attr` in `model` to `value`.

## Example

```julia
set_optimizer_attribute(model, MOI.Silent(), true)
```

See also: [`set_optimizer_attributes`](@ref), [`get_optimizer_attribute`](@ref).
"""
function set_optimizer_attribute(
    model::Model, attr::MOI.AbstractOptimizerAttribute, value
)
    return MOI.set(model, attr, value)
end

@deprecate set_parameter set_optimizer_attribute

"""
    set_optimizer_attributes(model::Model, pairs::Pair...)

Given a list of `attribute => value` pairs, calls
`set_optimizer_attribute(model, attribute, value)` for each pair.

## Example

```julia
model = Model(Ipopt.Optimizer)
set_optimizer_attributes(model, "tol" => 1e-4, "max_iter" => 100)
```
is equivalent to:
```julia
model = Model(Ipopt.Optimizer)
set_optimizer_attribute(model, "tol", 1e-4)
set_optimizer_attribute(model, "max_iter", 100)
```

See also: [`set_optimizer_attribute`](@ref), [`get_optimizer_attribute`](@ref).
"""
function set_optimizer_attributes(model::Model, pairs::Pair...)
    for (name, value) in pairs
        set_optimizer_attribute(model, name, value)
    end
end

@deprecate set_parameters set_optimizer_attributes

"""
    get_optimizer_attribute(model, name::String)

Return the value associated with the solver-specific attribute named `name`.

Note that this is equivalent to
`get_optimizer_attribute(model, MOI.RawParameter(name))`.

## Example

```julia
get_optimizer_attribute(model, "SolverSpecificAttributeName")
```

See also: [`set_optimizer_attribute`](@ref), [`set_optimizer_attributes`](@ref).
"""
function get_optimizer_attribute(model::Model, name::String)
    return get_optimizer_attribute(model, MOI.RawParameter(name))
end

"""
    get_optimizer_attribute(
        model::Model, attr::MOI.AbstractOptimizerAttribute
    )

Return the value of the solver-specific attribute `attr` in `model`.

## Example

```julia
get_optimizer_attribute(model, MOI.Silent())
```

See also: [`set_optimizer_attribute`](@ref), [`set_optimizer_attributes`](@ref).
"""
function get_optimizer_attribute(
    model::Model, attr::MOI.AbstractOptimizerAttribute
)
    return MOI.get(model, attr)
end

"""
    set_silent(model::Model)

Takes precedence over any other attribute controlling verbosity and requires the
solver to produce no output.

See also: [`unset_silent`](@ref).
"""
function set_silent(model::Model)
    return MOI.set(model, MOI.Silent(), true)
end

"""
    unset_silent(model::Model)

Neutralize the effect of the `set_silent` function and let the solver attributes
control the verbosity.

See also: [`set_silent`](@ref).
"""
function unset_silent(model::Model)
    return MOI.set(model, MOI.Silent(), false)
end

"""
    set_time_limit_sec(model::Model, limit)

Set the time limit (in seconds) of the solver.

Can be unset using [`unset_time_limit_sec`](@ref) or with `limit` set to
`nothing`.

See also: [`unset_time_limit_sec`](@ref), [`time_limit_sec`](@ref).
"""
function set_time_limit_sec(model::Model, limit)
    return MOI.set(model, MOI.TimeLimitSec(), limit)
end

"""
    unset_time_limit_sec(model::Model)

Unset the time limit of the solver.

See also: [`set_time_limit_sec`](@ref), [`time_limit_sec`](@ref).
"""
function unset_time_limit_sec(model::Model)
    return MOI.set(model, MOI.TimeLimitSec(), nothing)
end

"""
    time_limit_sec(model::Model)

Return the time limit (in seconds) of the `model`.

Returns `nothing` if unset.

See also: [`set_time_limit_sec`](@ref), [`unset_time_limit_sec`](@ref).
"""
function time_limit_sec(model::Model)
    return MOI.get(model, MOI.TimeLimitSec())
end

"""
    simplex_iterations(model::Model)

Gets the cumulative number of simplex iterations during the most-recent optimization.

Solvers must implement `MOI.SimplexIterations()` to use this function.
"""
function simplex_iterations(model::Model)
    return MOI.get(model, MOI.SimplexIterations())
end

"""
    barrier_iterations(model::Model)

Gets the cumulative number of barrier iterations during the most recent optimization.

Solvers must implement `MOI.BarrierIterations()` to use this function.
"""
function barrier_iterations(model::Model)
    return MOI.get(model, MOI.BarrierIterations())
end

"""
    node_count(model::Model)

Gets the total number of branch-and-bound nodes explored during the most recent
optimization in a Mixed Integer Program.

Solvers must implement `MOI.NodeCount()` to use this function.
"""
function node_count(model::Model)
    return MOI.get(model, MOI.NodeCount())
end

# Abstract base type for all scalar types
# The subtyping of `AbstractMutable` will allow calls of some `Base` functions
# to be redirected to a method in MA that handles type promotion more carefuly
# (e.g. the promotion in sparse matrix products in SparseArrays usually does not
# work for JuMP types) and exploits the mutability of `AffExpr` and `QuadExpr`.
abstract type AbstractJuMPScalar <: _MA.AbstractMutable end
Base.ndims(::Type{<:AbstractJuMPScalar}) = 0

# These are required to create symmetric containers of AbstractJuMPScalars.
LinearAlgebra.symmetric_type(::Type{T}) where T <: AbstractJuMPScalar = T
LinearAlgebra.symmetric(scalar::AbstractJuMPScalar, ::Symbol) = scalar
# This is required for linear algebra operations involving transposes.
LinearAlgebra.adjoint(scalar::AbstractJuMPScalar) = scalar

"""
    owner_model(s::AbstractJuMPScalar)

Return the model owning the scalar `s`.
"""
function owner_model end

Base.iterate(x::AbstractJuMPScalar) = (x, true)
Base.iterate(::AbstractJuMPScalar, state) = nothing
Base.isempty(::AbstractJuMPScalar) = false

# Check if two arrays of AbstractJuMPScalars are equal. Useful for testing.
function isequal_canonical(x::AbstractArray{<:JuMP.AbstractJuMPScalar},
                           y::AbstractArray{<:JuMP.AbstractJuMPScalar})
    return size(x) == size(y) && all(JuMP.isequal_canonical.(x, y))
end

include("constraints.jl")
include("variables.jl")
include("objective.jl")

Base.zero(::Type{V}) where V<:AbstractVariableRef = zero(GenericAffExpr{Float64, V})
Base.zero(v::AbstractVariableRef) = zero(typeof(v))
Base.one(::Type{V}) where V<:AbstractVariableRef = one(GenericAffExpr{Float64, V})
Base.one(v::AbstractVariableRef) = one(typeof(v))

mutable struct VariableNotOwnedError <: Exception
    context::String
end
function Base.showerror(io::IO, ex::VariableNotOwnedError)
    print(io, "VariableNotOwnedError: Variable not owned by model present in $(ex.context)")
end

_moi_optimizer_index(model::MOI.AbstractOptimizer, index::MOI.Index) = index
function _moi_optimizer_index(model::MOIU.CachingOptimizer, index::MOI.Index)
    if MOIU.state(model) == MOIU.NO_OPTIMIZER
        throw(NoOptimizer())
    elseif MOIU.state(model) == MOIU.EMPTY_OPTIMIZER
        error("There is no `optimizer_index` as the optimizer is not ",
              "synchronized with the cached model. Call ",
              "`MOIU.attach_optimizer(model)` to synchronize it.")
    else
        @assert MOIU.state(model) == MOIU.ATTACHED_OPTIMIZER
        return _moi_optimizer_index(model.optimizer,
                                    model.model_to_optimizer_map[index])
    end
end
function _moi_optimizer_index(model::MOI.Bridges.LazyBridgeOptimizer,
                              index::MOI.Index)
    if index isa MOI.ConstraintIndex &&
        MOI.Bridges.is_bridged(model, index)
        error("There is no `optimizer_index` for $(typeof(index)) constraints",
              " because they are bridged.")
    else
        return _moi_optimizer_index(model.model, index)
    end
end


"""
    optimizer_index(v::VariableRef)::MOI.VariableIndex

Return the index of the variable that corresponds to `v` in the optimizer model.
It throws [`NoOptimizer`](@ref) if no optimizer is set and throws an
`ErrorException` if the optimizer is set but is not attached.
"""
function optimizer_index(v::VariableRef)
    model = owner_model(v)
    if mode(model) == DIRECT
        return index(v)
    else
        return _moi_optimizer_index(backend(model), index(v))
    end
end

"""
    optimizer_index(cr::ConstraintRef{Model})::MOI.ConstraintIndex

Return the index of the constraint that corresponds to `cr` in the optimizer
model. It throws [`NoOptimizer`](@ref) if no optimizer is set and throws an
`ErrorException` if the optimizer is set but is not attached or if the
constraint is bridged.
"""
function optimizer_index(cr::ConstraintRef{Model})
    if mode(cr.model) == DIRECT
        return index(cr)
    else
        return _moi_optimizer_index(backend(cr.model), index(cr))
    end
end

"""
    index(cr::ConstraintRef)::MOI.ConstraintIndex

Return the index of the constraint that corresponds to `cr` in the MOI backend.
"""
index(cr::ConstraintRef) = cr.index

"""
    struct OptimizeNotCalled <: Exception end

A result attribute cannot be queried before [`optimize!`](@ref) is called.
"""
struct OptimizeNotCalled <: Exception end

"""
    struct NoOptimizer <: Exception end

No optimizer is set. The optimizer can be provided to the [`Model`](@ref)
constructor or by calling [`set_optimizer`](@ref).
"""
struct NoOptimizer <: Exception end

# Throws an error if `optimize!` has not been called, i.e., if there is no
# optimizer attached or if the termination status is `MOI.OPTIMIZE_NOT_CALLED`.
function _moi_get_result(model::MOI.ModelLike, args...)
    if MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED
        throw(OptimizeNotCalled())
    end
    return MOI.get(model, args...)
end
function _moi_get_result(model::MOIU.CachingOptimizer, args...)
    if MOIU.state(model) == MOIU.NO_OPTIMIZER
        throw(NoOptimizer())
    elseif MOI.get(model, MOI.TerminationStatus()) == MOI.OPTIMIZE_NOT_CALLED
        throw(OptimizeNotCalled())
    end
    return MOI.get(model, args...)
end

"""
    get(model::Model, attr::MathOptInterface.AbstractModelAttribute)

Return the value of the attribute `attr` from the model's MOI backend.
"""
function MOI.get(model::Model, attr::MOI.AbstractModelAttribute)
    if MOI.is_set_by_optimize(attr) &&
       !(attr isa MOI.TerminationStatus) && # Before `optimize!` is called, the
       !(attr isa MOI.PrimalStatus) &&      # statuses are `OPTIMIZE_NOT_CALLED`
       !(attr isa MOI.DualStatus)           # and `NO_SOLUTION`
        _moi_get_result(backend(model), attr)
    else
        MOI.get(backend(model), attr)
    end
end
"""
    get(model::Model, attr::MathOptInterface.AbstractOptimizerAttribute)

Return the value of the attribute `attr` from the model's MOI backend.
"""
function MOI.get(model::Model, attr::MOI.AbstractOptimizerAttribute)
    MOI.get(backend(model), attr)
end
function MOI.get(model::Model, attr::MOI.AbstractVariableAttribute,
                 v::VariableRef)
    check_belongs_to_model(v, model)
    if MOI.is_set_by_optimize(attr)
        return _moi_get_result(backend(model), attr, index(v))
    else
        return MOI.get(backend(model), attr, index(v))
    end
end
function MOI.get(model::Model, attr::MOI.AbstractConstraintAttribute,
                 cr::ConstraintRef)
    check_belongs_to_model(cr, model)
    if MOI.is_set_by_optimize(attr)
        return _moi_get_result(backend(model), attr, index(cr))
    else
        return MOI.get(backend(model), attr, index(cr))
    end
end

MOI.set(m::Model, attr::MOI.AbstractOptimizerAttribute, value) = MOI.set(backend(m), attr, value)
MOI.set(m::Model, attr::MOI.AbstractModelAttribute, value) = MOI.set(backend(m), attr, value)
function MOI.set(model::Model, attr::MOI.AbstractVariableAttribute,
                 v::VariableRef, value)
    check_belongs_to_model(v, model)
    MOI.set(backend(model), attr, index(v), value)
end
function MOI.set(model::Model, attr::MOI.AbstractConstraintAttribute,
                 cr::ConstraintRef, value)
    check_belongs_to_model(cr, model)
    MOI.set(backend(model), attr, index(cr), value)
end

const _Constant = Union{Number, UniformScaling}
_constant_to_number(x::Number) = x
_constant_to_number(J::UniformScaling) = J.λ

# GenericAffineExpression, AffExpr, AffExprConstraint
include("aff_expr.jl")

# GenericQuadExpr, QuadExpr
# GenericQuadConstraint, QuadConstraint
include("quad_expr.jl")

include("mutable_arithmetics.jl")

include("sets.jl")

# Indicator constraint
include("indicator.jl")
# Complementarity constraint
include("complement.jl")
# SDConstraint
include("sd.jl")

"""
    Base.getindex(m::JuMP.AbstractModel, name::Symbol)

To allow easy accessing of JuMP Variables and Constraints via `[]` syntax.
Returns the variable, or group of variables, or constraint, or group of constraints, of the given name which were added to the model. This errors if multiple variables or constraints share the same name.
"""
function Base.getindex(m::JuMP.AbstractModel, name::Symbol)
    obj_dict = object_dictionary(m)
    if !haskey(obj_dict, name)
        throw(KeyError(name))
    elseif obj_dict[name] === nothing
        error("There are multiple variables and/or constraints named $name that are already attached to this model. If creating variables programmatically, use the anonymous variable syntax x = @variable(m, [1:N], ...). If creating constraints programmatically, use the anonymous constraint syntax con = @constraint(m, ...).")
    else
        return obj_dict[name]
    end
end

"""
    Base.setindex!(m::JuMP.AbstractModel, value, name::Symbol)

stores the object `value` in the model `m` using so that it can be accessed via `getindex`.  Can be called with `[]` syntax.
"""
function Base.setindex!(model::AbstractModel, value, name::Symbol)
    # if haskey(object_dictionary(model), name)
    #     warn("Overwriting the object $name stored in the model. Consider using anonymous variables and constraints instead")
    # end
    object_dictionary(model)[name] = value
end

"""
    haskey(model::AbstractModel, name::Symbol)

Determine whether the model has a mapping for a given name.
"""
function Base.haskey(model::AbstractModel, name::Symbol)
    return haskey(object_dictionary(model), name)
end

"""
    operator_warn(model::AbstractModel)
    operator_warn(model::Model)

This function is called on the model whenever two affine expressions are added
together without using `destructive_add!`, and at least one of the two
expressions has more than 50 terms.

For the case of `Model`, if this function is called more than 20,000 times then
a warning is generated once.
"""
function operator_warn(::AbstractModel) end
function operator_warn(model::Model)
    model.operator_counter += 1
    if model.operator_counter > 20000
        @warn(
            "The addition operator has been used on JuMP expressions a large " *
            "number of times. This warning is safe to ignore but may " *
            "indicate that model generation is slower than necessary. For " *
            "performance reasons, you should not add expressions in a loop. " *
            "Instead of x += y, use add_to_expression!(x,y) to modify x in " *
            "place. If y is a single variable, you may also use " *
            "add_to_expression!(x, coef, y) for x += coef*y.", maxlog = 1)
    end
end

# TODO: rename "m" field to "model" for style compliance
"""
    NonlinearExpression

A struct to represent a nonlinear expression.

Create an expression using [`@NLexpression`](@ref).
"""
struct NonlinearExpression
    m::Model
    index::Int
end

"""
    NonlinearParameter

A struct to represent a nonlinear parameter.

Create a parameter using [`@NLparameter`](@ref).
"""
struct NonlinearParameter <: AbstractJuMPScalar
    m::Model
    index::Int
end

include("copy.jl")
include("operators.jl")
include("macros.jl")
include("optimizer_interface.jl")
include("nlp.jl")
include("print.jl")
include("lp_sensitivity.jl")
include("lp_sensitivity2.jl")
include("callbacks.jl")
include("file_formats.jl")

# JuMP exports everything except internal symbols, which are defined as those
# whose name starts with an underscore. Macros whose names start with
# underscores are internal as well. If you don't want all of these symbols
# in your environment, then use `import JuMP` instead of `using JuMP`.

# Do not add JuMP-defined symbols to this exclude list. Instead, rename them
# with an underscore.
const _EXCLUDE_SYMBOLS = [Symbol(@__MODULE__), :eval, :include]

for sym in names(@__MODULE__, all=true)
    sym_string = string(sym)
    if sym in _EXCLUDE_SYMBOLS || startswith(sym_string, "_") ||
         startswith(sym_string, "@_")
        continue
    end
    if !(Base.isidentifier(sym) || (startswith(sym_string, "@") &&
         Base.isidentifier(sym_string[2:end])))
       continue
    end
    @eval export $sym
end

end
