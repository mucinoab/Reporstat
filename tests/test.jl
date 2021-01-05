using Pkg, Test

Pkg.activate(".")
using Covid

@testset "All tests" begin

  @testset "Covid" begin
    @test Covid.func(2) == 5
  end;

  @testset "Second" begin
    @test isequal(NaN, NaN)
  end;

  @testset "Third" begin
    @test true
  end;
end;
