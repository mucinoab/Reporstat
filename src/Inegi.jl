push!(LOAD_PATH,"../src/")
using Dates, Printf 
include("Utilidades.jl") 
include("Constants.jl") 

using InfoZIP, HTTP,  StringEncodings, JSON
export poblacion_mexico, poblacion_entidad, poblacion_municipio, poblacion_todos_municipios, poblacion_todas_entidades, clave,idh,indicadores_pobreza_porcentaje,indicadores_pobreza, indicadores_pobreza_porcentaje_todos,indicadores_pobreza_todos, fechahoy, int_migratoria, geografia, codigos_postales, int_migratoria_todos_municipios, geografia_todos_municipios,tasas_vitales,edad_municipios, edad_entidades, similitud_region, similitud_entidad, similitud_municipio, codigos_postales_todos



#TODO nombre
"""
    fechahoy()::String

Crea un string con la fecha de hoy utilizando el formato "yyyymmdd". Año con cuarto dígitos, mes y día con dos.

# Ejemplo
```julia-repl
julia> fechahoy()
"20210112"
```
"""
function fechahoy()::String
  string(Dates.format(DateTime(Dates.today()), "yyyymmdd"))
end

#verifica que la 
function token_check(token_INEGI::String)::String
  if token_INEGI == ""
    try
      token_INEGI = ENV["token_INEGI"]
    catch e
      error("'token_INEGI' no encotrado. Proporcionala directamente o asignala de la siquiente manera 'ENV[\"token_INEGI\"] = <tu token>'")
    end
  end
  return token_INEGI
end

"""
    poblacion_mexico(token_INEGI::String="")::DataFrame

Regresa un `DataFrame` con los datos más recientes, a nivel nacional, proporcionados por la API de Indicadores del INEGI.
Requiere el token (`token_INEGI`) de la API, puede obtenerse [aquí.](https://www.inegi.org.mx/app/api/indicadores/interna_v1_1/tokenVerify.aspx)
Se pude proporcionar el token directamente o por medio de una variable de entorno llamada de la misma manera, `token_INEGI`.

# Ejemplo
```julia-repl
julia> ENV["token_INEGI"] = "00000000-0000-0000-0000-000000000000"
"00000000-0000-0000-0000-000000000000"

julia> popu = poblacion_mexico()
1×8 DataFrame
 Row │ lugar   total      hombres    mujeres    porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad
     │ String  Float64    Float64    Float64    Float64             Float64             Float64              Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ México  1.19938e8  5.48552e7  5.74813e7               48.57               51.43              21.4965   60.9642
```
"""
function poblacion_mexico(token_INEGI::String="")::DataFrame
  token_INEGI = token_check(token_INEGI)
  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/6207019014,1002000001,1002000002,1002000003,6207020032,6207020033,3105001001/es/0700/true/BISE/2.0/"*token_INEGI*"?type=json"
  return parse_poblacion(jsonparse(url), "México")
end

