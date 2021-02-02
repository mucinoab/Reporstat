@testset "Utils" begin
  @testset "sumar_columna" begin
    df = cargar_csv("./src/cities.csv")
    @test Reporstat.sumar_columna(df, 1) == 4969
    @test Reporstat.sumar_columna(df, "LatD") == 4969
  end;

  @testset "sumar_fila" begin
    df = DataFrame(A = 1:4, B = 4.0:-1.0:1.0)
    @test Reporstat.sumar_fila(df, 1) == 5.0
  end;

  @testset "cargar_csv url" begin
    datos_url = "https://raw.githubusercontent.com/mucinoab/Reporstat/master/src/cities.csv"
    dlocal = cargar_csv("./src/cities.csv")
    dremoto = cargar_csv(datos_url, "URL")
    @test dlocal == dremoto
  end;

  @testset "cargar_csv local" begin
    file = "./src/cities.csv"
    df_custom = cargar_csv(file)
    df = DataFrame(CSV.File(file))
    @test df_custom == df
  end;

  @testset "API INEGI" begin
    @test Reporstat.poblacion_mexico().lugar == ["México"]

    @test Reporstat.poblacion_entidad("32").lugar == ["Zacatecas"]
    @test Reporstat.poblacion_entidad("06").densidad_poblacion == [129.981519801061]

    @test Reporstat.poblacion_municipio("01", "001").lugar == ["Aguascalientes, Aguascalientes"]

    cdmx = Reporstat.poblacion_municipio("09", "016")
    @test cdmx.lugar == ["Ciudad de México, Miguel Hidalgo"]
    @test cdmx.hombres == [195467]
    @test cdmx.mujeres == [219003]
    @test cdmx.porcentaje_hombres == [47.1607112698145]
    @test cdmx.porcentaje_mujeres == [52.8392887301855]
    @test cdmx.porcentaje_indigena == [5.0142822]
    @test cdmx.densidad_poblacion == [8927.81062496375]
  end;
end;
