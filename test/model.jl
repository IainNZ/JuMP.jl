@testset "optimizehook" begin
    m = Model()
    @test m.optimizehook === nothing
    called = false
    function hook(m)
        called = true
    end
    JuMP.setoptimizehook(m, hook)
    @test !called
    optimize(m)
    @test called
end
@testset "UniversalFallback" begin
    m = Model()
    MOI.set!(m, MOIT.UnknownModelAttribute(), 1)
    @test MOI.get(m, MOIT.UnknownModelAttribute()) == 1
end
# Simple LP model not supporting Interval
@MOIU.model LPModel () (EqualTo, GreaterThan, LessThan) () () (SingleVariable,) (ScalarAffineFunction,) () ()
@testset "Bridges" begin
    @testset "Automatic bridging" begin
        # optimizer not supporting Interval
        model = Model(with_optimizer(MOIU.MockOptimizer, LPModel{Float64}()))
        @variable model x
        cref = @constraint model 0 <= x + 1 <= 1
        @test cref isa JuMP.ConstraintRef{JuMP.Model,MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64},MOI.Interval{Float64}}}
        JuMP.optimize(model)
    end
    @testset "Automatic bridging disabled with `bridge_constraints` keyword" begin
        model = Model(with_optimizer(MOIU.MockOptimizer, LPModel{Float64}()), bridge_constraints=false)
        @test model.moibackend isa MOIU.CachingOptimizer
        @test model.moibackend === JuMP.caching_optimizer(model)
        @variable model x
        @constraint model 0 <= x + 1 <= 1
        @test_throws ErrorException JuMP.optimize(model)
    end
    @testset "No bridge automatically added in Direct mode" begin
        optimizer = MOIU.MockOptimizer(LPModel{Float64}())
        model = JuMP.direct_model(optimizer)
        @variable model x
        @test_throws MethodError @constraint model 0 <= x + 1 <= 1
    end
end
