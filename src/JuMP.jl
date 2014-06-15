#############################################################################
# JuMP
# An algebraic modelling langauge for Julia
# See http://github.com/JuliaOpt/JuMP.jl
#############################################################################

module JuMP

import MathProgBase
import Base: size, copy, zero, one, isequal, issym

using ReverseDiffSparse
if isdir(Pkg.dir("ArrayViews"))
    eval(Expr(:import,:ArrayViews))
    const subarr = ArrayViews.view
else
    const subarr = Base.sub
end

export
# Objects
    Model, Variable, AffExpr, QuadExpr, LinearConstraint, QuadConstraint, MultivarDict,
    ConstraintRef,
# Functions
    # Model related
    getNumVars, getNumConstraints, getObjectiveValue, getObjective,
    getObjectiveSense, setObjectiveSense, writeLP, writeMPS, setObjective,
    addConstraint, addSOS1, addSOS2, solve,
    getInternalModel, setPresolve, buildInternalModel,
    # Variable
    setName, getName, setLower, setUpper, getLower, getUpper,
    getValue, setValue, getDual,
    # Expressions and constraints
    affToStr, quadToStr, conToStr, chgConstrRHS,
    
# Macros and support functions
    @addConstraint, @addConstraints, @defVar, 
    @defConstrRef, @setObjective, addToExpression,
    @setNLObjective, @addNLConstraint

include("JuMPDict.jl")
include("utils.jl")

###############################################################################
# Constants
const CONTINUOUS = 0
const INTEGER = 1
export CONTINUOUS, INTEGER

###############################################################################
# Model class
# Keeps track of all model and column info
type Model
    obj#::QuadExpr
    objSense::Symbol
    
    linconstr#::Vector{LinearConstraint}
    quadconstr
    sosconstr
    
    # Column data
    numCols::Int
    colNames::Vector{String}
    colLower::Vector{Float64}
    colUpper::Vector{Float64}
    colCat::Vector{Int}

    # Solution data
    objVal
    colVal::Vector{Float64}
    redCosts::Vector{Float64}
    linconstrDuals::Vector{Float64}
    # internal solver model object
    internalModel
    # Solver+option object from MathProgBase
    solver::MathProgBase.AbstractMathProgSolver
    internalModelLoaded::Bool
    # callbacks
    lazycallback
    cutcallback
    heurcallback

    # JuMPDict list
    dictList::Vector

    # presolve callback function
    presolve
    # storage vector for merging duplicate terms
    indexedVector::IndexedVector{Float64}

    nlpdata#::NLPData
    sdpdata

    # Extension dictionary - e.g. for robust
    # Extensions should define a type to hold information particular to
    # their functionality, and store an instance of the type in this
    # dictionary keyed on an extension-specific symbol
    ext::Dict{Symbol,Any}
end

# dummy solver
type UnsetSolver <: MathProgBase.AbstractMathProgSolver
end

# Default constructor
function Model(;solver=nothing)
    if solver == nothing
        # use default solvers
        Model(QuadExpr(),:Min,LinearConstraint[], QuadConstraint[],SOSConstraint[],
              0,String[],Float64[],Float64[],Int[],
              0,Float64[],Float64[],Float64[],nothing,UnsetSolver(),false,
              nothing,nothing,nothing,JuMPDict[],nothing,IndexedVector(Float64,0),nothing,nothing,Dict{Symbol,Any}())
    else
        if !isa(solver,MathProgBase.AbstractMathProgSolver)
            error("solver argument ($solver) must be an AbstractMathProgSolver")
        end
        # user-provided solver must support problem class
        Model(QuadExpr(),:Min,LinearConstraint[], QuadConstraint[],SOSConstraint[],
              0,String[],Float64[],Float64[],Int[],
              0,Float64[],Float64[],Float64[],nothing,solver,false,
              nothing,nothing,nothing,JuMPDict[],nothing,IndexedVector(Float64,0),nothing,nothing,Dict{Symbol,Any}())
    end
end

# Getters/setters
getNumVars(m::Model) = m.numCols
getNumConstraints(m::Model) = length(m.linconstr)
getObjectiveValue(m::Model) = m.objVal
getObjectiveSense(m::Model) = m.objSense
function setObjectiveSense(m::Model, newSense::Symbol)
    if (newSense != :Max && newSense != :Min)
        error("Model sense must be :Max or :Min")
    end
    m.objSense = newSense
