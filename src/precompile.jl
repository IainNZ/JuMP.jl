#  Copyright 2017, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

Base.precompile(addtoexpr_reorder, (Array{AffExpr,1},Float64,Array{Float64,1}))
Base.precompile(addtoexpr_reorder, (Array{AffExpr,1},Float64,Array{Int,1}))
Base.precompile(addtoexpr_reorder, (Array{AffExpr,1},Float64,Int))
Base.precompile(addtoexpr_reorder, (Array{AffExpr,2},Float64,Array{Float64,2}))
Base.precompile(addtoexpr_reorder, (Array{AffExpr,2},Float64,Int))
Base.precompile(addtoexpr_reorder, (Array{QuadExpr,1},Array{Variable,1}))
Base.precompile(addtoexpr_reorder, (Array{QuadExpr,1},Float64,Array{Int,1}))
Base.precompile(addtoexpr_reorder, (Array{QuadExpr,1},Float64,Int))
Base.precompile(addtoexpr_reorder, (Float64,Array{Float64,2}))
Base.precompile(addtoexpr_reorder, (Float64,Array{Int,1}))
Base.precompile(addtoexpr_reorder, (Float64,Array{Int,2}))
Base.precompile(addtoexpr_reorder, (Float64,Array{Variable,1}))
Base.precompile(addtoexpr_reorder, (Float64,Array{Variable,2}))
Base.precompile(addtoexpr_reorder, (Float64,Float64))
Base.precompile(addtoexpr_reorder, (Float64,Float64,Array{Int,1}))
Base.precompile(addtoexpr_reorder, (Float64,Float64,Int))
Base.precompile(addtoexpr_reorder, (Float64,Float64,AffExpr))
Base.precompile(addtoexpr_reorder, (Float64,Float64,SOCExpr))
Base.precompile(addtoexpr_reorder, (Float64,Float64,Norm{2}))
Base.precompile(addtoexpr_reorder, (Float64,Float64,QuadExpr))
Base.precompile(addtoexpr_reorder, (Float64,Float64,Variable))
Base.precompile(addtoexpr_reorder, (Float64,Int))
Base.precompile(addtoexpr_reorder, (Float64,Int,Variable))
Base.precompile(addtoexpr_reorder, (Float64,AffExpr))
Base.precompile(addtoexpr_reorder, (Float64,AffExpr,Float64))
Base.precompile(addtoexpr_reorder, (Float64,AffExpr,AffExpr))
Base.precompile(addtoexpr_reorder, (Float64,SOCExpr))
Base.precompile(addtoexpr_reorder, (Float64,Norm{2}))
Base.precompile(addtoexpr_reorder, (Float64,QuadExpr))
Base.precompile(addtoexpr_reorder, (Float64,Variable))
Base.precompile(addtoexpr_reorder, (Float64,Variable,Float64))
Base.precompile(addtoexpr_reorder, (Float64,Variable,Variable))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Array{AffExpr,2},Array{Float64,2},Array{AffExpr,1}}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Array{AffExpr,2},Array{Int,2},Array{AffExpr,1}}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Int,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Int,Int,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Float64,Float64}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Float64,Float64,Int}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Float64,Float64,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Float64,Int}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Float64,Int,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Float64,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Int,Norm{2}}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Int,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Int,Variable,Float64}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Variable,Float64}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Variable,Int}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Float64,Variable,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Tuple{Int,Variable,Variable}))
Base.precompile(addtoexpr_reorder, (AffExpr,Array{Float64,1},Variable))
Base.precompile(addtoexpr_reorder, (AffExpr,Array{Float64,2},Array{AffExpr,1}))
Base.precompile(addtoexpr_reorder, (AffExpr,Array{Int,2},Array{Variable,1}))
Base.precompile(addtoexpr_reorder, (AffExpr,Array{AffExpr,2}))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,Array{Float64,2}))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,Float64))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,Int))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,AffExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,SOCExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,Norm{2}))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,QuadExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Float64,Variable))
Base.precompile(addtoexpr_reorder, (AffExpr,Int))
Base.precompile(addtoexpr_reorder, (AffExpr,Int,AffExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Int,Norm{2}))
Base.precompile(addtoexpr_reorder, (AffExpr,Int,QuadExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Int,Variable))
Base.precompile(addtoexpr_reorder, (AffExpr,AffExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,AffExpr,AffExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,AffExpr,SOCExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Norm{2}))
Base.precompile(addtoexpr_reorder, (AffExpr,QuadExpr))
Base.precompile(addtoexpr_reorder, (AffExpr,Variable))
Base.precompile(addtoexpr_reorder, (AffExpr,Variable,Array{Float64,2}))
Base.precompile(addtoexpr_reorder, (AffExpr,Variable,Float64))
Base.precompile(addtoexpr_reorder, (AffExpr,Variable,Int))
Base.precompile(addtoexpr_reorder, (AffExpr,Variable,Variable))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,Float64))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,Int))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,AffExpr))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,SOCExpr))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,Norm{2}))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,QuadExpr))
Base.precompile(addtoexpr_reorder, (SOCExpr,Float64,Variable))
Base.precompile(addtoexpr_reorder, (SOCExpr,Variable))
Base.precompile(addtoexpr_reorder, (QuadExpr,Tuple{Float64,Int,Variable}))
Base.precompile(addtoexpr_reorder, (QuadExpr,Tuple{Float64,Int,Variable,Int,Variable}))
Base.precompile(addtoexpr_reorder, (QuadExpr,Tuple{Float64,Int,Variable,Variable}))
Base.precompile(addtoexpr_reorder, (QuadExpr,Tuple{Float64,Variable,Variable}))
Base.precompile(addtoexpr_reorder, (QuadExpr,Tuple{Int,Variable,Variable}))
Base.precompile(addtoexpr_reorder, (QuadExpr,Float64,Int))
Base.precompile(addtoexpr_reorder, (QuadExpr,Float64,AffExpr))
Base.precompile(addtoexpr_reorder, (QuadExpr,Float64,SOCExpr))
Base.precompile(addtoexpr_reorder, (QuadExpr,Float64,Norm{2}))
Base.precompile(addtoexpr_reorder, (QuadExpr,Float64,QuadExpr))
Base.precompile(addtoexpr_reorder, (QuadExpr,Float64,Variable))
Base.precompile(addtoexpr_reorder, (QuadExpr,Int))
Base.precompile(addtoexpr_reorder, (QuadExpr,Int,QuadExpr))
Base.precompile(addtoexpr_reorder, (QuadExpr,Int,Variable))
Base.precompile(addtoexpr_reorder, (QuadExpr,AffExpr,Float64))
Base.precompile(addtoexpr_reorder, (QuadExpr,AffExpr,AffExpr))
Base.precompile(addtoexpr_reorder, (QuadExpr,QuadExpr))
Base.precompile(addtoexpr_reorder, (QuadExpr,QuadExpr,Int))
Base.precompile(addtoexpr_reorder, (QuadExpr,Variable))
Base.precompile(addtoexpr_reorder, (QuadExpr,Variable,Variable))
Base.precompile(parseCurly, (Expr,Symbol,Vector{Any},Vector{Any},Symbol))
Base.precompile(parseExpr, (Expr,Symbol,Vector{Any},Vector{Any},Symbol))
Base.precompile(parseExpr, (Float64,Symbol,Vector{Any},Vector{Any},Symbol))
Base.precompile(parseExpr, (Int,Symbol,Vector{Any},Vector{Any},Symbol))
Base.precompile(parseExpr, (Symbol,Symbol,Vector{Any},Vector{Any},Symbol))
Base.precompile(parseSum, (Expr,Symbol,Vector{Any},Vector{Any},Symbol))

