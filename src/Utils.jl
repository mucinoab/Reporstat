push!(LOAD_PATH,"../src/")
using Dates, Printf

using InfoZIP, HTTP, DataFrames, CSV, StringEncodings, JSON
export unzip, data_check, fechahoy, sumacolumna, sumafila, poblacion_mexico, poblacion_entidad, poblacion_municipio, poblacion_todos_municipios, poblacion_todos_entidades, CSV_to_DataFrame, jsonparse

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

Lee un archivo CSV con el `encoding` indicado y regresa un `DataFrame`.

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

Crea un `DataFrame` dado un archivo CSV o una liga al archivo.
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

Suma todos los valores de una determinada columna en un `DataFrame`.
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

Suma todos los valores de una determinada fila en un `DataFrame`.
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
  return sum(eachrow(tabla)[fila])
end

"""
    jsonparse(url::String)::Dict

Hace un http request al `url` especificado y convierte el `json` obtenido del sitio web en un diccionario.
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
    error("Error de servidor, respuesta http: $request.status")
  end
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
  hom = indicadores["1002000002"]       
  muj = indicadores["1002000003"]       
  tot = hom + muj #Parce ser que el API no proporciona este dato(!?)
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

  tot = indicadores["1002000001"]        # población total                                 
  hom = indicadores["1002000002"]        # población hombres
  muj = indicadores["1002000003"]        # población mujeres
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
    poblacion_todos_entidades()::DataFrame

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
julia> poblacion_todos_entidades()
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
function poblacion_todos_entidades()::DataFrame
  path = "poblacion_entidades.csv"
  if !isfile(path)
    global path = HTTP.download("https://raw.githubusercontent.com/mucinoab/mucinoab.github.io/dev/extras/poblacion_entidades.csv", pwd())
  end

  return DataFrame(CSV.File(path, types=[String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64]))
end

