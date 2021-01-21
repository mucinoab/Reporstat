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

  @testset "API INEGI" begin
    token = ENV["INEGI_TOKEN"]
    @test Covid.poblacion_mexico(token).lugar == "México"

    @test Covid.poblacion_entidad(token, "32").lugar == "Zacatecas"
    @test Covid.poblacion_entidad(token, "06").densidad_poblacion == 126.39943

    @test Covid.poblacion_municipio(token, "01", "001").lugar == "Aguascalientes, Aguascalientes"

    cdmx = Covid.poblacion_municipio(token, "09", "016")
    @test cdmx.lugar == "Ciudad de México, Miguel Hidalgo"
    @test cdmx.hombres == 172667.00
    @test cdmx.hombres == 172667.00
    @test cdmx.mujeres == 200222.00
    @test cdmx.porcentaje_hombres == 45.847179
    @test cdmx.porcentaje_mujeres == 54.152821
    @test cdmx.porcentaje_indigena == 5.0142822
    @test cdmx.densidad_poblacion == 7855.6605
  end;
end;