end

# Deep copy the model
function Base.copy(source::Model)
    
    dest = Model()
    dest.solver = source.solver  # The two models are linked by this
    dest.lazycallback = source.lazycallback
    dest.cutcallback  = source.cutcallback
    dest.heurcallback = source.heurcallback
    dest.ext = source.ext  # Should probably be deep copy
    if length(source.ext) >= 1
        Base.warn_once("Copying model with extensions - not deep copying extension-specific information.")
    end
    
    # Objective
    dest.obj = copy(source.obj, dest)
    dest.objSense = source.objSense

    # Constraints
    dest.linconstr = [copy(c, dest) for c in source.linconstr]
    dest.quadconstr = [copy(c, dest) for c in source.quadconstr]

    # Variables
    dest.numCols = source.numCols
    dest.colNames = source.colNames[:]
    dest.colLower = source.colLower[:]
    dest.colUpper = source.colUpper[:]
    dest.colCat = source.colCat[:]

    if source.nlpdata != nothing
        dest.nlpdata = copy(source.nlpdata)
    end

    return dest
end

getInternalModel(m::Model) = m.internalModel

setPresolve(m::Model, f::Function) = (m.presolve = f)

###############################################################################
# Variable class
# Doesn't actually do much, just a pointer back to the model
type Variable <: ReverseDiffSparse.Placeholder
    m::Model
    col::Int
end

ReverseDiffSparse.getplaceindex(x::Variable) = x.col
Base.isequal(x::Variable,y::Variable) = isequal(x.col,y.col) && isequal(x.m,y.m)

getindex(x::Variable) = x.col
getindex(x::Variable,idx::Int) = (idx == 1 ? x : throw(BoundsError()))
getindex(x::Variable,idx::Int,idy::Int) = ((idx,idy) == (1,1) ? x : throw(BoundsError()))

isequal(x::Variable,y::Variable) = isequal(x.col,y.col) && isequal(x.m,y.m)

function Variable(m::Model,lower::Number,upper::Number,cat::Int,name::String)
    m.numCols += 1
    push!(m.colNames, name)
    push!(m.colLower, convert(Float64,lower))
    push!(m.colUpper, convert(Float64,upper))
    push!(m.colCat, cat)
    push!(m.colVal,NaN)
    return Variable(m, m.numCols)
end

Variable(m::Model,lower::Number,upper::Number,cat::Int) =
    Variable(m,lower,upper,cat,"")

size(v::Variable) = (1,)
size(v::Variable,sl::Int) = 1

# Name setter/getters
setName(v::Variable,n::String) = (v.m.colNames[v.col] = n)
function getName(m::Model, col)
    m.colNames[col] == "" && fillVarNames(m)
    return ( m.colNames[col] == "" ? "_col$(col)" : m.colNames[col] )
end
getName(v::Variable) = getName(v.m, v.col)

# Bound setter/getters
setLower(v::Variable,lower::Number) = (v.m.colLower[v.col] = convert(Float64,lower))
setUpper(v::Variable,upper::Number) = (v.m.colUpper[v.col] = convert(Float64,upper))
getLower(v::Variable) = v.m.colLower[v.col]
getUpper(v::Variable) = v.m.colUpper[v.col]

# Value setter/getter
function setValue(v::Variable, val::Number)
    v.m.colVal[v.col] = val
end

function getValue(v::Variable) 
    if v.m.colVal[v.col] == NaN
        warn("Variable $(getName(v))'s value not defined. Check that the model was properly solved.")
    end
    return v.m.colVal[v.col]
end

getValue(arr::Array{Variable}) = map(getValue, arr)

# Dual value (reduced cost) getter
function getDual(v::Variable) 
    if length(v.m.redCosts) < getNumVars(v.m)
        error("Variable bound duals (reduced costs) not available. Check that the model was properly solved and no integer variables are present.")
    end
    return v.m.redCosts[v.col]
end

Base.zero(v::Type{Variable}) = AffExpr(Variable[],Float64[],0.0)
Base.zero(v::Variable) = zero(typeof(v))

