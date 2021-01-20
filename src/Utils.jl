push!(LOAD_PATH,"../src/")
using Dates, Printf

using InfoZIP, HTTP, DataFrames, CSV, StringEncodings, JSON
export unzip, data_check, fechahoy, sumacolumna, sumafila, jsonparse, poblacion_mexico, poblacion_entidad
export poblacion

include("Constants.jl") # Diccionario de entidades y municipios 

"""
    unzip(path::String, dest::String="")

Descomprime y guarda el archivo en el destino indicado(`dest`), si no se proporciona un destino, se guarda en el directorio actual.

# Ejemplo
```julia-repl
julia> unzip("datos.zip")
julia> unzip("datos.zip", pwd()*"/datos")
```
"""
function unzip(path::String, dest::String="")
  if dest == ""
    InfoZIP.unzip(path, pwd())
  else
    InfoZIP.unzip(path, dest)
  end
end


"""
    CSV_to_DataFrame(path_url::String, encoding::String="UTF-8")::DataFrame

Lee un archivo CSV con el `encoding` indicado y regresa un _DataFrame_.

# Ejemplo
```julia-repl
julia> df = DataFrameEncode("datos.csv")
julia> df_latin1 = DataFrameEncode("datos.csv", "LATIN1")
```

Los _encodings_ soportados dependen de la plataforma, obtén la lista de la siguiente manera.

```julia-repl
julia> using StringEncodings
julia> encodings()

```
"""
function CSV_to_DataFrame(path::String, encoding::String="UTF-8")
  f = open(path, "r")
  s = StringDecoder(f, encoding, "UTF-8")
  data = DataFrame(CSV.File(s))
  close(s)
  close(f)
  return data
end


"""
    data_check(path_url::String, type::String="PATH", encoding::String="UTF-8")::DataFrame

Crea un _DataFrame_ dado un archivo CSV o una liga al archivo.
Se pude especificar el _encoding_.

# Ejemplo
```julia-repl
julia> url = "http://www.conapo.gob.mx/work/models/OMI/Datos_Abiertos/DA_IAIM/IAIM_Municipio_2010.csv"
julia> first(data_check(url, "URL", "LATIN1"))
julia> first(data_check("prueba.csv"))
```
"""
function data_check(path_url::String, type::String="PATH", encoding::String="UTF-8")::DataFrame
  if type == "PATH"
    return CSV_to_DataFrame(path_url, encoding)
  elseif type == "URL"
    path = HTTP.download(path_url, pwd())
    return CSV_to_DataFrame(path, encoding)
  else
    error("'type' debe de ser 'PATH' o 'URL'")
  end
end

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

"""
    sumacolumna(tabla::DataFrame, col::Int)::Number
    sumacolumna(tabla::DataFrame, col::String)::Number

Suma todos los valores de una determinada columna en un DataFrame.
Para hacer referencia a que columna se desea sumar se pude usar la posición de la columna o el nombre que tiene.

# Ejemplo
```julia-repl
julia> df = data_check("datos.csv")
4×2 DataFrame
 Row │ x      y
     │ Int64  Int64
─────┼──────────────
   1 │     0     11
   2 │     2     12
   3 │     0     13
   4 │    40     14

julia> sumacolumna(df, 1)
42

julia> sumacolumna(df, "x")
42
```
"""
function sumacolumna(tabla::DataFrame, col)::Number
  return sum(eachcol(tabla)[col])
end

"""
    sumafila(tabla::DataFrame, fila::Int)::Number

Suma todos los valores de una determinada fila en un DataFrame.
La fila se especifica con la posición en la que se encuentra.

# Ejemplo
```julia-repl
julia> df = data_check("datos.csv")
4×2 DataFrame
 Row │ x      y
     │ Int64  Int64
─────┼──────────────
   1 │     0     11
   2 │     2     12
   3 │     0     13
   4 │    40     14

julia> sumafila(df, 2)
14

julia> sumafila(df, 4)
54
```
"""
function sumafila(tabla::DataFrame, fila::Int)::Number
  return prod(eachrow(tabla)[fila])
end

"""
    jsonparse(url::String)::Dict

Hace un http request al `url` especificado y convierte el json obtenido del sitio web en un diccionario.
En caso de que el servidor devuelva un _status_ distinto a _200_, se arroja un `error`.

# Ejemplo
```julia-repl
julia> datos = jsonparse("https://sitioweb.com/datos.json")
```
"""
function jsonparse(url::String)::Dict
  request = HTTP.request("GET", url)

  if request.status == 200
    json = String(request.body)
    return JSON.parse(json, dicttype=Dict, inttype=Int8)
  else
    error("Error de servidor, respuesta http: $(Printf.@sprintf("%i", request.status))")
  end
end

struct poblacion
  lugar::String
  total::Float64
  hombres::Float64
  mujeres::Float64
  porcentaje_hombres::Float64
  porcentaje_mujeres::Float64
  porcentaje_indigena::Float64
end

