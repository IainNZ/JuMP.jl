#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

# JuMPArray is inspired by the AxisArrays package.
# JuMPArray can be replaced with AxisArray once integer indices are no longer
# a special case. See discussions at:
# https://github.com/JuliaArrays/AxisArrays.jl/issues/117
# https://github.com/JuliaArrays/AxisArrays.jl/issues/84


struct JuMPArray{T,N,Ax,L<:NTuple{N,Dict}} <: AbstractArray{T,N}
    data::Array{T,N}
    axes::Ax
    lookup::L
end

export JuMPArray

function build_lookup(ax)
    d = Dict{eltype(ax),Int}()
    cnt = 1
    for el in ax
        if haskey(d, el)
            error("Repeated index $el. Index sets must have unique elements.")
        end
        d[el] = cnt
        cnt += 1
    end
    d
end

function JuMPArray(data::Array{T,N}, axs...) where {T,N}
    @assert length(axs) == N
    return JuMPArray(data, axs, build_lookup.(axs))
end

lookup_index(i, lookup::Dict) = isa(i, Colon) ? Colon() : lookup[i]

# Lisp-y tuple recursion trick to handle indexing in a nice type-
# stable way. The idea here is that `_to_index_tuple(idx, lookup)`
# performs a lookup on the first element of `idx` and `lookup`,
# then recurses using the remaining elements of both tuples.
# The compiler knows the lengths and types of each tuple, so
# all of the types are inferable.
function _to_index_tuple(idx::Tuple, lookup::Tuple)
    tuple(lookup_index(first(idx), first(lookup)),
          _to_index_tuple(Base.tail(idx), Base.tail(lookup))...)
end

# Handle the base case when we have more indices than lookups:
function _to_index_tuple(idx::NTuple{N}, ::NTuple{0}) where {N}
    ntuple(k -> begin
        i = idx[k]
        (i == 1) ? 1 : error("invalid index $i")
    end, Val(N))
end

# Handle the base case when we have fewer indices than lookups:
_to_index_tuple(idx::NTuple{0}, lookup::Tuple) = ()

# Resolve ambiguity with the above two base cases
_to_index_tuple(idx::NTuple{0}, lookup::NTuple{0}) = ()

to_index(A::JuMPArray, idx...) = _to_index_tuple(idx, A.lookup)

# Doing `Colon() in idx` is relatively slow because it involves
# a non-unrolled loop through the `idx` tuple which may be of
# varying element type. Another lisp-y recursion trick fixes that
has_colon(idx::Tuple{}) = false
has_colon(idx::Tuple) = isa(first(idx), Colon) || has_colon(Base.tail(idx))

# TODO: better error (or just handle correctly) when user tries to index with a range like a:b
# The only kind of slicing we support is dropping a dimension with colons
function Base.getindex(A::JuMPArray, idx...)
    if has_colon(idx)
        JuMPArray(A.data[to_index(A,idx...)...], (ax for (i,ax) in enumerate(A.axes) if idx[i] == Colon())...)
    else
        return A.data[to_index(A,idx...)...]
    end
end
Base.getindex(A::JuMPArray, idx::CartesianIndex) = A.data[idx]

Base.setindex!(A::JuMPArray, v, idx...) = A.data[to_index(A,idx...)...] = v
Base.setindex!(A::JuMPArray, v, idx::CartesianIndex) = A.data[idx] = v

# AbstractArray interface

Base.linearindices(A::JuMPArray) = error("JuMPArray does not support this operation.")
# We don't define size because it causes 'end' to behave incorrectly. Better to error.
Base.size(A::JuMPArray) = error("JuMPArray does not define size().")
if VERSION < v"0.7-"
    Base.indices(A::JuMPArray) = A.axes
else
    Base.axes(A::JuMPArray) = A.axes
end

# Arbitrary typed indices. Linear indexing not supported.
struct IndexAnyCartesian <: Base.IndexStyle end
Base.IndexStyle(::Type{JuMPArray{T,N,Ax}}) where {T,N,Ax} = IndexAnyCartesian()

@static if VERSION < v"0.7-"
    Base.broadcast(f::Function, A::JuMPArray) = JuMPArray(broadcast(f, A.data), A.axes, A.lookup)
else
    # This implementation follows the instructions at
    # https://docs.julialang.org/en/latest/manual/interfaces/#man-interfaces-broadcasting-1
    # for implementing broadcast. We eagerly evaluate expressions involving
    # JuMPArrays, overriding operation fusion.  For now, nested (fused)
    # broadcasts like f.(A .+ 1) don't work, and we don't support broadcasts
    # where multiple JuMPArrays appear. This is a stopgap solution to get tests
    # passing on Julia 0.7 and leaves lots of room for improvement.
    struct JuMPArrayBroadcastStyle <: Broadcast.BroadcastStyle end
    Base.BroadcastStyle(::Type{<:JuMPArray}) = JuMPArrayBroadcastStyle()
    function Base.Broadcast.broadcasted(::JuMPArrayBroadcastStyle, f, args...)
        array = find_jump_array(args)
        if sum(arg isa JuMPArray for arg in args) > 1
            error("Broadcast operations with multiple JuMPArrays are not yet " *
                  "supported.")
        end
        result_data = broadcast(f, unpack_jump_array(args)...)
        return JuMPArray(result_data, array.axes, array.lookup)
    end
    function find_jump_array(args::Tuple)
        return find_jump_array(args[1], Base.tail(args))
    end
    find_jump_array(array::JuMPArray, rest) = array
    find_jump_array(::Any, rest) = find_jump_array(rest)
    function find_jump_array(broadcasted::Broadcast.Broadcasted)
        error("Unsupported nested broadcast operation. JuMPArray supports " *
              "only simple broadcast operations like f.(A) but not f.(A .+ 1).")
    end

    function unpack_jump_array(args::Tuple)
        return unpack_jump_array(args[1], Base.tail(args))
    end
    unpack_jump_array(args::Tuple{}) = ()
    function unpack_jump_array(array::JuMPArray, rest)
        return (array.data, unpack_jump_array(rest)...)
    end
    unpack_jump_array(other::Any, rest) = (other, unpack_jump_array(rest)...)