# Autogenerated via SnoopCompile. May contain duplicate entries.
precompile(JuMP.conicconstraintdata, (JuMP.Model,))
precompile(JuMP.parseExpr, (Expr, Symbol, Array{Any, 1}, Array{Any, 1}, Symbol,))
precompile(JuMP.parseNLExpr, (Expr, Symbol, Symbol, Int64, Symbol,))
precompile(JuMP.parseNLExpr, (Expr, Symbol, Symbol, Symbol, Symbol,))
precompile(JuMP.parseNLExpr, (Expr, Symbol, Int64, Int64, Symbol,))
precompile(JuMP.addQuadratics, (JuMP.Model,))
precompile(JuMP.tapeToExpr, (Int64, Array{ReverseDiffSparse.NodeData, 1}, Base.SparseMatrix.SparseMatrixCSC{Bool, Int64}, Array{Float64, 1}, Array{Float64, 1}, Array{Any, 1},))
precompile(JuMP.setindex!, (JuMP.JuMPArray{JuMP.Variable, 4, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, JuMP.Variable, Int64, Int64, Int64, Int64,))
precompile(JuMP.parseSum, (Expr, Symbol, Array{Any, 1}, Array{Any, 1}, Symbol,))
precompile(JuMP.call, (Type{JuMP.JuMPArray}, Array{JuMP.Variable, 4}, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}},))
precompile(JuMP.getindex, (JuMP.JuMPArray{JuMP.Variable, 4, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, Int64, Int64, Int64, Int64,))
precompile(JuMP.call, (Type{JuMP.JuMPArray}, Array{JuMP.Variable, 3}, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}},))
precompile(JuMP.call, (Type{JuMP.JuMPArray}, Array{JuMP.Variable, 2}, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}},))
precompile(JuMP.addConstraint, (JuMP.Model, JuMP.GenericQuadConstraint{JuMP.GenericQuadExpr{Float64, JuMP.Variable}},))
precompile(JuMP.setindex!, (JuMP.JuMPArray{JuMP.Variable, 3, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, JuMP.Variable, Int64, Int64, Int64,))
precompile(JuMP.isquadsoc, (JuMP.Model,))
precompile(JuMP.getindex, (JuMP.JuMPArray{JuMP.Variable, 3, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, Int64, Int64, Int64,))
precompile(JuMP.buildrefsets, (Expr,))
precompile(JuMP.hessian_slice, (JuMP.JuMPNLPEvaluator, JuMP.FunctionStorage, Array{Float64, 1}, Array{Float64, 1}, Float64, Int64, Array{Float64, 1}, Type{Base.Val{1}},))
precompile(JuMP._hesslag_structure, (JuMP.JuMPNLPEvaluator,))
precompile(JuMP.call, (Type{JuMP.Variable}, JuMP.Model, Int64, Int64, Symbol, UTF8String, Float64,))
precompile(JuMP.parseExpr, (Symbol, Symbol, Array{Any, 1}, Array{Any, 1}, Symbol,))
precompile(JuMP.setindex!, (JuMP.JuMPArray{JuMP.Variable, 2, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, JuMP.Variable, Int64, Int64,))
precompile(JuMP.call, (Type{JuMP.Variable}, JuMP.Model, Float64, Float64, Symbol, UTF8String, Float64,))
precompile(JuMP.call, (Type{JuMP.Variable}, JuMP.Model, Int64, Float64, Symbol, UTF8String, Float64,))
precompile(JuMP.getindex, (JuMP.JuMPArray{JuMP.Variable, 2, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, Int64, Int64,))
precompile(JuMP.getConstraintBounds, (JuMP.Model, JuMP.ProblemTraits,))
precompile(JuMP.hessian_slice_inner, (JuMP.JuMPNLPEvaluator, JuMP.FunctionStorage, Array{Float64, 2}, JuMP.VectorView{ForwardDiff.Partials{Float64, Tuple{Float64}}}, JuMP.VectorView{ForwardDiff.Partials{Float64, Tuple{Float64}}}, Type{Base.Val{1}},))
precompile(JuMP.fillConicRedCosts, (JuMP.Model,))
precompile(JuMP.setObjective, (JuMP.Model, Symbol, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.hasdependentsets, (Array{Any, 1}, Array{Any, 1},))
precompile(JuMP.parseExpr, (Int64, Symbol, Array{Any, 1}, Array{Any, 1}, Symbol,))
precompile(JuMP.addSOS, (JuMP.Model,))
precompile(JuMP.call, (Array{Any, 1}, Type{JuMP.Model},))
precompile(JuMP.collect_expr!, (JuMP.Model, JuMP.IndexedVector{Float64}, JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.merge_duplicates, (Type{Int32}, JuMP.GenericAffExpr{Float64, JuMP.Variable}, JuMP.IndexedVector{Float64}, JuMP.Model,))
precompile(JuMP.call, (Type{JuMP.JuMPNLPEvaluator}, JuMP.Model,))
precompile(JuMP.prepConstrMatrix, (JuMP.Model,))
precompile(JuMP._buildInternalModel_nlp, (JuMP.Model, JuMP.ProblemTraits,))
precompile(JuMP.getNumBndRows, (JuMP.Model,))
precompile(JuMP.buildInternalModel, (Array{Any, 1}, JuMP.Model, JuMP.ProblemTraits,))
precompile(JuMP.call, (Vararg{Any},))
precompile(JuMP.parseNLExpr, (Float64, Symbol, Symbol, Int64, Symbol,))
precompile(JuMP.parseNLExpr, (Symbol, Symbol, Symbol, Int64, Symbol,))
precompile(JuMP.call, (Type{JuMP.FunctionStorage}, Array{ReverseDiffSparse.NodeData, 1}, Base.SparseMatrix.SparseMatrixCSC{Bool, Int64}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Int64, 1}, Array{Int64, 1}, Array{Int64, 1}, ReverseDiffSparse.Coloring.RecoveryInfo, Array{Float64, 2}, ReverseDiffSparse.Linearity, Array{Int64, 1},))
precompile(JuMP.parseNLExpr, (Int64, Symbol, Symbol, Int64, Symbol,))
precompile(JuMP.addToExpression_reorder, (Vararg{Any},))
precompile(JuMP._localvar, (Expr,))
precompile(JuMP.registercallbacks, (JuMP.Model,))
precompile(JuMP.call, (Type{JuMP.FunctionStorage}, Array{ReverseDiffSparse.NodeData, 1}, Array{Float64, 1}, Int64, Bool, Array{Array{ReverseDiffSparse.NodeData, 1}, 1}, Array{Int64, 1}, Array{ReverseDiffSparse.Linearity, 1}, Array{Base.Set{Tuple{Int64, Int64}}, 1}, Array{Base.Set{Int64}, 1}, Base.BitArray{1},))
precompile(JuMP.forward_eval_all, (JuMP.JuMPNLPEvaluator, Array{Float64, 1},))
precompile(JuMP.prepProblemBounds, (JuMP.Model,))
precompile(JuMP.vartypes_without_fixed, (JuMP.Model,))
precompile(JuMP.solvenlp, (Array{Any, 1}, JuMP.Model, JuMP.ProblemTraits,))
precompile(JuMP.reverse_eval_all, (JuMP.JuMPNLPEvaluator, Array{Float64, 1},))
precompile(JuMP.addToExpression, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Int64, JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.addConstraint, (JuMP.Model, JuMP.GenericRangeConstraint{JuMP.GenericAffExpr{Float64, JuMP.Variable}},))
precompile(JuMP.addToExpression, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Float64, JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.assert_isfinite, (JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.empty!, (JuMP.IndexedVector{Float64},))
precompile(JuMP.addelt!, (JuMP.IndexedVector{Float64}, Int64, Float64,))
precompile(JuMP.parseIdxSet, (Expr,))
precompile(JuMP.assert_isfinite, (JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.isdependent, (Array{Any, 1}, Expr, Int64,))
precompile(JuMP.call, (Type{JuMP.SubexpressionStorage}, Array{ReverseDiffSparse.NodeData, 1}, Base.SparseMatrix.SparseMatrixCSC{Bool, Int64}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1}, ReverseDiffSparse.Linearity,))
precompile(JuMP.convert, (Type{JuMP.GenericQuadExpr{Float64, JuMP.Variable}}, Float64,))
precompile(JuMP.addToExpression, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, Float64, JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.call, (Type{JuMP.ProblemTraits}, JuMP.Model,))
precompile(JuMP.addToExpression, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Int64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.verify_ownership, (JuMP.Model, Array{JuMP.Variable, 1},))
precompile(JuMP.addToExpression, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Float64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.fillConicDuals, (JuMP.Model,))
precompile(JuMP.default_solver, (JuMP.ProblemTraits,))
precompile(JuMP.buildrefsets, (Void,))
precompile(JuMP.tryParseIdxSet, (Expr,))
precompile(JuMP.setLower, (JuMP.Variable, Float64,))
precompile(JuMP.setObjectiveSense, (JuMP.Model, Symbol,))
precompile(JuMP.operator_warn, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.getNumSOCRows, (JuMP.Model,))
precompile(JuMP.storecontainerdata, (JuMP.Model, Array{JuMP.Variable, 2}, Symbol, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}}, Array{JuMP.IndexPair, 1}, Expr,))
precompile(JuMP.constructconstraint!, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, Symbol,))
precompile(JuMP.storecontainerdata, (JuMP.Model, JuMP.JuMPArray{JuMP.Variable, 4, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, Symbol, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}, Array{JuMP.IndexPair, 1}, Expr,))
precompile(JuMP.zero, (Type{JuMP.GenericQuadExpr{Float64, JuMP.Variable}},))
precompile(JuMP.storecontainerdata, (JuMP.Model, JuMP.JuMPArray{JuMP.Variable, 2, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, Symbol, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}}, Array{JuMP.IndexPair, 1}, Expr,))
precompile(JuMP.storecontainerdata, (JuMP.Model, JuMP.JuMPArray{JuMP.Variable, 3, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}}, Symbol, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}, Array{JuMP.IndexPair, 1}, Expr,))
precompile(JuMP.storecontainerdata, (JuMP.Model, Array{JuMP.Variable, 1}, Symbol, Tuple{Base.UnitRange{Int64}}, Array{JuMP.IndexPair, 1}, Expr,))
precompile(JuMP.scale!, (JuMP.VectorView{Float64}, Float64,))
precompile(JuMP.setindex!, (Vararg{Any},))
precompile(JuMP._canonicalize_sense, (Symbol,))
precompile(JuMP.addToExpression, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, Float64, JuMP.Variable,))
precompile(JuMP.addToExpression_reorder, (Vararg{Any},))
precompile(JuMP.getindex, (Vararg{Any},))
precompile(JuMP.parseCurly, (Expr, Symbol, Array{Any, 1}, Array{Any, 1}, Symbol,))
precompile(JuMP.initNLP, (JuMP.Model,))
precompile(JuMP.setUpper, (JuMP.Variable, Float64,))
precompile(JuMP.setindex!, (JuMP.VectorView{ForwardDiff.Partials{Float64, Tuple{Float64}}}, ForwardDiff.Partials{Float64, Tuple{Float64}}, Array{Int64, 1},))
precompile(JuMP.parseNLExpr_runtime, (JuMP.Variable, Array{ReverseDiffSparse.NodeData, 1}, Int64, Int64, Array{Float64, 1},))
precompile(JuMP.copy, (JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP._sizehint_expr!, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, Int64,))
precompile(JuMP.simplify_expression, (Array{ReverseDiffSparse.NodeData, 1}, Array{Float64, 1}, Array{ReverseDiffSparse.Linearity, 1}, Base.BitArray{1}, Array{Float64, 1}, Array{Float64, 1}, Array{Float64, 1},))
precompile(JuMP.parseNLExpr_runtime, (Float64, Array{ReverseDiffSparse.NodeData, 1}, Int64, Int64, Array{Float64, 1},))
precompile(JuMP.setObjective, (JuMP.Model, Symbol, JuMP.GenericAffExpr{Float64, JuMP.Variable},))
precompile(JuMP.addToExpression, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, Float64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.call, (Type{JuMP.SubexpressionStorage}, Array{ReverseDiffSparse.NodeData, 1}, Array{Float64, 1}, Int64, Base.BitArray{1}, Array{ReverseDiffSparse.Linearity, 1},))
precompile(JuMP.call, (Type{JuMP.ProblemTraits}, Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool, Bool,))
precompile(JuMP.addToExpression_reorder, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Float64, Float64, Float64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.addToExpression, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, Int64, JuMP.Variable,))
precompile(JuMP.resize!, (JuMP.IndexedVector{Float64}, Int64,))
precompile(JuMP.reinterpret_unsafe, (Type{ForwardDiff.Partials{Float64, Tuple{Float64}}}, Array{Float64, 1},))
precompile(JuMP.assert_validmodel, (Expr, Expr,))
precompile(JuMP._sizehint_expr!, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Int64,))
precompile(JuMP.addToExpression, (Float64, Int64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.parseExprToplevel, (Expr, Symbol,))
precompile(JuMP.parseNLExpr_runtime, (Int64, Array{ReverseDiffSparse.NodeData, 1}, Int64, Int64, Array{Float64, 1},))
precompile(JuMP.__init__, ())
precompile(JuMP.parseExprToplevel, (Symbol, Symbol,))
precompile(JuMP.dependson, (Expr, Symbol,))
precompile(JuMP.registervar, (JuMP.Model, Symbol, Array{JuMP.Variable, 2},))
precompile(JuMP.registervar, (JuMP.Model, Symbol, JuMP.JuMPArray{JuMP.Variable, 4, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}},))
precompile(JuMP.registervar, (JuMP.Model, Symbol, JuMP.JuMPArray{JuMP.Variable, 3, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}, Base.UnitRange{Int64}}},))
precompile(JuMP.registervar, (JuMP.Model, Symbol, JuMP.JuMPArray{JuMP.Variable, 2, Tuple{Base.UnitRange{Int64}, Base.UnitRange{Int64}}},))
precompile(JuMP.registervar, (JuMP.Model, Symbol, JuMP.Variable,))
precompile(JuMP.registervar, (JuMP.Model, Symbol, Array{JuMP.Variable, 1},))
precompile(JuMP.issum, (Symbol,))
precompile(JuMP.solve, (JuMP.Model,))
precompile(JuMP.getname, (Expr,))
precompile(JuMP.esc_nonconstant, (Expr,))
precompile(JuMP.dependson, (Int64, Symbol,))
precompile(JuMP.is_complex_expr, (Expr,))
precompile(JuMP.esc_nonconstant, (Symbol,))
precompile(JuMP.esc_nonconstant, (Float64,))
precompile(JuMP.validmodel, (JuMP.Model, Symbol,))
precompile(JuMP.getloopedcode, (Void, Expr, Expr, Array{Any, 1}, Array{Any, 1}, Array{JuMP.IndexPair, 1}, Expr,))
precompile(JuMP.addToExpression_reorder, (Vararg{Any},))
precompile(JuMP.is_complex_expr, (Int64,))
precompile(JuMP.addToExpression_reorder, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Float64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.is_complex_expr, (Float64,))
precompile(JuMP.is_complex_expr, (Symbol,))
precompile(JuMP.getloopedcode, (Void, Expr, Expr, Array{Any, 1}, Array{Any, 1}, Array{JuMP.IndexPair, 1}, Symbol,))
precompile(JuMP.constructconstraint!, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Symbol,))
precompile(JuMP.dependson, (Symbol, Symbol,))
precompile(JuMP.esc_nonconstant, (Int64,))
precompile(JuMP.addToExpression_reorder, (JuMP.GenericAffExpr{Float64, JuMP.Variable}, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.getloopedcode, (Expr, Expr, Expr, Array{Any, 1}, Array{Any, 1}, Array{JuMP.IndexPair, 1}, Symbol,))
precompile(JuMP.addToExpression_reorder, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.addToExpression_reorder, (JuMP.GenericQuadExpr{Float64, JuMP.Variable}, Int64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
precompile(JuMP.addToExpression_reorder, (Float64, Int64, JuMP.GenericQuadExpr{Float64, JuMP.Variable},))