###############################################################################
# Generic affine expression class
# Holds a vector of tuples (Var, Coeff)
type GenericAffExpr{CoefType,VarType}
    vars::Array{VarType,1}
    coeffs::Array{CoefType,1}
    constant::CoefType
end

typealias AffExpr GenericAffExpr{Float64,Variable}
AffExpr() = AffExpr(Variable[],Float64[],0.0)
AffExpr(v::Real) = AffExpr(Variable[],Float64[],convert(Float64,v))
AffExpr(v::Variable) = AffExpr(concat(v),[1.0],0.0)

getindex(x::AffExpr,idx::Int) = (idx == 1 ? x : throw(BoundsError()))
getindex(x::AffExpr,idx::Int,idy::Int) = ((idx,idy) == (1,1) ? x : throw(BoundsError()))
isequal(x::AffExpr,y::AffExpr) = isequal(x.vars,y.vars) && isequal(x.coeffs,y.coeffs) && isequal(x.constant,y.constant)

Base.isempty(a::AffExpr) = (length(a.vars) == 0 && a.constant == 0.)
Base.convert(::Type{AffExpr}, v::Variable) = AffExpr(Variable[v], [1.0], 0.)
Base.convert(::Type{AffExpr}, v::Real) = AffExpr(Variable[], Float64[], v)
Base.zero(::Type{AffExpr}) = AffExpr(Variable[],Float64[],0.)
Base.zero(a::AffExpr) = zero(typeof(a))

copy(a::AffExpr) = AffExpr(copy(a.vars),copy(a.coeffs),copy(a.constant))

zero(::Type{AffExpr}) = AffExpr(Variable[],Float64[],0.)

function setObjective(m::Model, sense::Symbol, a::AffExpr)
    setObjectiveSense(m, sense)
    m.obj = QuadExpr()
    m.obj.aff = a
end

# Copy utility function, not exported
function Base.copy(a::AffExpr, new_model::Model)
    return AffExpr([Variable(new_model, v.col) for v in a.vars],
                                 a.coeffs[:], a.constant)
end

# More efficient ways to grow an affine expression
# Add a single term to an affine expression
function Base.push!{T,S}(aff::GenericAffExpr{T,S}, new_coeff::T, new_var::S)
    push!(aff.vars, new_var)
    push!(aff.coeffs, new_coeff)
end
# Add an affine expression to an existing affine expression
function Base.append!{T,S}(aff::GenericAffExpr{T,S}, other::GenericAffExpr{T,S})
    append!(aff.vars, other.vars)
    append!(aff.coeffs, other.coeffs)
    aff.constant += other.constant  # Not efficient if CoefType isn't immutable
end

function getValue(a::AffExpr)
    ret = a.constant
    for it in 1:length(a.vars)
        ret += a.coeffs[it] * getValue(a.vars[it])
    end
    return ret
end

getValue(arr::Array{AffExpr}) = map(getValue, arr)

###############################################################################
# QuadExpr class
# Holds a vector of tuples (Var, Var, Coeff), as well as an AffExpr
type GenericQuadExpr{CoefType,VarType}
    qvars1::Vector{VarType}
    qvars2::Vector{VarType}
    qcoeffs::Vector{CoefType}
    aff::GenericAffExpr{CoefType,VarType}
end
typealias QuadExpr GenericQuadExpr{Float64,Variable}

isequal(x::QuadExpr,y::QuadExpr) = isequal(x.vars1,y.vars1) && isequal(x.vars2,y.vars2) && isequal(x.qcoeffs,y.qcoeffs) && isequal(x.aff,y.aff)

QuadExpr() = QuadExpr(Variable[],Variable[],Float64[],AffExpr())

Base.isempty(q::QuadExpr) = (length(q.qvars1) == 0 && isempty(q.aff))

function setObjective(m::Model, sense::Symbol, q::QuadExpr)
    m.obj = q
    setObjectiveSense(m, sense)
end

# Copy utility function
function Base.copy(q::QuadExpr, new_model::Model)
    return QuadExpr([Variable(new_model, v.col) for v in q.qvars1],
                    [Variable(new_model, v.col) for v in q.qvars2],
                    q.qcoeffs[:], copy(q.aff, new_model))