"""
    poblacion_mexico(token_INEGI::String)::poblacion

Regresa un una estructura `poblacion` con los datos más recientes, a nivel nacional, proporcionados por la API de Indicadores del INEGI.
Requiere el token (`token_INEGI`) de la API, puede obtenerse [aquí.](https://www.inegi.org.mx/app/api/indicadores/interna_v1_1/tokenVerify.aspx)

# Ejemplo
```julia-repl
julia> popu = poblacion_mexico(token)

julia> popu.total
1.19938473e8
```
"""
function poblacion_mexico(token_INEGI::String)::poblacion
  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/6207019014,1002000001,1002000002,1002000003,6207020032,6207020033/es/0700/true/BISE/2.0/"*token_INEGI*"?type=json"
  return parse_poblacion(jsonparse(url), "México")
end

"""
    poblacion_entidad(token_INEGI::String, cve_entidad::String)::poblacion

Regresa un una estructura `poblacion` con los datos más recientes, por entidad federativa, proporcionados por la API de Indicadores del INEGI.
Requiere el token (`token_INEGI`) de la API, puede obtenerse [aquí.](https://www.inegi.org.mx/app/api/indicadores/interna_v1_1/tokenVerify.aspx)
La estructura _poblacion_  contiene los siguientes datos.
- lugar
- población total
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
julia> struct poblacion
  lugar::String
  total::Float64
  hombres::Float64
  mujeres::Float64
  porcentaje_hombres::Float64
  porcentaje_mujeres::Float64
  porcentaje_indigena::Float64
end

julia> popu = poblacion_entidad(token, "31")
poblacion("Yucatán", 2.102259e6, 963333.0, 992244.0, 48.996769, 51.003231, 65.403459)

julia> popu.porcentaje_indigena
65.403459
```
"""
function poblacion_entidad(token_INEGI::String, cve_entidad::String)::poblacion
  try
    global lugar = entidades[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe de ser de dos dígitos en el rango [01, 32]. cve_entidad '$(Printf.@sprintf("%s", cve_entidad))' no existe.")
  end

  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/1002000001,1002000002,1002000003,6207019014,6207020032,6207020033/es/"*cve_entidad*"/true/BISE/2.0/"*token_INEGI*"?type=json"
  return parse_poblacion(jsonparse(url), lugar)
end

"""
    poblacion_municipio(token_INEGI::String, cve_entidad::String, cve_municipio::String)::poblacion

Regresa un una estructura `poblacion` con los datos más recientes, por municipio, proporcionados por la API de Indicadores del INEGI.
Requiere el token (`token_INEGI`) de la API, puede obtenerse [aquí.](https://www.inegi.org.mx/app/api/indicadores/interna_v1_1/tokenVerify.aspx)

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
julia> popu = poblacion_municipio(token, "01", "002")

julia> popu.lugar
Aguascalientes, Asientos

julia> popu.hombres
22512.000000
```
"""
function poblacion_municipio(token_INEGI::String, cve_entidad::String, cve_municipio::String)::poblacion
  try
    global estado = entidades[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe de ser de dos dígitos en el rango [01, 32]. cve_entidad '$(Printf.@sprintf("%s", cve_entidad))' no existe.")
  end

  try
    global municipio = municipios[cve_entidad*cve_municipio]
  catch e
    error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio: $(Printf.@sprintf("%s", cve_municipio)).")
  end

  url = "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/1002000002,1002000003,6207019014,6207020032,6207020033/es/070000"*cve_entidad*"0"*cve_municipio*"/true/BISE/2.0/"*token_INEGI*"?type=json"

  datos = jsonparse(url)["Series"]
  lugar = estado * ", " * municipio
  hombres = tryparse(Float64, datos[1]["OBSERVATIONS"][end]["OBS_VALUE"])            
  mujeres = tryparse(Float64, datos[2]["OBSERVATIONS"][end]["OBS_VALUE"])            
  total = hombres + mujeres #Parce ser que el API no proporciona este dato(!?)
  porcentaje_indigena = tryparse(Float64, datos[3]["OBSERVATIONS"][end]["OBS_VALUE"])
  porcentaje_hombres = tryparse(Float64, datos[4]["OBSERVATIONS"][end]["OBS_VALUE"]) 
  porcentaje_mujeres = tryparse(Float64, datos[5]["OBSERVATIONS"][end]["OBS_VALUE"]) 
  return poblacion(lugar, total, hombres, mujeres, porcentaje_hombres, porcentaje_mujeres, porcentaje_indigena)
end

#TODO documentación
function parse_poblacion(datos::Dict, lugar::String)::poblacion
  datos = datos["Series"]
  total = tryparse(Float64, datos[1]["OBSERVATIONS"][end]["OBS_VALUE"])              # población total
  hombres = tryparse(Float64, datos[2]["OBSERVATIONS"][end]["OBS_VALUE"])            # población hombres
  mujeres = tryparse(Float64, datos[3]["OBSERVATIONS"][end]["OBS_VALUE"])            # población mujeres
  porcentaje_indigena = tryparse(Float64, datos[4]["OBSERVATIONS"][end]["OBS_VALUE"])# porcentaje de población que se considera indígena
  porcentaje_hombres = tryparse(Float64, datos[5]["OBSERVATIONS"][end]["OBS_VALUE"]) # porcentaje de hombres
  porcentaje_mujeres = tryparse(Float64, datos[6]["OBSERVATIONS"][end]["OBS_VALUE"]) # porcentaje de mujeres
  return poblacion(lugar, total, hombres, mujeres, porcentaje_hombres, porcentaje_mujeres, porcentaje_indigena)
end