"""
    poblacion_entidad(cve_entidad::String, token_INEGI::String="")::poblacion

Regresa un una `DataFrame` con los datos más recientes, por entidad federativa, proporcionados por la API de Indicadores del INEGI.
Requiere el token (`token_INEGI`) de la API, puede obtenerse [aquí.](https://www.inegi.org.mx/app/api/indicadores/interna_v1_1/tokenVerify.aspx)
Se pude proporcionar el token directamente o por medio de una variable de entorno, de la siguiente manera. 

```julia-repl
julia> ENV["token_INEGI"] = "00000000-0000-0000-0000-000000000000"
```
El `DataFrame` resultante contiene los siguientes datos.

- lugar
- población total
- densidad de población (habitantes por kilómetro cuadrado) 
- población total hombres
- población total mujeres
- porcentaje de hombres
- porcentaje de mujeres
- porcentaje de población que se considera indígena

!!! note
    ### Área geoestadística estatal (AGEE)
    La entidad federativa se codifica de acuerdo con el orden alfabético de sus nombres _oficiales_, con una longitud de dos dígitos, a partir del 01 en adelante, según el número de entidades federativas que dispongan las leyes vigentes; en este momento son 32 entidades federativas (Aguascalientes 01, Baja California 02,... y Zacatecas 32).
    Las puedes consultar [aquí.](https://www.inegi.org.mx/app/ageeml/)

   Clave Entidad | Entidad
   --- | ---
    01 | Aguascalientes
    02 | Baja California
    03 | Baja California Sur
    ⋮  |⋮
    30 | Veracruz de Ignacio de la Llave
    31 | Yucatán
    32 | Zacatecas

# Ejemplo
```julia-repl
julia> popu = poblacion_entidad("31", token)
1×8 DataFrame
 Row │ lugar    total      hombres   mujeres   porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad
     │ String   Float64    Float64   Float64   Float64             Float64             Float64              Float64
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Yucatán  2.10226e6  963333.0  992244.0             48.9968             51.0032              65.4035   53.0607
```
"""
function poblacion_entidad(cve_entidad::String, token_INEGI::String="")::DataFrame
  token_INEGI = token_check(token_INEGI)
  try
    global lugar = entidades[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe de ser de dos dígitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/1002000001,1002000002,1002000003,6207019014,6207020032,6207020033,3105001001/es/"*cve_entidad*"/true/BISE/2.0/"*token_INEGI*"?type=json"
  return parse_poblacion(jsonparse(url), lugar)
end

"""
    poblacion_municipio(cve_entidad::String, cve_municipio::String, token_INEGI::String="")::DataFrame

Regresa un `DataFrame` con los datos más recientes, por municipio, proporcionados por la API de Indicadores del INEGI.
Requiere el token (`token_INEGI`) de la API, puede obtenerse [aquí.](https://www.inegi.org.mx/app/api/indicadores/interna_v1_1/tokenVerify.aspx)
Se pude proporcionar el token directamente o por medio de una variable de entorno llamada de la misma manera, `token_INEGI`.

!!! note
    ### Área geoestadística municipal (AGEM)
    La clave del municipio está formada por tres números que se asignan de manera ascendente  a  partir  del  001,  de  acuerdo  con  el  orden  alfabético  de  los  nombres  de  los  municipios,  aunque  a  los  creados  posteriormente  a  la  clavificación  inicial,  se  les  asigna  la  clave  geoestadística  conforme se vayan creando.
    Las puedes consultar [aquí.](https://www.inegi.org.mx/app/ageeml/)

    Clave Entidad | Nombre Entidad | Clave Municipio | Nombre Municipio 
      --- | --- | --- | --- 
    01|Aguascalientes|001	|Aguascalientes
    01|Aguascalientes|002 |Asientos	    
    01|Aguascalientes|003 |Calvillo
    ⋮|⋮|⋮|⋮
    32|Zacatecas|056|Zacatecas
    32|Zacatecas|057|Trancoso
    32|Zacatecas|058|Santa María de la Paz

# Ejemplo
```julia-repl
julia> ENV["token_INEGI"] = "00000000-0000-0000-0000-000000000000"
"00000000-0000-0000-0000-000000000000"

julia> popu = poblacion_municipio("01", "002")
1×8 DataFrame
 Row │ lugar                     total    hombres  mujeres  porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad
     │ String                    Float64  Float64  Float64  Float64             Float64             Float64              Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Aguascalientes, Asientos  45492.0  22512.0  22980.0             48.9519             51.0481              3.63938   84.6325
```
"""
function poblacion_municipio(cve_entidad::String, cve_municipio::String, token_INEGI::String="")::DataFrame
  token_INEGI = token_check(token_INEGI)
  try
    global estado = entidades[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe de ser de dos dígitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  try
    global municipio = municipios[cve_entidad*cve_municipio]
  catch e
    error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio '$cve_municipio' no existe.")
  end

  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/1002000001,6207019014,6207020032,6207020033,3105001001/es/070000"*cve_entidad*"0"*cve_municipio*"/true/BISE/2.0/"*token_INEGI*"?type=json"

  lugar = estado * ", " * municipio

  return parse_poblacion(jsonparse(url), lugar)
end

#TODO documentación
function parse_poblacion(datos::Dict, lugar::String)::DataFrame
  
  indicadores = Dict{String, Float64}()

  for dato in datos["Series"]
    indicadores[dato["INDICADOR"]] = tryparse(Float64, dato["OBSERVATIONS"][end]["OBS_VALUE"])
  end

  # indicadores INEGI, 
  # total =   1002000001 hombres = 1002000002 mujeres = 1002000003
  # densdad = 3105001001 (hab/km^2) porhom = 6207020032 pormuj = 6207020033
  # indígena= 6207019014 

  tot = trunc(Int64, indicadores["1002000001"])# población total                                 
  den = indicadores["3105001001"]              # densidad de población
  ext = tot/den                                # extensión territorial
  porcen_hom = indicadores["6207020032"]       # porcentaje de hombres
  porcen_muj = indicadores["6207020033"]       # porcentaje de mujeres
  porcen_ind = indicadores["6207019014"]       # porcentaje de población que se considera indígena
  hom =trunc(Int64,round(0.01*tot*porcen_hom)) # población hombres
  muj =trunc(Int64,round(0.01*tot*porcen_muj)) # población mujeres

  df = DataFrame(lugar=[lugar], total=[tot], hombres=[hom], mujeres=[muj],
    porcentaje_hombres=[porcen_hom], porcentaje_mujeres=[porcen_muj], 
    porcentaje_indigena=[porcen_ind], densidad_poblacion=[den], extesion_territorial=[ext])

  return df 
end

"""
    poblacion_todos_municipios()::DataFrame

Regresa un `DataFrame` con los datos poblacionales de _todos_ los municipios.

- nombre del lugar
- clave de entidad 
- nombre de la entidad
- clave de municipio
- nombre de municipio
- población total
- densidad de población (habitantes por kilómetro cuadrado) 
- población total hombres
- población total mujeres
- porcentaje de hombres
- porcentaje de mujeres
- porcentaje de población que se considera indígena

# Ejemplo
```julia-repl
julia> poblacion_todos_municipios()
2469×11 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre              total     densidad   hombres   mujeres   porcentaje_hombres  porcentajes_mujeres ⋯
      │ String   String          String     String                        Float64   Float64    Float64   Float64   Float64             Float64             ⋯
──────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes                797010.0  744.58     386429.0  410581.0             48.5335              51.4665 ⋯
    2 │ 01       Aguascalientes  002        Asientos                      797010.0  744.58     386429.0  410581.0             48.5335              51.4665 
    ⋮   │    ⋮           ⋮             ⋮                   ⋮                   ⋮          ⋮         ⋮         ⋮              ⋮                    ⋮          ⋱
 2468 │ 32       Zacatecas       057        Trancoso                      138176.0  331.026     66297.0   71879.0             48.482               51.518  ⋯
 2469 │ 32       Zacatecas       058        Santa María de la Paz          16934.0   87.9192     8358.0    8576.0             48.962               51.038  
```
"""
function poblacion_todos_municipios()::DataFrame
  path = "poblacion_municipios.csv"
  return get_info(path, [String, String, String, String, Int64, Float64, Int64, Int64, Float64, Float64, Float64, Float64])
end

"""
    poblacion_todas_entidades()::DataFrame

Regresa un `DataFrame` con los datos poblacionales de _todas_ las entidades.

- clave de entidad
- nombre oficial de la entidad
- población total
- densidad de población (habitantes por kilómetro cuadrado) 
- población total hombres
- población total mujeres
- porcentaje de hombres
- porcentaje de mujeres
- porcentaje de población que se considera indígena

# Ejemplo
```julia-repl
julia> poblacion_todas_entidades()
32×9 DataFrame
 Row │ entidad  entidad_nombre     total         densidad    hombres         mujeres         porcentaje_hombres ⋯
     │ String   String             Float64       Float64     Float64         Float64         Float64            ⋯
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────── 
   1 │ 01       Aguascalientes      1.185e6     233.729    576638.0        608358.0           48.7672 ⋯
   2 │ 02       Baja California     3.15507e6    46.4066        1.59161e6       1.56346e6     49.7725 
   ⋮ │ ⋮             ⋮               ⋮               ⋮            ⋮           ⋮                 ⋮      
  32 │ 32       Zacatecas           1.49067e6    20.9791   726897.0        763771.0           48.7819
```                                                                                                                            
"""                                                                                                                             
function poblacion_todas_entidades()::DataFrame
  path = "poblacion_entidades.csv"
  return get_info(path, [String, String, Int64, Float64, Float64, Int64, Int64, Float64, Float64, Float64])
end

"""
    clave(id::String)::String

Toma como parámetro el nombre de algún municipio o entidad y regresa la clave de este.

# Ejemplo

```julia-repl
julia> clave("Campeche")
"04"
julia> clave("Calakmul")
"010"
```
"""
function clave(id::String)::String
  if haskey(entidad_nombre, id)
    return entidad_nombre[id]
  end
  if haskey(municipio_nombre, id)
    return municipio_nombre[id][3:end]
  end
  error("No existe $id esa entidad o estado")
end

"""
    idh(cve_entidad::String, cve_municipio::String="")::Number

Regresa el indice de desarrollo humano de una entidad o de un municipio se debe especificar la clave para ambos parametros, si solo se manda el parametro _cve_entidad_ se regresara el idh de la entidad.Los datos son obtenidos de  la pgina oficial de las naciones unidas  puedes consultar [aquí](https://www.mx.undp.org/content/mexico/es/home/library/poverty/idh-municipal-en-mexico--nueva-metodologia.html).
# Ejemplo
```julia-repl
julia> idh(clave("Campeche"),"002")
0.797
julia> idh(clave("Campeche"),"003")
0.775
```
"""
function idh(cve_entidad::String, cve_municipio::String="")::Number
    tabla = get_info("IDH.csv",[String,String,String,String,Float64])
    if !haskey(entidades,cve_entidad)
        error("No se encontro la clave")
    end
    if cve_municipio == ""
        #TODO
        print("TODO recolectar idh de estados en general")
    else
        if !haskey(municipios,cve_entidad*cve_municipio)
            error("No se encontro la clave")
        end
        q1 = ":cve_entidad == '$cve_entidad'"
        q2 = ":cve_municipio == '$cve_municipio'"
        try 
            return filtrar(tabla,q1,q2)[1,:].idh
        catch
            error("No se encontro la clave")
        end
    end
end


"""
    indicadores_pobreza()::DataFrame

Proporciona el número de personas que cumple con los indicadores de pobreza según el CONEVAL, del _municipio_ indicado. 

Los datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México [datos.gob.mx](https://www.datos.gob.mx/busca/dataset/indicadores-de-pobreza-municipal-2010--2015/resource/d6d6e2a8-a2e3-4e7d-84f8-dd5ea9336671)
Consulta el [Diccionario de Datos, Indicadores de pobreza municipal (2015)](@ref)
```julia-repl
julia> df = indicadores_pobreza("01", "001") 
2457×20 DataFrame
  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯
      │ String   String               String     String           Int64    Int64      Int64     ⋯
──────┼────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes       001        Aguascalientes   224949      13650     211299 ⋯

```
"""
function indicadores_pobreza(cve_entidad::String,cve_municipio::String)::DataFrame
  path = "indicadores_de_pobreza_municipal_2015_poblacion.csv"
  tabla = get.info(path, ypes=[String, String, String, String, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64])
  return filtrar(tabla, ":entidad==$cve_entidad", ":municipio==$cve_municipio") 
end

"""
    indicadores_pobreza_porcentaje(cve_entidad::String,cve_municipio::String)::DataFrame

Proporciona el _porcentaje_ de personas que cumple con los indicadores de pobreza según el CONEVAL, del _municipio_ indicado.

Los datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México [datos.gob.mx](https://www.datos.gob.mx/busca/dataset/indicadores-de-pobreza-municipal-2010--2015/resource/d6d6e2a8-a2e3-4e7d-84f8-dd5ea9336671)
Consulta el [Diccionario de Datos, Indicadores de pobreza municipal (2015)](@ref)
```julia-repl
julia> df = indicadores_pobreza_porcentaje("01", "001") 
2457×20 DataFrame
  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯
      │ String   String               String     String           Float64  Float64    Float64   ⋯
──────┼─────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes       001        Aguascalientes      26.1        1.6       24.5 ⋯
   
```
"""
function indicadores_pobreza_porcentaje(cve_entidad::String,cve_municipio::String)::DataFrame
  path = "indicadores_de_pobreza_municipal_2015_porcentaje.csv"
  tabla = get.info(path,  types=[String, String, String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64])
  return filtrar(tabla, ":entidad==$cve_entidad", ":municipio==$cve_municipio")
end

"""
    indicadores_pobreza_todos()::DataFrame

Proporciona el número de personas que cumple con los indicadores de pobreza según el CONEVAL, a nivel _federal_ segregado por _municipios. 

Los datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México [datos.gob.mx](https://www.datos.gob.mx/busca/dataset/indicadores-de-pobreza-municipal-2010--2015/resource/d6d6e2a8-a2e3-4e7d-84f8-dd5ea9336671)
Consulta el [Diccionario de Datos, Indicadores de pobreza municipal (2015)](@ref)
```julia-repl
julia> df = indicadores_pobreza_todos() 
2457×20 DataFrame
  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯
      │ String   String               String     String           Int64    Int64      Int64     ⋯
──────┼────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes       001        Aguascalientes   224949      13650     211299 ⋯
    2 │ 01       Aguascalientes       002        Asientos          25169       2067      23101 ⋯
   ⋮  │ ⋮             ⋮               ⋮               ⋮            ⋮            ⋮          ⋮   
```
"""
function indicadores_pobreza_todos()::DataFrame
  path = "indicadores_de_pobreza_municipal_2015_poblacion.csv"
  if !isfile(path)
    global path = HTTP.download("https://raw.githubusercontent.com/mucinoab/mucinoab.github.io/dev/extras/indicadores_de_pobreza_municipal_2015_poblacion.csv", pwd())
  end
  return DataFrame(CSV.File(path, types=[String, String, String, String, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64]))
end

"""
    indicadores_pobreza_porcentaje_todos()::DataFrame

Proporciona el _porcentaje_ de personas que cumple con los indicadores de pobreza según el CONEVAL, a nivel _federal_ segregado por _municipios_.

Los datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México [datos.gob.mx](https://www.datos.gob.mx/busca/dataset/indicadores-de-pobreza-municipal-2010--2015/resource/d6d6e2a8-a2e3-4e7d-84f8-dd5ea9336671)
Consulta el [Diccionario de Datos, Indicadores de pobreza municipal (2015)](@ref)
```julia-repl
julia> df = indicadores_pobreza_porcentaje_todos() 
2457×20 DataFrame
  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯
      │ String   String               String     String           Float64  Float64    Float64   ⋯
──────┼─────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes       001        Aguascalientes      26.1        1.6       24.5 ⋯
    2 │ 01       Aguascalientes       002        Asientos            54.0        4.4       49.5 ⋯
   ⋮  │ ⋮             ⋮               ⋮               ⋮            ⋮            ⋮          ⋮    
```
"""
function indicadores_pobreza_porcentaje_todos()::DataFrame
  path = "indicadores_de_pobreza_municipal_2015_porcentaje.csv"
  if !isfile(path)
    global path = HTTP.download("https://raw.githubusercontent.com/mucinoab/mucinoab.github.io/dev/extras/indicadores_de_pobreza_municipal_2015_porcentaje.csv", pwd())
  end
  return DataFrame(CSV.File(path, types=[String, String, String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]))
end


"""
    edad_municipios()::DataFrame
Da a conocer el primer y tercer cuartil, así como mediana(segundo cuartil) de las edades por municipio en formato `DataFrame`.
Dichos datos de edades actualizados al año 2020 se obtuvieron de la página [INEGI.](https://www.inegi.org.mx/sistemas/Olap/Proyectos/bd/censos/cpv2020/pt.asp)
# Ejemplo
```julia-repl
julia> edad_municipios()
2469×7 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre    Q1             Q2            Q3
      │ String   String          String     String            Float64        Float64       Float64                  
──────┼──────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes        14           28              46
    2 │ 01       Aguascalientes  002        Asientos              11           24              42
    3 │ 01       Aguascalientes  003        Calvillo              12           27              46
   ⋮           ⋮             ⋮       ⋮             ⋮                   ⋮            ⋮               ⋮
```
"""
function edad_municipios()::DataFrame
  return get_info("cuartiles_municipios_2020.csv",[String,String,String,String, Float64,Float64,Float64])
end

"""
    edad_entidades()::DataFrame
Da a conocer el primer y tercer cuartil, así como mediana(segundo cuartil) de las edades por entidad en formato `DataFrame`.
Dichos datos de edades actualizados al año 2020 se obtuvieron de la página [INEGI.](https://www.inegi.org.mx/sistemas/Olap/Proyectos/bd/censos/cpv2020/pt.asp)
# Ejemplo
```julia-repl
julia> edad_entidades()
32×5 DataFrame
  Row │ entidad  entidad_nombre    	  Q1             Q2            Q3
      │ String   String                 Float64        Float64       Float64                  
──────┼───────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes            13           26              43
    2 │ 02       Baja California           15           28              44
    3 │ 03       Baja California Sur  	   14           28              43
   ⋮        ⋮             ⋮      		     ⋮             ⋮                ⋮            
```
"""
function edad_entidades()::DataFrame
  return get_info("cuartiles_entidades_2020.csv",[String,String,Float64,Float64,Float64])
end




"""
    int_migratoria(cve_entidad::String,cve_municipio::String ="")::Float64

Devuelve la intensidad migratoria de una entidad o municipio,
los datos se pueden obtener de [aqui](https://www.datos.gob.mx/busca/dataset/indice-absoluto-de-intensidad-migratoria-mexico--estados-unidos-2000--2010).

# Ejemplo

```julia-repl
julia> int_migratoria(clave("Campeche"),"003")
0.288

julia> int_migratoria(clave("Campeche"))
0.64
```
"""
function int_migratoria(cve_entidad::String,cve_municipio::String ="")::Float64
  q1 = ":ent == '$cve_entidad'"
  if cve_municipio == ""
    tabla = get_info("IAIM_Entidad.csv",[String,Float64])
    try 
      return filtrar(tabla,q1).IAIM
    catch 
      error("Clave $cve_entidad no encontrada")
    end
  else
    q2 = ":mun == '$cve_municipio'"
    tabla = get_info("IAIM_Municipio.csv",[String,String,String,String,Float64])
    try 
      return filtrar(tabla,q1,q2).iaim
    catch 
      error("Clave no encontrada")
    end
  end
end
"""
    int_migratoria_todos()::DataFrame

Regresa un `DataFrame` con  los indices de intensidad migratoria de todos los municipios, los datos se pueden obtener de [aqui](https://www.datos.gob.mx/busca/dataset/indice-absoluto-de-intensidad-migratoria-mexico--estados-unidos-2000--2010).

# Ejemplo

```julia-repl
julia> int_migratoria_todos()
2469×5 DataFrame
  Row │ ent     ent_nombre      mun     mun_nom                       iaim     ⋯
      │ String  String          String  String                        Float64? ⋯
──────┼─────────────────────────────────────────────────────────────────────────
    1 │ 01      Aguascalientes  001     Aguascalientes                   1.92  ⋯
    2 │ 01      Aguascalientes  002     Asientos                         5.18
  ⋮   │   ⋮           ⋮           ⋮                  ⋮                   ⋮     ⋱
 2468 │ 32      Zacatecas       057     Trancoso                         4.141 ⋯
 2469 │ 32      Zacatecas       058     Santa María de la Paz           10.074
```
 """
function int_migratoria_todos()::DataFrame
     return get_info("IAIM_Municipio.csv",[String,String,String,String,Float64])
end
"""
    geografia(cve_entidad::String,cve_municipio::String ="")::DataFrame

Devuelve un `DataFrame` con los valores clave de entidad, clave municipal ( si es requerida ), latitud, longitud, altitud.Puedes consultar la información [aquí](https://www.inegi.org.mx/app/ageeml/#).

Se pueden hacer consultas de una entidad o de un municipio.
```julia-repl
julia> geografia(clave("Oaxaca"),"003")
1×5 DataFrame
 Row │ ent  mun  latitud       longitud       altitud 
     │ Any  Any  Any           Any            Any     
─────┼────────────────────────────────────────────────
   1 │ 20   003  17°04´10.549  095°58´04.929  1486

julia> geografia(clave("Oaxaca"),"003").latitud
1-element Array{Any,1}:
 "17°04´10.549"

julia> geografia(clave("Oaxaca"),"003").altitud
1-element Array{Any,1}:
 "1486"

julia> geografia(clave("Campeche"))
1×4 DataFrame
 Row │ ent  latitud       longitud       altitud 
     │ Any  Any           Any            Any     
─────┼───────────────────────────────────────────
   1 │ 04   19°01´17.138  092°27´54.859  14

```
"""
function geografia(cve_entidad::String,cve_municipio::String ="")::DataFrame
  tabla = get_info("lat_lon_alt_municipios.csv",[String,String,String,String,String,String,Float64])
  q1 = ":ent == '$cve_entidad'"
  if cve_municipio == ""
    try
      return seleccionar(filtrar(tabla,q1,":mun =='003'"),["1","2","5","6","7"])
    catch 
      error("Clave $cve_entidad no encontrada")
    end
  else
    q2 = ":mun == '$cve_municipio'"
    try
      return filtrar(tabla,q1,q2)
    catch
      error("Clave no encontrada ")
    end
  end
end
"""
    geografia_todos_municipios()::DataFrame
Devuelve los datos geograficos de todos los municipios, puedes consultar la información [aquí](https://www.inegi.org.mx/app/ageeml/#).

# Ejemplo

```julia-repl
julia> geografia_todos_municipios()
2469×7 DataFrame
  Row │ ent     nom_ent         mun     nom_mun                       latitud  ⋯
      │ String  String          String  String                        String   ⋯
──────┼─────────────────────────────────────────────────────────────────────────
    1 │ 01      Aguascalientes  001     Aguascalientes                22°03´26 ⋯
    2 │ 01      Aguascalientes  002     Asientos                      22°17´45
  ⋮   │   ⋮           ⋮           ⋮                  ⋮                     ⋮   ⋱
 2468 │ 32      Zacatecas       057     Trancoso                      22°49´06 ⋯
 2469 │ 32      Zacatecas       058     Santa María de la Paz         21°33´55
```
"""
function geografia_todos_municipios()::DataFrame
  try 
    return get_info("lat_lon_alt_municipios.csv",[String,String,String,String,String,String,Float64])
  catch
    error("Hubo un problema consiguiendo la informacion")
  end
end
"""
    codigos_postales()::DataFrame

Proporciona los _códigos postales_ del municpio indicado,
en un `DataFrame`.
Los datos son obtenidos del [Servicio Postal Mexicano.](https://www.gob.mx/correosdemexico)

# Ejemplo

```julia-repl
julia> codigos_postales("01", "001")
2465×6 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre  número de códigos postales  códigos postales
      │ String   String          String     String            Int64                       String          
──────┼────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes                           599  20000;20010;20010 ⋯
```
"""
function codigos_postales(cve_entidad::String, cve_municipio::String)::DataFrame
 	codigos = get_info("codigos_postales_municipios_2021.csv",[String,String,String,String,Int64,String])
	return filtrar(codigos, ":entidad==$cve_entidad", ":municipio==$cve_municipio")
end

"""
    codigos_postales_todos()::DataFrame

Proporciona todos los _códigos postales_ de México, segregados por municipio,
en un `DataFrame`.
Los datos son obtenidos del [Servicio Postal Mexicano.](https://www.gob.mx/correosdemexico)

# Ejemplo

```julia-repl
julia> codigos_postales_todos()
2465×6 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre  número de códigos postales  códigos postales
      │ String   String          String     String            Int64                       String          
──────┼────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes                           599  20000;20010;20010 ⋯
    2 │ 01       Aguascalientes  002        Asientos                                  82  20700;20700;20700 ⋯
  ⋮   │    ⋮           ⋮             ⋮                   ⋮                ⋮                               ⋮
```
"""
function codigos_postales_todos()::DataFrame
  return get_info("codigos_postales_municipios_2021.csv",[String,String,String,String,Int64,String])
end

"""
    tasas_vitales()::DataFrame

Proporciona un `DataFrame` con las tasas de natalidad, fecundidad y mortalidad del municipio indicado.
En caso de omitir el parametro cve_municipio, se mostraran datos de la entidad indicada.
Datos obtenidos del registro de nacimientos (2019), defunciones generales (2019) y población de mujeres en edad fertil (15-45 años, 2020) del INEGI.

# Ejemplo

```julia-repl
julia> tasas_vitales("01", "001")
1×3 DataFrame
 Row │ Natalidad  Fecundidad  Mortalidad
     │ Float64    Float64     Float64    
─────┼───────────────────────────────────  
   1 │ 0.0430915   0.0915221   0.0221098
```
"""
function tasas_vitales(cve_entidad::String, cve_municipio::String="")::DataFrame

	token_INEGI = token_check(token_INEGI)

	try
		estado = entidades[cve_entidad]
	catch e
		error("Verifica tu clave de entidad. Debe ser de dos digitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
	end

	try
    		 municipio = municipios[cve_entidad*cve_municipio]
	catch e
    		error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio '$cve_municipio' no existe.")
	end

	nacimientos = get_info("nacimientos.csv")

	if(cve_municipio=="")
		localidad = poblacion_entidad(cve_entidad)
		pob_mujeres = localidad[:1, :4]

		estado = filtrar(nacimientos, ":entidad == $cve_entidad", ":municipio == '000'")
  		nacimientos_ent = estado[:1, :4]
		if(nacimientos_ent == "")
			natalidad = 0
		else
			natalidad = nacimientos_ent/pob_mujeres
		end
	else
		localidad = poblacion_municipio(cve_entidad, cve_municipio)
		pob_mujeres = localidad[:1, :4]

		municipio = filtrar(nacimientos, ":entidad == $cve_entidad", ":municipio == $cve_municipio")
  		nacimientos_muni = municipio[:1, :4]
		if(nacimientos_muni == "")
			natalidad = 0
		else
			natalidad = nacimientos_muni/pob_mujeres
		end
	end

	fertilidades = get_info("fertilidad_entidad_municipio_2020.csv")

	if(cve_municipio=="")
		fertil_ent = filtrar(fertilidades, ":entidad == $cve_entidad", ":municipio == '000'")
		pob_fertil = fertil_ent[:1, :4]
		fecundidad = nacimientos_ent/pob_fertil
	else
		fertil_muni = filtrar(fertilidades, ":entidad == $cve_entidad", ":municipio == $cve_municipio")
		pob_fertil = fertil_muni[:1, :4]
		fecundidad = nacimientos_muni/pob_fertil
	end
	
	defunciones = get_info("defunciones_municipio_2019.csv")

	pob_total = localidad[:1, :2]

	if(cve_municipio=="")
		estado = filtrar(nacimientos, ":entidad == $cve_entidad", ":municipio == '000'")
		defunciones_ent = estado[:1, :4]
		if(defunciones_ent == "")
			mortalidad = 0
		else
			mortalidad = defunciones_ent/pob_total
		end
	else
		municipio = filtrar(nacimientos, ":entidad == $cve_entidad", ":municipio == $cve_municipio")
		defunciones_muni = municipio[:1, :4]
		if(defunciones_muni == "")
			mortalidad = 0
		else
			mortalidad = defunciones_muni/pob_total
		end
	end
	return DataFrame(natalidad=[natalidad], fecundidad=[fecundidad], mortalidad=[mortalidad])
end


# toma un string (a) y un arreglo (b) para regresar los elementos de b 
# que tengan similitud con a. Qué tan similar tiene que ser un elemento
# de b a "a" para ser considerado se ajusta con el parámetro "min_score".
function colecta_similitud(id::String, iter::Array{String})::Array{String}
  similar = String[]
  for f in findall(id, iter, StringDistances.Levenshtein(), min_score = 0.5)
    push!(similar, iter[f])
  end
  return similar
end

"""
    similitud_entidad(entidad::String)::Array{String}

Proporciona un arreglo con todas las entidades con un nombre igual o similar a `entidad`.

# Ejemplo
```julia-repl
julia> similitud_entidad("oajaca")
1-element Array{String,1}:
 "Oaxaca"

julia> clave(similitud_entidad("oaxjaca")[1])
"29"
```
"""
function similitud_entidad(id::String)::Array{String}
  entidades_iter = collect(values(entidades))
  return colecta_similitud(id, entidades_iter)
end
 
"""
    similitud_municipio(municipio::String)::Array{String}

Proporciona un arreglo con todos los municipios con un nombre igual o similar a `municipio`.

# Ejemplo
```julia-repl
julia> similitud_municipio("tequixciapn")
3-element Array{String,1}:
 "Tequisquiapan"
 "Atlequizayan"
 "Tequixquiac"

julia> clave(similitud_municipio("tequixciapn")[end])
"096"
```
"""
function similitud_municipio(id::String)::Array{String}
  municipios_iter = collect(values(municipios))
  return colecta_similitud(id, municipios_iter)
end

"""
    similitud_region(region::String)::Array{Array{String}}

Proporciona _dos_ arreglos dentro de un arreglo. El primer arreglo contiene todas
las entidades similares a `region` y el segundo todos los municipios similares a 
`region`.

# Ejemplo
```julia-repl
julia> similitud_region("jalisto")
2-element Array{Array{String,N} where N,1}:
 ["Jalisco"]
 ["Xalisco", "Naolinco", "Xaloztoc", "Calvillo", "Saltillo"]
```
"""
function similitud_region(id::String)::Array{Array{String}}
  entidades_iter = collect(values(entidades))
  municipios_iter = collect(values(municipios))
  simil_entidades = colecta_similitud(id, entidades_iter)
  simil_municipio = colecta_similitud(id, municipios_iter)
  return [simil_entidades, simil_municipio]
end
