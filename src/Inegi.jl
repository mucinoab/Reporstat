push!(LOAD_PATH,"../src/")
using Dates, Printf
include("Utils.jl")
include("Constants.jl")
using InfoZIP, HTTP, DataFrames, CSV, StringEncodings, JSON
export poblacion_mexico, poblacion_entidad, poblacion_municipio, poblacion_todos_municipios, poblacion_todas_entidades, clave,idh



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

  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/1002000002,1002000003,6207019014,6207020032,6207020033,3105001001/es/070000"*cve_entidad*"0"*cve_municipio*"/true/BISE/2.0/"*token_INEGI*"?type=json"

  datos = jsonparse(url)
  indicadores = Dict{String, Float64}()

  for dato in datos["Series"]
    indicadores[dato["INDICADOR"]] = tryparse(Float64, dato["OBSERVATIONS"][end]["OBS_VALUE"])
  end

  lugar = estado * ", " * municipio
  hom = trunc(Int64, indicadores["1002000002"])
  muj = trunc(Int64, indicadores["1002000003"])
  tot = trunc(Int64, hom + muj) #Parce ser que el API no proporciona este dato(!?)
  den = indicadores["3105001001"]       
  porcen_hom = indicadores["6207020032"]
  porcen_muj = indicadores["6207020033"]
  porcen_ind = indicadores["6207019014"]

  df = DataFrame(lugar=[lugar], total=[tot], hombres=[hom], mujeres=[muj],
    porcentaje_hombres=[porcen_hom], porcentaje_mujeres=[porcen_muj], 
    porcentaje_indigena=[porcen_ind], densidad_poblacion=[den])
 
  return df 
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

  tot = trunc(Int64, indicadores["1002000001"])        # población total                                 
  hom = trunc(Int64, indicadores["1002000002"])        # población hombres
  muj = trunc(Int64, indicadores["1002000003"])        # población mujeres
  den = indicadores["3105001001"]        # densidad de población
  porcen_hom = indicadores["6207020032"] # porcentaje de hombres
  porcen_muj = indicadores["6207020033"] # porcentaje de mujeres
  porcen_ind = indicadores["6207019014"] # porcentaje de población que se considera indígena

  df = DataFrame(lugar=[lugar], total=[tot], hombres=[hom], mujeres=[muj],
    porcentaje_hombres=[porcen_hom], porcentaje_mujeres=[porcen_muj], 
    porcentaje_indigena=[porcen_ind], densidad_poblacion=[den])

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
  path = "muni.csv"
  if !isfile(path)
    global path = HTTP.download("https://raw.githubusercontent.com/mucinoab/mucinoab.github.io/dev/extras/muni.csv", pwd())
  end

  return DataFrame(CSV.File(path, types=[String, String, String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]))
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
  if !isfile(path)
    global path = HTTP.download("https://raw.githubusercontent.com/mucinoab/mucinoab.github.io/dev/extras/poblacion_entidades.csv", pwd())
  end

  return DataFrame(CSV.File(path, types=[String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]))
end

"""
   clave(id::String)::String

Toma como parametro el nombre de algun municipio o entidad y regresa la clave de este.
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

Regresa el indice de desarrollo humano de una entidad o de un municipio se debe especificar la clave para ambos parametros, si solo se manda el parametro _cve_entidad_ se regresara el idh de la entidad.Los datos son obtenidos de  la pgina oficial de las naciones unidas  puedes consultar [aqui](https://www.mx.undp.org/content/mexico/es/home/library/poverty/idh-municipal-en-mexico--nueva-metodologia.html).
"""
function idh(cve_entidad::String, cve_municipio::String="")::Number
    tabla = get_info("IDH.csv",[String,String,String,String,Float64])
       
    if !haskey(entidades,cve_entidad)
        error("No se encontro la clave $cve_entidad")
    end
    if cve_municipio == ""
        #TODO
        print("TODO recolectar idh de estados en general")
    else
        if !haskey(municipios,cve_entidad*cve_municipio)
            error("No se encontro la clave $cve_municipio")
        end
        q1 = ":cve_entidad == '$cve_entidad'"
        q2 = ":cve_municipio == '$cve_municipio'"
        try 
            return filtrar(tabla,q1,q2)[1,:].idh
        catch
            error("No se encontro la clave $cve_municipio")
        end
    end
end