end

Base.zero(::Type{QuadExpr}) = QuadExpr(Variable[],Variable[],Float64[],zero(AffExpr))
Base.zero(v::QuadExpr) = zero(typeof(v))

function getValue(a::QuadExpr)
    ret = getValue(a.aff)
    for it in 1:length(a.qvars1)
        ret += a.qcoeffs[it] * getValue(a.qvars1[it]) * getValue(a.qvars2[it])
    end
    return ret
end

getValue(arr::Array{QuadExpr}) = map(getValue, arr)

##########################################################################
# JuMPConstraint
# abstract base for constraint types
abstract JuMPConstraint

##########################################################################
# Generic constraint type with lower and upper bound
type GenericRangeConstraint{TermsType} <: JuMPConstraint
    terms::TermsType
    lb::Float64
    ub::Float64
end

if VERSION.major == 0 && VERSION.minor < 3
    GenericRangeConstraint(terms, lb::Number, ub::Number) =
        GenericRangeConstraint(terms,float(lb),float(ub))
end

function sense(c::GenericRangeConstraint) 
    if c.lb != -Inf
        if c.ub != Inf
            if c.ub == c.lb
                return :(==)
            else
                return :range
            end
        else
                return :>=
        end
    else
        @assert c.ub != Inf
        return :<=
    end
end

function rhs(c::GenericRangeConstraint)
    s = sense(c)
    @assert s != :range
    if s == :<=
        return c.ub
    else
        return c.lb
    end
end

##########################################################################
# LinearConstraint is an affine expression with lower bound (possibly
# -Inf) and upper bound (possibly Inf).
typealias LinearConstraint GenericRangeConstraint{AffExpr}

function addConstraint(m::Model, c::LinearConstraint)
    push!(m.linconstr,c)
    if m.internalModelLoaded 
        # TODO: we don't check for duplicates here
        try
            MathProgBase.addconstr!(m.internalModel,[v.col for v in c.terms.vars],c.terms.coeffs,c.lb,c.ub)
        catch
            Base.warn_once("Solver does not appear to support adding constraints to an existing model. Hot-start is disabled.")
            m.internalModelLoaded = false
        end
    end
    return ConstraintRef{LinearConstraint}(m,length(m.linconstr))
end

# Copy utility function, not exported
function Base.copy(c::LinearConstraint, new_model::Model)
    return LinearConstraint(copy(c.terms, new_model), c.lb, c.ub)
end

##########################################################################
# SOSConstraint class
# An SOS constraint.
type SOSConstraint <: JuMPConstraint
    terms::Vector{Variable}
    weights::Vector{Float64}
    sostype::Symbol
end

function constructSOS(coll::Vector{AffExpr})
    nvar = length(coll)
    vars = Array(Variable, nvar)
    weight = Array(Float64, nvar)
    for i in 1:length(coll)
        if (length(coll[i].vars) != 1) || (coll[i].constant != 0)
            error("Must specify collection in terms of single variables")
        end
        if coll[i].vars[1].m.colCat[coll[i].vars[1].col] == CONTINUOUS
            error("SOS constraints cannot handle continuous variables")
        end
        vars[i] = coll[i].vars[1]
        weight[i] = coll[i].coeffs[1]
    end
    return vars, weight
end

addSOS1(m::Model, coll) = addSOS1(m, convert(Vector{AffExpr}, coll))

function addSOS1(m::Model, coll::Vector{AffExpr})
    vars, weight = constructSOS(coll)
    push!(m.sosconstr, SOSConstraint(vars, weight, :SOS1))
    if m.internalModelLoaded
        try
            MathProgBase.addsos1!(m.internalModel, Int[v.col for v in vars], weight)
        catch
            Base.warn_once("Solver does not appear to support adding constraints to an existing model. Hot-start is disabled.")
            m.internalModelLoaded = false
        end
    end
    return ConstraintRef{SOSConstraint}(m,length(m.sosconstr))
end

addSOS2(m::Model, coll) = addSOS2(m, convert(Vector{AffExpr}, coll))

