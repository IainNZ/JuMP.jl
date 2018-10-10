# Used in @constraint model x in PSDCone
struct PSDCone end

"""
    SymmetricMatrixShape

Shape object for a symmetric square matrix of `side_dimension` rows and columns.
The vectorized form contains the entries of the upper-right triangular part of
the matrix given column by column (or equivalently, the entries of the
lower-left triangular part given row by row).
"""
struct SymmetricMatrixShape <: AbstractShape
    side_dimension::Int
end
function reshape(vectorized_form::Vector{T}, shape::SymmetricMatrixShape) where T
    matrix = Matrix{T}(undef, shape.side_dimension, shape.side_dimension)
    k = 0
    for j in 1:shape.side_dimension
        for i in 1:j
            k += 1
            matrix[j, i] = matrix[i, j] = vectorized_form[k]
        end
    end
    return Symmetric(matrix)
end

"""
    SquareMatrixShape

Shape object for a square matrix of `side_dimension` rows and columns. The
vectorized form contains the entries of the the matrix given column by column
(or equivalently, the entries of the lower-left triangular part given row by
row).
"""
struct SquareMatrixShape <: AbstractShape
    side_dimension::Int
end
function reshape(vectorized_form::Vector{T}, shape::SquareMatrixShape) where T
    return Base.reshape(vectorized_form,
                        shape.side_dimension,
                        shape.side_dimension)
end

"""
    function build_constraint(_error::Function, Q::Symmetric{V, M},
                              ::PSDCone) where {V <: AbstractJuMPScalar,
                                                M <: AbstractMatrix{V}}

Return a `VectorConstraint` of shape [`SymmetricMatrixShape`](@ref) constraining
the matrix `Q` to be positive semidefinite.

This function is used by the [`@variable`](@ref) macro to create a symmetric
semidefinite matrix of variables and by the [`@constraint`](@ref) macros as
follows:
```julia
@constraint(model, Symmetric(Q) in PSDCone())
```
The form above is usually used when the entries of `Q` are affine or quadratic
expressions but it can also be used when the entries are variables to get the
reference of the semidefinite constraint, e.g.,
```julia
@variable model Q[1:2,1:2] Symmetric
# The type of `Q` is `Symmetric{VariableRef, Matrix{VariableRef}}`
var_psd = @constraint model Q in PSDCone()
# The `var_psd` variable contains a reference to the constraint
```
"""
function build_constraint(_error::Function, Q::Symmetric{V, M},
                          ::PSDCone) where {V <: AbstractJuMPScalar,
                                            M <: AbstractMatrix{V}}
    n = Compat.LinearAlgebra.checksquare(Q)
    VectorConstraint([Q[i, j] for j in 1:n for i in 1:j],
                     MOI.PositiveSemidefiniteConeTriangle(n),
                     SymmetricMatrixShape(n))
end

"""
    function build_constraint(_error::Function,
                              Q::AbstractMatrix{<:AbstractJuMPScalar},
                              ::PSDCone)

Return a `VectorConstraint` of shape [`SquareMatrixShape`](@ref) constraining
the matrix `Q` to be symmetric and positive semidefinite.

This function is used by the [`@constraint`](@ref) and [`@SDconstraint`](@ref)
macros as follows:
```julia
@constraint(model, Q in PSDCone())
@SDconstraint(model, P ⪰ Q)
```
The [`@constraint`](@ref) call above is usually used when the entries of `Q` are
affine or quadratic expressions but it can also be used when the entries are
variables to get the reference of the semidefinite constraint, e.g.,
```julia
@variable model Q[1:2,1:2]
# The type of `Q` is `Matrix{VariableRef}`
var_psd = @constraint model Q in PSDCone()
# The `var_psd` variable contains a reference to the constraint
```
"""
function build_constraint(_error::Function,
                          Q::AbstractMatrix{<:AbstractJuMPScalar},
                          ::PSDCone)
    n = Compat.LinearAlgebra.checksquare(Q)
    VectorConstraint(vec(Q),
                     MOI.PositiveSemidefiniteConeSquare(n),
                     SquareMatrixShape(n))
end