end

Base.isempty(A::JuMPArray) = isempty(A.data)

Base.isassigned(A::JuMPArray{T,N}, idx...) where {T,N} = length(idx) == N && all(t -> haskey(A.lookup[t[1]], t[2]), enumerate(idx))
# For ambiguity
Base.isassigned(A::JuMPArray{T,N}, idx::Int...) where {T,N} = length(idx) == N && all(t -> haskey(A.lookup[t[1]], t[2]), enumerate(idx))

Base.eachindex(A::JuMPArray) = CartesianIndices(size(A.data))

# TODO: similar

# Adapted printing from Julia's show.jl

# Copyright (c) 2009-2016: Jeff Bezanson, Stefan Karpinski, Viral B. Shah,
# and other contributors:
#
# https://github.com/JuliaLang/julia/contributors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

function Base.summary(io::IO, A::JuMPArray)
    _summary(io, A)
    for (k,ax) in enumerate(A.axes)
        print(io, "    Dimension $k, ")
        show(IOContext(io, :limit=>true), ax)
        println(io)
    end
    print(io, "And data, a ", summary(A.data))
end
_summary(io, A::JuMPArray{T,N}) where {T,N} = println(io, "$N-dimensional JuMPArray{$T,$N,...} with index sets:")

function Base.summary(A::JuMPArray)
    io = IOBuffer()
    Base.summary(io, A)
    String(io)
end

if isdefined(Base, :print_array) # 0.7 and later
    Base.print_array(io::IO, X::JuMPArray{T,1}) where {T} = Base.print_matrix(io, X.data)
    Base.print_array(io::IO, X::JuMPArray{T,2}) where {T} = Base.print_matrix(io, X.data)
end

# n-dimensional arrays
function Base.show_nd(io::IO, a::JuMPArray, print_matrix::Function, label_slices::Bool)
    limit::Bool = get(io, :limit, false)
    if isempty(a)
        return
    end
    tailinds = Base.tail(Base.tail(Compat.axes(a.data)))
    nd = ndims(a)-2
    for I in CartesianIndices(tailinds)
        idxs = I.I
        if limit
            for i = 1:nd
                ii = idxs[i]
                ind = tailinds[i]
                if length(ind) > 10
                    if ii == ind[4] && all(d->idxs[d]==first(tailinds[d]),1:i-1)
                        for j=i+1:nd
                            szj = size(a.data,j+2)
                            indj = tailinds[j]
                            if szj>10 && first(indj)+2 < idxs[j] <= last(indj)-3
                                @goto skip
                            end
                        end
                        #println(io, idxs)
                        print(io, "...\n\n")
                        @goto skip
                    end
                    if ind[3] < ii <= ind[end-3]
                        @goto skip
                    end
                end
            end
        end
        if label_slices
            print(io, "[:, :, ")
            for i = 1:(nd-1); show(io, a.axes[i+2][idxs[i]]); print(io,", "); end
            show(io, a.axes[end][idxs[end]])
            println(io, "] =")
        end
        slice = view(a.data, Compat.axes(a.data,1), Compat.axes(a.data,2),
                     idxs...)
        Base.print_matrix(io, slice)
        print(io, idxs == map(last,tailinds) ? "" : "\n\n")
        @label skip
    end
end

@static if VERSION >= v"0.7-"
    function Base.show(io::IO, array::JuMPArray)
        summary(io, array)
        isempty(array) && return
        println(io, ":")
        Base.print_array(io, array)
    end
else
    function Base.showarray(io::IO, X::JuMPArray, repr::Bool = true; header = true)
        repr = false
        #if repr && ndims(X) == 1
        #    return Base.show_vector(io, X, "[", "]")
        #end
        if !haskey(io, :compact)
            io = IOContext(io, :compact => true)
        end
        if !repr && get(io, :limit, false) && eltype(X) === Method
            # override usual show method for Vector{Method}: don't abbreviate long lists
            io = IOContext(io, :limit => false)
        end
        (!repr && header) && print(io, summary(X))
        if !isempty(X.data)
            (!repr && header) && println(io, ":")
            if ndims(X.data) == 0
                if isassigned(X.data)
                    return show(io, X.data[])
                else
                    return print(io, undef_ref_str)
                end
            end
            #if repr
            #    if ndims(X.data) <= 2
            #        Base.print_matrix_repr(io, X)
            #    else
            #        show_nd(io, X, print_matrix_repr, false)
            #    end
            #else
            punct = (" ", "  ", "")
            if ndims(X.data) <= 2
                Base.print_matrix(io, X.data, punct...)
            else
                Base.show_nd(io, X,
                        (io, slice) -> Base.print_matrix(io, slice, punct...),
                        !repr)
            end
            #end
        elseif repr
            Base.repremptyarray(io, X.data)
        end
    end
end