function addSOS2(m::Model, coll::Vector{AffExpr})
    vars, weight = constructSOS(coll)
    push!(m.sosconstr, SOSConstraint(vars, weight, :SOS2))
    if m.internalModelLoaded
        try
            MathProgBase.addsos2!(m.internalModel, Int[v.col for v in vars], weight)
        catch
            Base.warn_once("Solver does not appear to support adding constraints to an existing model. Hot-start is disabled.")
            m.internalModelLoaded = false
        end
    end
    return ConstraintRef{SOSConstraint}(m,length(m.sosconstr))
end

##########################################################################
# Generic constraint type for quadratic expressions
# Right-hand side is implicitly taken to be zero, constraint is stored in
# the included QuadExpr.
type GenericQuadConstraint{QuadType} <: JuMPConstraint
    terms::QuadType
    sense::Symbol
end

##########################################################################
# QuadConstraint class
typealias QuadConstraint GenericQuadConstraint{QuadExpr}

function addConstraint(m::Model, c::QuadConstraint)
    push!(m.quadconstr,c)
    if m.internalModelLoaded
        # we don't (yet) support hot-starting QCQP solutions
        Base.warn_once("JuMP does not yet support adding quadratic constraints to an existing model. Hot-start is disabled.")
        m.internalModelLoaded = false
    end
    return ConstraintRef{QuadConstraint}(m,length(m.quadconstr))
end

# Copy utility function
function Base.copy(c::QuadConstraint, new_model::Model)
    return QuadConstraint(copy(c.terms, new_model), c.sense)
end

##########################################################################
# ConstraintRef
# Reference to a constraint for retrieving solution info
immutable ConstraintRef{T<:JuMPConstraint}
    m::Model
    idx::Int
end

function getDual(c::ConstraintRef{LinearConstraint}) 
    if length(c.m.linconstrDuals) != getNumConstraints(c.m)
        error("Dual solution not available. Check that the model was properly solved and no integer variables are present.")
    end
    return c.m.linconstrDuals[c.idx]
end

function chgConstrRHS(c::ConstraintRef{LinearConstraint}, rhs::Number)
    constr = c.m.linconstr[c.idx]
    sen = sense(constr)
    if sen == :range
        error("Modifying range constraints is currently unsupported.")
    elseif sen == :(==)
        constr.lb = float(rhs)
        constr.ub = float(rhs)
    elseif sen == :>=
        constr.lb = float(rhs)
    else
        @assert sen == :<=
        constr.ub = float(rhs)
    end
end

# add variable to existing constraints
function Variable(m::Model,lower::Number,upper::Number,cat::Int,objcoef::Number,
    constraints::Vector{ConstraintRef{LinearConstraint}},coefficients::Vector{Float64};
    name::String="")
        
    v = Variable(m, lower, upper, cat, name)
    # add to existing constraints
    @assert length(constraints) == length(coefficients)
    for i in 1:length(constraints)
        c::LinearConstraint = m.linconstr[constraints[i].idx]
        coef = coefficients[i]
        push!(c.terms.vars,v)
        push!(c.terms.coeffs,coef)
    end
    push!(m.obj.aff.vars, v)
    push!(m.obj.aff.coeffs,objcoef)

    if m.internalModelLoaded
        try
            MathProgBase.addvar!(m.internalModel,Int[c.idx for c in constraints],coefficients,float(lower),float(upper),float(objcoef))
        catch
            Base.warn_once("Solver does not appear to support adding variables to an existing model. Hot-start is disabled.")
            m.internalModelLoaded = false
        end
    end

    return v
end

##########################################################################
# Operator overloads
include("operators.jl")
# Writers - we support MPS (MILP + QuadObj), LP (MILP)
include("writers.jl")
# Solvers
include("solvers.jl")
# Macros - @defVar, sum{}, etc.
include("macros.jl")
# Callbacks - lazy, cuts, ...
include("callbacks.jl")
# Pretty-printing, including IJulia
include("print.jl")
# Nonlinear-specific code
include("nlp.jl")
# SDP-specific (type) code
include("sdp.jl")
# SDP-specific operators
include("sdp_operators.jl")
# SDP-specific solve code
include("sdp_solve.jl")
# concatenation helpers, mostly
include("sdp_utils.jl")

##########################################################################
end
