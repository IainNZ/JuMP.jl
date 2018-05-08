using JuMP
using Compat
using Compat.Test

@testset "Operator" begin
    @testset "Basic operator overloads" begin
        m = Model()
        @variable(m, w)
        @variable(m, x)
        @variable(m, y)
        @variable(m, z)

        aff = @inferred 7.1 * x + 2.5
        @test_expression_with_string 7.1 * x + 2.5 "7.1 x + 2.5"
        aff2 = @inferred 1.2 * y + 1.2
        @test_expression_with_string 1.2 * y + 1.2 "1.2 y + 1.2"
        q = @inferred 2.5 * y * z + aff
        @test_expression_with_string 2.5 * y * z + aff "2.5 y*z + 7.1 x + 2.5"
        q2 = @inferred 8 * x * z + aff2
        @test_expression_with_string 8 * x * z + aff2 "8 x*z + 1.2 y + 1.2"
        @test_expression_with_string 2 * x * x + 1 * y * y + z + 3 "2 x² + y² + z + 3"

        @testset "isequal_canonical" begin
            @test JuMP.isequal_canonical((@inferred 3w + 2y), @inferred 2y + 3w)
            @test !JuMP.isequal_canonical((@inferred 3w + 2y + 1), @inferred 3w + 2y)
            @test !JuMP.isequal_canonical((@inferred 3w + 2y), @inferred 3y + 2w)
            @test !JuMP.isequal_canonical((@inferred 3w + 2y), @inferred 3w + y)

            @test !JuMP.isequal_canonical(aff, aff2)
            @test !JuMP.isequal_canonical(aff2, aff)

            @test  JuMP.isequal_canonical(q, @inferred 2.5z*y + aff)
            @test !JuMP.isequal_canonical(q, @inferred 2.5y*z + aff2)
            @test !JuMP.isequal_canonical(q, @inferred 2.5x*z + aff)
            @test !JuMP.isequal_canonical(q, @inferred 2.5y*x + aff)
            @test !JuMP.isequal_canonical(q, @inferred 1.5y*z + aff)
            @test  JuMP.isequal_canonical(q2, @inferred 8z*x + aff2)
            @test !JuMP.isequal_canonical(q2, @inferred 8x*z + aff)
            @test !JuMP.isequal_canonical(q2, @inferred 7x*z + aff2)
            @test !JuMP.isequal_canonical(q2, @inferred 8x*y + aff2)
            @test !JuMP.isequal_canonical(q2, @inferred 8y*z + aff2)
        end

        # Different objects that must all interact:
        # 1. Number
        # 2. Variable
        # 3. AffExpr
        # 4. QuadExpr

        # 1. Number tests
        @testset "Number--???" begin
            # 1-1 Number--Number - nope!
            # 1-2 Number--Variable
            @test_expression_with_string 4.13 + w "w + 4.13"
            @test_expression_with_string 3.16 - w "-w + 3.16"
            @test_expression_with_string 5.23 * w "5.23 w"
            @test_throws ErrorException 2.94 / w
            # 1-3 Number--AffExpr
            @test_expression_with_string 1.5 + aff "7.1 x + 4"
            @test_expression_with_string 1.5 - aff "-7.1 x - 1"
            @test_expression_with_string 2 * aff "14.2 x + 5"
            @test_throws ErrorException 2 / aff
            # 1-4 Number--QuadExpr
            @test_expression_with_string 1.5 + q "2.5 y*z + 7.1 x + 4"
            @test_expression_with_string 1.5 - q "-2.5 y*z - 7.1 x - 1"
            @test_expression_with_string 2 * q "5 y*z + 14.2 x + 5"
            @test_throws ErrorException 2 / q
        end

        # 2. Variable tests
        @testset "Variable--???" begin
            # 2-0 Variable unary
            @test (+x) === x
            @test_expression_with_string -x "-x"
            # 2-1 Variable--Number
            @test_expression_with_string w + 4.13 "w + 4.13"
            @test_expression_with_string w - 4.13 "w - 4.13"
            @test_expression_with_string w * 4.13 "4.13 w"
            @test_expression_with_string w / 2.00 "0.5 w"
            @test w == w
            @test_expression_with_string x*y - 1 "x*y - 1"
            # 2-2 Variable--Variable
            @test_expression_with_string w + x "w + x"
            @test_expression_with_string w - x "w - x"
            @test_expression_with_string w * x "w*x"
            @test_expression_with_string x - x "0"
            @test_throws ErrorException w / x
            @test_expression_with_string y*z - x "y*z - x"
            @test_expression_with_string x - x "0"
            # 2-3 Variable--AffExpr
            @test_expression_with_string z + aff "z + 7.1 x + 2.5"
            @test_expression_with_string z - aff "z - 7.1 x - 2.5"
            @test_expression_with_string z * aff "7.1 z*x + 2.5 z"
            @test_throws ErrorException z / aff
            @test_throws MethodError z ≤ aff
            @test_expression_with_string 7.1 * x - aff "-2.5"
            # 2-4 Variable--QuadExpr
            @test_expression_with_string w + q "2.5 y*z + w + 7.1 x + 2.5"
            @test_expression_with_string w - q "-2.5 y*z + w - 7.1 x - 2.5"
            @test_throws ErrorException w*q
            @test_throws ErrorException w/q
        end

        # 3. AffExpr tests
        @testset "AffExpr--???" begin
            # 3-0 AffExpr unary
            @test_expression_with_string +aff "7.1 x + 2.5"
            @test_expression_with_string -aff "-7.1 x - 2.5"
            # 3-1 AffExpr--Number
            @test_expression_with_string aff + 1.5 "7.1 x + 4"
            @test_expression_with_string aff - 1.5 "7.1 x + 1"
            @test_expression_with_string aff * 2 "14.2 x + 5"
            @test_expression_with_string aff / 2 "3.55 x + 1.25"
            @test_throws MethodError aff ≤ 1
            @test aff == aff
            @test_throws MethodError aff ≥ 1
            @test_expression_with_string aff - 1 "7.1 x + 1.5"
            # 3-2 AffExpr--Variable
            @test_expression_with_string aff + z "7.1 x + z + 2.5"
            @test_expression_with_string aff - z "7.1 x - z + 2.5"
            @test_expression_with_string aff * z "7.1 x*z + 2.5 z"
            @test_throws ErrorException aff/z
            @test_expression_with_string aff - 7.1 * x "2.5"
            # 3-3 AffExpr--AffExpr
            @test_expression_with_string aff + aff2 "7.1 x + 1.2 y + 3.7"
            @test_expression_with_string aff - aff2 "7.1 x - 1.2 y + 1.3"
            @test_expression_with_string aff * aff2 "8.52 x*y + 3 y + 8.52 x + 3"
            @test string((x+x)*(x+3)) == string((x+3)*(x+x))  # Issue #288
            @test_throws ErrorException aff/aff2
            @test_expression_with_string aff-aff "0"
            # 4-4 AffExpr--QuadExpr
            @test_expression_with_string aff2 + q "2.5 y*z + 1.2 y + 7.1 x + 3.7"
            @test_expression_with_string aff2 - q "-2.5 y*z + 1.2 y - 7.1 x - 1.3"
            @test_throws ErrorException aff2 * q
            @test_throws ErrorException aff2 / q
        end

        # 4. QuadExpr
        @testset "QuadExpr--???" begin
            # 4-0 QuadExpr unary
            @test_expression_with_string +q "2.5 y*z + 7.1 x + 2.5"
            @test_expression_with_string -q "-2.5 y*z - 7.1 x - 2.5"
            # 4-1 QuadExpr--Number
            @test_expression_with_string q + 1.5 "2.5 y*z + 7.1 x + 4"
            @test_expression_with_string q - 1.5 "2.5 y*z + 7.1 x + 1"
            @test_expression_with_string q * 2 "5 y*z + 14.2 x + 5"
            @test_expression_with_string q / 2 "1.25 y*z + 3.55 x + 1.25"
            @test q == q
            @test_expression_with_string aff2 - q "-2.5 y*z + 1.2 y - 7.1 x - 1.3"
            # 4-2 QuadExpr--Variable
            @test_expression_with_string q + w "2.5 y*z + w + 7.1 x + 2.5"
            @test_expression_with_string q - w "2.5 y*z + 7.1 x - w + 2.5"
            @test_throws ErrorException q*w
            @test_throws ErrorException q/w
            # 4-3 QuadExpr--AffExpr
            @test_expression_with_string q + aff2 "2.5 y*z + 7.1 x + 1.2 y + 3.7"
            @test_expression_with_string q - aff2 "2.5 y*z + 7.1 x - 1.2 y + 1.3"
            @test_throws ErrorException q * aff2
            @test_throws ErrorException q / aff2
            # 4-4 QuadExpr--QuadExpr
            @test_expression_with_string q + q2 "2.5 y*z + 8 x*z + 7.1 x + 1.2 y + 3.7"
            @test_expression_with_string q - q2 "2.5 y*z - 8 x*z + 7.1 x - 1.2 y + 1.3"
            @test_throws ErrorException q * q2
            @test_throws ErrorException q / q2
        end
    end

    @testset "Higher-level operators" begin
        m = Model()
        @testset "sum" begin
            sum_m = Model()
            @variable(sum_m, 0 ≤ matrix[1:3,1:3] ≤ 1, start = 1)
            @testset "sum(j::JuMPArray{Variable})" begin
                @test_expression_with_string sum(matrix) "matrix[1,1] + matrix[2,1] + matrix[3,1] + matrix[1,2] + matrix[2,2] + matrix[3,2] + matrix[1,3] + matrix[2,3] + matrix[3,3]"
            end

            @testset "sum(j::JuMPArray{T}) where T<:Real" begin
                @test sum(JuMP.startvalue.(matrix)) ≈ 9
            end
            @testset "sum(j::Array{VariableRef})" begin
                @test string(sum(matrix[1:3,1:3])) == string(sum(matrix))
            end
            @testset "sum(affs::Array{AffExpr})" begin
                @test_expression_with_string sum([2*matrix[i,j] for i in 1:3, j in 1:3]) "2 matrix[1,1] + 2 matrix[2,1] + 2 matrix[3,1] + 2 matrix[1,2] + 2 matrix[2,2] + 2 matrix[3,2] + 2 matrix[1,3] + 2 matrix[2,3] + 2 matrix[3,3]"
            end

            S = [1,3]
            @variable(sum_m, x[S], start=1)
            @testset "sum(j::JuMPDict{VariableRef})" begin
                @test_expression sum(x)
                @test length(string(sum(x))) == 11 # order depends on hashing
                @test contains(string(sum(x)),"x[1]")
                @test contains(string(sum(x)),"x[3]")
            end
            @testset "sum(j::JuMPDict{T}) where T<:Real" begin
                @test sum(JuMP.startvalue.(x)) == 2
            end
        end

        @testset "dot" begin
            dot_m = Model()
            @variable(dot_m, 0 ≤ x[1:3] ≤ 1)
            c = vcat(1:3)
            @test_expression_with_string dot(c,x) "x[1] + 2 x[2] + 3 x[3]"
            @test_expression_with_string dot(x,c) "x[1] + 2 x[2] + 3 x[3]"

            A = [1 3 ; 2 4]
            @variable(dot_m, 1 ≤ y[1:2,1:2] ≤ 1)
            @test_expression_with_string vecdot(A,y) "y[1,1] + 2 y[2,1] + 3 y[1,2] + 4 y[2,2]"
            @test_expression_with_string vecdot(y,A) "y[1,1] + 2 y[2,1] + 3 y[1,2] + 4 y[2,2]"

            B = ones(2,2,2)
            @variable(dot_m, 0 ≤ z[1:2,1:2,1:2] ≤ 1)
            @test_expression_with_string vecdot(B,z) "z[1,1,1] + z[2,1,1] + z[1,2,1] + z[2,2,1] + z[1,1,2] + z[2,1,2] + z[1,2,2] + z[2,2,2]"
            @test_expression_with_string vecdot(z,B) "z[1,1,1] + z[2,1,1] + z[1,2,1] + z[2,2,1] + z[1,1,2] + z[2,1,2] + z[1,2,2] + z[2,2,2]"

            @objective(dot_m, Max, dot(x, ones(3)) - vecdot(y, ones(2,2)))
            for i in 1:3
                JuMP.setstartvalue(x[i], 1)
            end
            for i in 1:2, j in 1:2
                JuMP.setstartvalue(y[i,j], 1)
            end
            for i in 1:2, j in 1:2, k in 1:2
                JuMP.setstartvalue(z[i,j,k], 1)
            end
            @test dot(c, JuMP.startvalue.(x)) ≈ 6
            @test vecdot(A, JuMP.startvalue.(y)) ≈ 10
            @test vecdot(B, JuMP.startvalue.(z)) ≈ 8

            @testset "JuMP issue #656" begin
                issue656 = Model()
                @variable(issue656, x)
                floats = Float64[i for i in 1:2]
                anys   = Array{Any}(undef, 2)
                anys[1] = 10
                anys[2] = 20 + x
                @test dot(floats, anys) == 10 + 40 + 2x
            end

            @testset "JuMP PR #943" begin
                pull943 = Model()
                @variable(pull943, x[1 : 10^6]);
                JuMP.setstartvalue.(x, 1 : 10^6)
                @expression(pull943, testsum, sum(x[i] * i for i = 1 : 10^6))
                @expression(pull943, testdot1, dot(x, 1 : 10^6))
                @expression(pull943, testdot2, dot(1 : 10^6, x))
                @test JuMP.value(testsum, JuMP.startvalue) ≈ JuMP.value(testdot1, JuMP.startvalue)
                @test JuMP.value(testsum, JuMP.startvalue) ≈ JuMP.value(testdot2, JuMP.startvalue)
            end
        end
    end

    vec_eq(x,y) = vec_eq([x;], [y;])

    function vec_eq(x::AbstractArray, y::AbstractArray)
        size(x) == size(y) || return false
        for i in 1:length(x)
            v, w = convert(AffExpr,x[i]), convert(AffExpr,y[i])
            JuMP.isequal_canonical(v, w) || return false
        end
        return true
    end

    function vec_eq(x::Array{QuadExpr}, y::Array{QuadExpr})
        size(x) == size(y) || return false
        for i in 1:length(x)
            JuMP.isequal_canonical(x[i], y[i]) || return false
        end
        return true
    end

    @testset "Vectorized operations" begin
        @testset "Transpose" begin
            m = Model()
            @variable(m, x[1:3])
            @variable(m, y[1:2,1:3])
            @variable(m, z[2:5])
            @test vec_eq(x', [x[1] x[2] x[3]])
            @test vec_eq(transpose(x), [x[1] x[2] x[3]])
            @test vec_eq(y', [y[1,1] y[2,1]
                              y[1,2] y[2,2]
                              y[1,3] y[2,3]])
            @test vec_eq(transpose(y),
                         [y[1,1] y[2,1]
                          y[1,2] y[2,2]
                          y[1,3] y[2,3]])
            @test (z')' == z
            @test transpose(transpose(z)) == z
        end

        @testset "Vectorized arithmetic" begin
            m = Model()
            @variable(m, x[1:3])
            A = [2 1 0
                 1 2 1
                 0 1 2]
            B = sparse(A)
            @variable(m, X11)
            @variable(m, X23)
            X = sparse([1, 2], [1, 3], [X11, X23], 3, 3) # for testing Variable
            @test vec_eq([X11 0. 0.; 0. 0. X23; 0. 0. 0.], @inferred Matrix(X))
            @variable(m, Xd[1:3, 1:3])
            Y = sparse([1, 2], [1, 3], [2X11, 4X23], 3, 3) # for testing GenericAffExpr
            Yd = [2X11 0    0
                  0    0 4X23
                  0    0    0]
            Z = sparse([1, 2], [1, 3], [X11^2, 2X23^2], 3, 3) # for testing GenericQuadExpr
            Zd = [X11^2 0      0
                  0     0 2X23^2
                  0     0      0]
            v = [4, 5, 6]
            @test vec_eq(A*x, [2x[1] +  x[2]
                               2x[2] +  x[1] + x[3]
                                x[2] + 2x[3]])
            @test vec_eq(A*x, B*x)
            @test vec_eq(A*x, @JuMP.Expression(B*x))
            @test vec_eq(@JuMP.Expression(A*x), @JuMP.Expression(B*x))
            @test vec_eq(x'*A, [2x[1]+x[2]; 2x[2]+x[1]+x[3]; x[2]+2x[3]]')
            @test vec_eq(x'*A, x'*B)
            @test vec_eq(x'*A, @JuMP.Expression(x'*B))
            @test vec_eq(@JuMP.Expression(x'*A), @JuMP.Expression(x'*B))
            @test JuMP.isequal_canonical(x'*A*x, 2x[1]*x[1] + 2x[1]*x[2] + 2x[2]*x[2] + 2x[2]*x[3] + 2x[3]*x[3])
            @test JuMP.isequal_canonical(x'A*x, x'*B*x)
            @test JuMP.isequal_canonical(x'*A*x, @JuMP.Expression(x'*B*x))
            @test JuMP.isequal_canonical(@JuMP.Expression(x'*A*x), @JuMP.Expression(x'*B*x))

            y = A*x
            @test vec_eq(-x, [-x[1], -x[2], -x[3]])
            @test vec_eq(-y, [-2x[1] -  x[2]
                               -x[1] - 2x[2] -  x[3]
                                       -x[2] - 2x[3]])
            @test vec_eq(y + 1, [2x[1] +  x[2]         + 1
                                  x[1] + 2x[2] +  x[3] + 1
                                  x[2] + 2x[3] + 1])
            @test vec_eq(y - 1, [2x[1] +  x[2]         - 1
                                  x[1] + 2x[2] +  x[3] - 1
                                          x[2] + 2x[3] - 1])
            @test vec_eq(y + 2ones(3), [2x[1] +  x[2]         + 2
                                         x[1] + 2x[2] +  x[3] + 2
                                         x[2] + 2x[3] + 2])
            @test vec_eq(y - 2ones(3), [2x[1] +  x[2]         - 2
                                         x[1] + 2x[2] +  x[3] - 2
                                         x[2] + 2x[3] - 2])
            @test vec_eq(2ones(3) + y, [2x[1] +  x[2]         + 2
                                         x[1] + 2x[2] +  x[3] + 2
                                         x[2] + 2x[3] + 2])
            @test vec_eq(2ones(3) - y, [-2x[1] -  x[2]         + 2
                                         -x[1] - 2x[2] -  x[3] + 2
                                         -x[2] - 2x[3] + 2])
            @test vec_eq(y + x, [3x[1] +  x[2]
                                  x[1] + 3x[2] +  x[3]
                                          x[2] + 3x[3]])
            @test vec_eq(x + y, [3x[1] +  x[2]
                                  x[1] + 3x[2] +  x[3]
                                  x[2] + 3x[3]])
            @test vec_eq(2y + 2x, [6x[1] + 2x[2]
                                   2x[1] + 6x[2] + 2x[3]
                                   2x[2] + 6x[3]])
            @test vec_eq(y - x, [ x[1] + x[2]
                                  x[1] + x[2] + x[3]
                                         x[2] + x[3]])
            @test vec_eq(x - y, [-x[1] - x[2]
                                 -x[1] - x[2] - x[3]
                                 -x[2] - x[3]])
            @test vec_eq(y + x[:], [3x[1] +  x[2]
                                     x[1] + 3x[2] +  x[3]
                                             x[2] + 3x[3]])
            @test vec_eq(x[:] + y, [3x[1] +  x[2]
                                     x[1] + 3x[2] +  x[3]
                                             x[2] + 3x[3]])

            @test vec_eq(@JuMP.Expression(A*x/2), A*x/2)
            @test vec_eq(X*v,  [4X11; 6X23; 0])
            @test vec_eq(v'*X,  [4X11  0   5X23])
            @test vec_eq(v.'*X, [4X11  0   5X23])
            @test vec_eq(X'*v,  [4X11;  0;  5X23])
            @test vec_eq(X.'*v, [4X11; 0;  5X23])
            @test vec_eq(X*A,  [2X11  X11  0
                                0     X23  2X23
                                0     0    0   ])
            @test vec_eq(A*X,  [2X11  0    X23
                                X11   0    2X23
                                0     0    X23])
            @test vec_eq(A*X', [2X11  0    0
                                X11   X23  0
                                0     2X23 0])
            @test vec_eq(X'*A, [2X11  X11  0
                                0     0    0
                                X23   2X23 X23])
            @test vec_eq(X.'*A, [2X11 X11  0
                                 0    0    0
                                 X23  2X23 X23])
            @test vec_eq(A'*X, [2X11  0 X23
                                X11   0 2X23
                                0     0 X23])
            @test vec_eq(X.'*A, X'*A)
            @test vec_eq(A.'*X, A'*X)
            @test vec_eq(X*A, X*B)
            @test vec_eq(Y'*A, Y.'*A)
            @test vec_eq(A*Y', A*Y.')
            @test vec_eq(Z'*A, Z.'*A)
            @test vec_eq(Xd'*Y, Xd.'*Y)
            @test vec_eq(Y'*Xd, Y.'*Xd)
            @test vec_eq(Xd'*Xd, Xd.'*Xd)
            @test vec_eq(A*X, B*X)
            @test_broken vec_eq(A*X', B*X') # See https://github.com/JuliaOpt/JuMP.jl/issues/1276
            @test vec_eq(X'*A, X'*B)
            @test vec_eq(X'*X, X.'*X)
        end

        @testset "Dot-ops" begin
            m = Model()
            @variable(m, x[1:2,1:2])
            A = [1 2;
                 3 4]
            B = sparse(A)
            y = SparseMatrixCSC(2, 2, copy(B.colptr), copy(B.rowval), vec(x))
            @test vec_eq(A.+x, [1+x[1,1]  2+x[1,2];
                                3+x[2,1]  4+x[2,2]])
            @test vec_eq(A.+x, B.+x)
            @test vec_eq(A.+x, A.+y)
            @test vec_eq(A.+y, B.+y)
            @test vec_eq(x.+A, [1+x[1,1]  2+x[1,2];
                                3+x[2,1]  4+x[2,2]])
            @test vec_eq(x.+A, x.+B)
            @test vec_eq(x.+A, y.+A)
            @test vec_eq(x .+ x, [2x[1,1] 2x[1,2]; 2x[2,1] 2x[2,2]])
            @test vec_eq(y.+A, y.+B)
            @test vec_eq(A.-x, [1-x[1,1]  2-x[1,2];
                                3-x[2,1]  4-x[2,2]])
            @test vec_eq(A.-x, B.-x)
            @test vec_eq(A.-x, A.-y)
            @test vec_eq(x .- x, [zero(AffExpr) for _1 in 1:2, _2 in 1:2])
            @test vec_eq(A.-y, B.-y)
            @test vec_eq(x.-A, [-1+x[1,1]  -2+x[1,2];
                                -3+x[2,1]  -4+x[2,2]])
            @test vec_eq(x.-A, x.-B)
            @test vec_eq(x.-A, y.-A)
            @test vec_eq(y.-A, y.-B)
            @test vec_eq(A.*x, [1*x[1,1]  2*x[1,2];
                                3*x[2,1]  4*x[2,2]])
            @test vec_eq(A.*x, B.*x)
            @test vec_eq(A.*x, A.*y)
            @test vec_eq(A.*y, B.*y)

            @test vec_eq(x.*A, [1*x[1,1]  2*x[1,2];
                                3*x[2,1]  4*x[2,2]])
            @test vec_eq(x.*A, x.*B)
            @test vec_eq(x.*A, y.*A)
            @test vec_eq(y.*A, y.*B)

            @test vec_eq(x .* x, [x[1,1]^2 x[1,2]^2; x[2,1]^2 x[2,2]^2])
            @test_throws ErrorException vec_eq(A./x, [1*x[1,1]  2*x[1,2];
                                                      3*x[2,1]  4*x[2,2]])
            @test vec_eq(x./A, [1/1*x[1,1]  1/2*x[1,2];
                                1/3*x[2,1]  1/4*x[2,2]])
            @test vec_eq(x./A, x./B)
            @test vec_eq(x./A, y./A)
            @test_throws ErrorException A./y
            @test_throws ErrorException B./y

            @test vec_eq((2*x) / 3, full((2*y) / 3))
            @test vec_eq(2 * (x/3), full(2 * (y/3)))
            @test vec_eq(x[1,1] .* A, full(x[1,1] .* B))
        end

        @testset "Vectorized comparisons" begin
            m = Model()
            @variable(m, x[1:3])
            A = [1 2 3
                 0 4 5
                 6 0 7]
            B = sparse(A)
            # force vector output
            cref1 = @constraint(m, reshape(x,(1,3))*A*x .>= 1)
            c1 = JuMP.constraintobject.(cref1, QuadExpr, MOI.GreaterThan)
            f1 = map(c -> c.func, c1)
            @test vec_eq(f1, [x[1]*x[1] + 2x[1]*x[2] + 4x[2]*x[2] + 9x[1]*x[3] + 5x[2]*x[3] + 7x[3]*x[3]])
            @test all(c -> c.set.lower == 1, c1)

            cref2 = @constraint(m, x'*A*x >= 1)
            c2 = JuMP.constraintobject.(cref2, QuadExpr, MOI.GreaterThan)
            @test vec_eq(f1[1], c2.func)

            mat = [ 3x[1] + 12x[3] +  4x[2]
                    2x[1] + 12x[2] + 10x[3]
                   15x[1] +  5x[2] + 21x[3]]

            cref3 = @constraint(m, (x'A)' + 2A*x .<= 1)
            c3 = JuMP.constraintobject.(cref3, AffExpr, MOI.LessThan)
            f3 = map(c->c.func, c3)
            @test vec_eq(f3, mat)
            @test all(c -> c.set.upper == 1, c3)
            @test vec_eq((x'A)' + 2A*x, (x'A)' + 2B*x)
            @test vec_eq((x'A)' + 2A*x, (x'B)' + 2A*x)
            @test vec_eq((x'A)' + 2A*x, (x'B)' + 2B*x)
            @test vec_eq((x'A)' + 2A*x, @JuMP.Expression((x'A)' + 2A*x))
            @test vec_eq((x'A)' + 2A*x, @JuMP.Expression((x'B)' + 2A*x))
            @test vec_eq((x'A)' + 2A*x, @JuMP.Expression((x'A)' + 2B*x))
            @test vec_eq((x'A)' + 2A*x, @JuMP.Expression((x'B)' + 2B*x))

            cref4 = @constraint(m, -1 .<= (x'A)' + 2A*x .<= 1)
            c4 = JuMP.constraintobject.(cref4, AffExpr, MOI.Interval)
            f4 = map(c->c.func, c4)
            @test vec_eq(f4, mat)
            @test all(c -> c.set.lower == -1, c4)
            @test all(c -> c.set.upper == 1, c4)

            cref5 = @constraint(m, -[1:3;] .<= (x'A)' + 2A*x .<= 1)
            c5 = JuMP.constraintobject.(cref5, AffExpr, MOI.Interval)
            f5 = map(c->c.func, c5)
            @test vec_eq(f5, mat)
            @test map(c -> c.set.lower, c5) == -[1:3;]
            @test all(c -> c.set.upper == 1, c4)

            cref6 = @constraint(m, -[1:3;] .<= (x'A)' + 2A*x .<= [3:-1:1;])
            c6 = JuMP.constraintobject.(cref6, AffExpr, MOI.Interval)
            f6 = map(c->c.func, c6)
            @test vec_eq(f6, mat)
            @test map(c -> c.set.lower, c6) == -[1:3;]
            @test map(c -> c.set.upper, c6) == [3:-1:1;]

            cref7 = @constraint(m, -[1:3;] .<= (x'A)' + 2A*x .<= 3)
            c7 = JuMP.constraintobject.(cref7, AffExpr, MOI.Interval)
            f7 = map(c->c.func, c7)
            @test vec_eq(f7, mat)
            @test map(c -> c.set.lower, c7) == -[1:3;]
            @test all(c -> c.set.upper == 3, c7)
        end
    end

    @testset "JuMPArray concatenation" begin
        m = Model()
        @variable(m, x[1:3])
        @variable(m, y[1:3,1:3])
        @variable(m, z[1:1])
        @variable(m, w[1:1,1:3])

        @test vec_eq([x y], [x[1] y[1,1] y[1,2] y[1,3]
                             x[2] y[2,1] y[2,2] y[2,3]
                             x[3] y[3,1] y[3,2] y[3,3]])

        @test vec_eq([x 2y+1], [x[1] 2y[1,1]+1 2y[1,2]+1 2y[1,3]+1
                                x[2] 2y[2,1]+1 2y[2,2]+1 2y[2,3]+1
                                x[3] 2y[3,1]+1 2y[3,2]+1 2y[3,3]+1])

        @test vec_eq([1 x'], [1 x[1] x[2] x[3]])
        @test vec_eq([2x;x], [2x[1],2x[2],2x[3],x[1],x[2],x[3]])
        # vcat on JuMPArray
        @test vec_eq([x;x], [x[1],x[2],x[3],x[1],x[2],x[3]])
        # hcat on JuMPArray
        @test vec_eq([x x], [x[1] x[1]
                             x[2] x[2]
                             x[3] x[3]])
        # hvcat on JuMPArray
        tmp1 = [z w; x y]
        tmp2 = [z[1] w[1,1] w[1,2] w[1,3]
                x[1] y[1,1] y[1,2] y[1,3]
                x[2] y[2,1] y[2,2] y[2,3]
                x[3] y[3,1] y[3,2] y[3,3]]
        @test vec_eq(tmp1, tmp2)
        tmp3 = [1 2x'
                x 2y-x*x']
        tmp4 = [1    2x[1]               2x[2]               2x[3]
                x[1] -x[1]*x[1]+2y[1,1]  -x[1]*x[2]+2y[1,2]  -x[1]*x[3] + 2y[1,3]
                x[2] -x[1]*x[2]+2y[2,1]  -x[2]*x[2]+2y[2,2]  -x[2]*x[3] + 2y[2,3]
                x[3] -x[1]*x[3]+2y[3,1]  -x[2]*x[3]+2y[3,2]  -x[3]*x[3] + 2y[3,3]]
        @test vec_eq(tmp3, tmp4)

        A = sprand(3, 3, 0.2)
        B = full(A)
        @test vec_eq([A y], [B y])
    end
end
