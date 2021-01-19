@testset "Utils" begin
  @testset "sumacolumna" begin
    df = data_check("./src/cities.csv")
    @test Covid.sumacolumna(df, 1) == 4969
    @test Covid.sumacolumna(df, "LatD") == 4969
  end;

  @testset "sumafila" begin
    df = DataFrame(A = 1:4, B = 4.0:-1.0:1.0)
    @test Covid.sumafila(df, 1) == 4.0
  end;

  @testset "data_check url" begin
    datos_url = "https://raw.githubusercontent.com/mucinoab/Covid/master/src/cities.csv"
    dlocal = data_check("./src/cities.csv")
    dremoto = data_check(datos_url, "URL")
    @test dlocal == dremoto
  end;

  @testset "data_check local" begin
    file = "./src/cities.csv"
    df_custom = data_check(file)
    df = DataFrame(CSV.File(file))
    @test df_custom == df
  end;
end;
