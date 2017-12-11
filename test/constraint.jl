

@testset "Constraints" begin
    @testset "AffExpr constraints" begin
        m = Model()
        @variable(m, x)

        cref = @constraint(m, 2x <= 10)
        c = JuMP.constraintobject(cref, AffExpr, MOI.LessThan)
        @test JuMP.isequal_canonical(c.func, 2x)
        @test c.set == MOI.LessThan(10.0)
        @test_throws TypeError JuMP.constraintobject(cref, QuadExpr, MOI.LessThan)
        @test_throws TypeError JuMP.constraintobject(cref, AffExpr, MOI.EqualTo)

        cref = @constraint(m, 3x + 1 ≥ 10)
        c = JuMP.constraintobject(cref, AffExpr, MOI.GreaterThan)
        @test JuMP.isequal_canonical(c.func, 3x)
        @test c.set == MOI.GreaterThan(9.0)

        cref = @constraint(m, 1 == -x)
        c = JuMP.constraintobject(cref, AffExpr, MOI.EqualTo)
        @test JuMP.isequal_canonical(c.func, 1.0x)
        @test c.set == MOI.EqualTo(-1.0)

        @test_throws ErrorException @constraint(m, [x, 2x] == [1-x, 3])
        cref = @constraint(m, [x, 2x] .== [1-x, 3])
        c = JuMP.constraintobject.(cref, AffExpr, MOI.EqualTo)
        @test JuMP.isequal_canonical(c[1].func, 2.0x)
        @test c[1].set == MOI.EqualTo(1.0)
        @test JuMP.isequal_canonical(c[2].func, 2.0x)
        @test c[2].set == MOI.EqualTo(3.0)
    end

    @testset "QuadExpr constraints" begin
        m = Model()
        @variable(m, x)
        @variable(m, y)

        cref = @constraint(m, x^2 + x <= 1)
        c = JuMP.constraintobject(cref, QuadExpr, MOI.LessThan)
        @test JuMP.isequal_canonical(c.func, x^2 + x)
        @test c.set == MOI.LessThan(1.0)

        cref = @constraint(m, y*x - 1.0 == 0.0)
        c = JuMP.constraintobject(cref, QuadExpr, MOI.EqualTo)
        @test JuMP.isequal_canonical(c.func, x*y)
        @test c.set == MOI.EqualTo(1.0)
        @test_throws TypeError JuMP.constraintobject(cref, QuadExpr, MOI.LessThan)
        @test_throws TypeError JuMP.constraintobject(cref, AffExpr, MOI.EqualTo)

        # cref = @constraint(m, [x^2 - 1] in MOI.SecondOrderCone(1))
        # c = JuMP.constraintobject(cref, QuadExpr, MOI.SecondOrderCone)
        # @test JuMP.isequal_canonical(c.func, -1 + x^2)
        # @test c.set == MOI.SecondOrderCone(1)
    end

    @testset "SDP constraint" begin
        m = Model()
        @variable(m, x)
        @variable(m, y)

        cref = @SDconstraint(m, [x 1; 1 -y] ⪰ [1 x; x -2])
        c = JuMP.constraintobject(cref, Vector{AffExpr}, MOI.PositiveSemidefiniteConeTriangle)
        @test JuMP.isequal_canonical(c.func[1], x-1)
        @test JuMP.isequal_canonical(c.func[2], 1-x)
        @test JuMP.isequal_canonical(c.func[3], 2-y)
        @test c.set == MOI.PositiveSemidefiniteConeTriangle(2)
    end

    @testset "Nonsensical SDPs" begin
        m = Model()
        @test_throws ErrorException @variable(m, unequal[1:5,1:6], PSD)
        # Some of these errors happen at compile time, so we can't use @test_throws
        @test macroexpand(:(@variable(m, notone[1:5,2:6], PSD))).head == :error
        @test macroexpand(:(@variable(m, oneD[1:5], PSD))).head == :error
        @test macroexpand(:(@variable(m, threeD[1:5,1:5,1:5], PSD))).head == :error
        @test macroexpand(:(@variable(m, psd[2] <= rand(2,2), PSD))).head == :error
        @test macroexpand(:(@variable(m, -ones(3,4) <= foo[1:4,1:4] <= ones(4,4), PSD))).head == :error
        @test macroexpand(:(@variable(m, -ones(3,4) <= foo[1:4,1:4] <= ones(4,4), Symmetric))).head == :error
        @test macroexpand(:(@variable(m, -ones(4,4) <= foo[1:4,1:4] <= ones(4,5), Symmetric))).head == :error
        @test macroexpand(:(@variable(m, -rand(5,5) <= nonsymmetric[1:5,1:5] <= rand(5,5), Symmetric))).head == :error
    end

end
