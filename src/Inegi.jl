push!(LOAD_PATH,"../src/")
using Dates, Printf
include("Utilidades.jl")
include("Constants.jl")

using InfoZIP, HTTP,  StringEncodings, JSON, StringDistances
export poblacion_mexico, poblacion_entidad, poblacion_municipio, poblacion_todos_municipios, poblacion_todas_entidades, clave,idh,indicadores_pobreza_porcentaje,indicadores_pobreza, indicadores_pobreza_porcentaje_todos,indicadores_pobreza_todos, fechahoy, int_migratoria, geografia, codigos_postales, int_migratoria_todos, geografia_todos_municipios,tasas_vitales,edad_municipios, edad_entidades, similitud_region, similitud_entidad, similitud_municipio, codigos_postales_todos,idh_todos_municipios, edad_municipios_todos

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

# Verifica que el token este presente
# o que este asignado como variable de entorno.
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
Se puede proporcionar el token directamente o por medio de una [variable de entorno](https://docs.julialang.org/en/v1/base/base/#Base.ENV) llamada de la misma manera, `token_INEGI`.

# Ejemplo
```julia-repl
julia> ENV["token_INEGI"] = "00000000-0000-0000-0000-000000000000"
"00000000-0000-0000-0000-000000000000"

julia> poblacion_mexico()
1×9 DataFrame
 Row │ lugar   total      hombres   mujeres   porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad_poblacion  extesion_territorial
     │ String  Int64      Int64     Int64     Float64             Float64             Float64              Float64             Float64
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ México  126014024  61473390  64540634              48.783              51.217              21.4965             64.2717             1.96065e6
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
Se puede proporcionar el token directamente o por medio de una [variable de entorno](https://docs.julialang.org/en/v1/base/base/#Base.ENV), de la siguiente manera.

```julia-repl
julia> ENV["token_INEGI"] = "00000000-0000-0000-0000-000000000000"
```
El `DataFrame` resultante contiene los siguientes datos.

- lugar
- población total
- densidad de población (habitantes por kilómetro cuadrado)
- extensión terrotorial (kilómetros cuadrados)
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
1×9 DataFrame
 Row │ lugar    total    hombres  mujeres  porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad_poblacion  extesion_territorial
     │ String   Int64    Int64    Int64    Float64             Float64             Float64              Float64             Float64
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Yucatán  2320898  1140279  1180619             49.1309             50.8691              65.4035             58.7206               39524.4
```
"""
function poblacion_entidad(cve_entidad::String, token_INEGI::String="")::DataFrame
  token_INEGI = token_check(token_INEGI)
   cve_entidad, cve_municipio= check(cve_entidad,"") 
  try
    global lugar = ENTIDADES[cve_entidad]
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
Se puede proporcionar el token directamente o por medio de una [variable de entorno](https://docs.julialang.org/en/v1/base/base/#Base.ENV) llamada de la misma manera, `token_INEGI`.

!!! note
    ### Área geoestadística municipal (AGEM)
    La clave del municipio está formada por tres números que se asignan de manera ascendente  a  partir  del  001,  de  acuerdo  con  el  orden  alfabético  de  los  nombres  de  los  municipios,  aunque  a  los  creados  posteriormente  a  la  clavificación  inicial,  se  les  asigna  la  clave  geoestadística  conforme se vayan creando.
    Las puedes consultar [aquí.](https://www.inegi.org.mx/app/ageeml/)

    Clave Entidad | Nombre Entidad | Clave Municipio | Nombre Municipio
      --- | --- | --- | ---
    01|Aguascalientes|001 |Aguascalientes
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
1×9 DataFrame
 Row │ lugar                     total  hombres  mujeres  porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad_poblacion  extesion_territorial
     │ String                    Int64  Int64    Int64    Float64             Float64             Float64              Float64             Float64
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Aguascalientes, Asientos  51536    25261    26275             49.0162             50.9838              3.63938             93.8709               549.009
```
"""
function poblacion_municipio(cve_entidad::String, cve_municipio::String, token_INEGI::String="")::DataFrame
  token_INEGI = token_check(token_INEGI)
     cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 
  try
    global estado = ENTIDADES[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe de ser de dos dígitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  try
    global municipio = MUNICIPIOS[cve_entidad*cve_municipio]
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
- extensión territorial (kilómetros cuadrados)
- población total hombres
- población total mujeres
- porcentaje de hombres
- porcentaje de mujeres
- porcentaje de población que se considera indígena

# Ejemplo
```julia-repl
julia> poblacion_todos_municipios()
2469×11 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre              total   densidad   hombres   mujeres   porcentaje_hombres  porcentajes_mujeres ⋯
      │ String   String          String     String                        Int64   Float64    Int64     Int64     Float64             Float64             ⋯
──────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes                797010   744.58     386429   410581.0             48.5335              51.4665 ⋯
    2 │ 01       Aguascalientes  002        Asientos                      797010   744.58     386429   410581.0             48.5335              51.4665
    ⋮   │    ⋮           ⋮             ⋮                   ⋮                   ⋮           ⋮         ⋮         ⋮              ⋮                    ⋮          ⋱
 2468 │ 32       Zacatecas       057        Trancoso                      138176   331.026     66297    71879.0             48.482               51.518  ⋯
 2469 │ 32       Zacatecas       058        Santa María de la Paz          16934    87.9192     8358     8576.0             48.962               51.038
```
"""
function poblacion_todos_municipios()::DataFrame
  path = "poblacion_municipios.csv"
  return get_info(path, [String, String, String, String, Int64, Float64, Float64, Int64, Int64, Float64, Float64, Float64, Float64])
end

"""
    poblacion_todas_entidades()::DataFrame

Regresa un `DataFrame` con los datos poblacionales de _todas_ las entidades.

- clave de entidad
- nombre oficial de la entidad
- población total
- densidad de población (habitantes por kilómetro cuadrado)
- extensión territorial (kilómetros cuadrados)
- población total hombres
- población total mujeres
- porcentaje de hombres
- porcentaje de mujeres
- porcentaje de población que se considera indígena

# Ejemplo
```julia-repl
julia> poblacion_todas_entidades()
32×10 DataFrame
 Row │ entidad  entidad_nombre     total     densidad   extension_territorial  hombres    mujeres    ⋯
     │ String   String             Int64     Float64    Float64                Int64      Int64      ⋯
─────┼───────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 01       Aguascalientes      1425607   253.862            5615.67        69668300   72892400  ⋯
   2 │ 02       Baja California     3769020    52.7505          71450.0        190058900  186843100        
   ⋮ │ ⋮             ⋮                 ⋮            ⋮           ⋮                 ⋮                      ⋱
  32 │ 32       Zacatecas           1622138    21.5494          75275.3         79105800   83108000  ⋯
```
"""
function poblacion_todas_entidades()::DataFrame
  path = "poblacion_entidades.csv"
  return get_info(path, [String, String, Int64, Float64, Float64, Int64, Int64, Float64, Float64, Float64])
end

"""
    clave(id::String)::String

Toma como parámetro el nombre de algún municipio o entidad y regresa la clave del mismo.

# Ejemplo

```julia-repl
julia> clave("Campeche")
"04"
julia> clave("Calakmul")
"010"
```
"""
function clave(id::String,prio::Bool=true)::String
  if prio == true
    if haskey(ENTIDAD_NOMBRE, id)
      return ENTIDAD_NOMBRE[id]
    end
    if haskey(MUNICIPIO_NOMBRE, id)
      return MUNICIPIO_NOMBRE[id][3:end]
    end
  else
    if haskey(MUNICIPIO_NOMBRE, id)
      return MUNICIPIO_NOMBRE[id][3:end]
    end
    if haskey(ENTIDAD_NOMBRE, id)
      return ENTIDAD_NOMBRE[id]
    end
  end
  aux = "No existe $id en los registros de entidades o estados.\n"
  ent , mun = similitud_region(id)
  ent ,mun = unique(ent), unique(mun)
  if length(ent) > 0
    aux *= "Prueba estas sugerencias: \n"
    aux *= "Entidades: \n"
  end
  for en in ent
    aux *= "\t"*en*" ➜ "*ENTIDAD_NOMBRE[en] *"\n"
  end
  if length(mun) > 0
    aux *= "Municipios: \n"
  end
  for mu in mun
    aux *= "\t"*mu*" ➜ "*MUNICIPIO_NOMBRE[mu][3:5]*"\n"
  end
  error(aux)
end

"""
    idh(cve_entidad::String, cve_municipio::String="")::DataFrame
Regresa el índice de desarrollo humano, los años promedio de escolaridad, los años esperados de escolaridad y los ingresos per cápita de una entidad o de un municipio en formato `DataFrame`, se debe especificar la clave para ambos parámetros, si solo se manda el parámetro _cve_entidad_ se regresará el IDH de la entidad. Los datos son obtenidos de la página oficial de las Naciones Unidas, se pueden consultar [aquí](https://www.mx.undp.org/content/mexico/es/home/library/poverty/idh-municipal-en-mexico--nueva-metodologia.html).
# Ejemplo
```julia-repl
julia> idh(clave("Campeche"),"003").idh*100
1-element Array{Float64,1}:
 77.50874

julia> idh(clave("Campeche"),"003").idh[1]*100
77.50874

julia> idh(clave("Campeche"),"003")
1×8 DataFrame
 Row │ ent  mun  entidad   municipio  idh       anio_promedio_escolaridad  anios_esperados_escolaridad  ingreso_per_capita 
     │ Any  Any  Any       Any        Any       Any                        Any                          Any                
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 04   003  Campeche  Carmen     0.775087  9.19528                    12.6746                      18552.8

julia> idh(clave("Campeche"))
1×3 DataFrame
 Row │ ent  ent_nombre  idh  
     │ Any  Any         Any  
─────┼───────────────────────
   1 │ 04   Campeche    0.82
```
"""
function idh(cve_entidad::String, cve_municipio::String="")::DataFrame
     cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 
  if cve_municipio == ""
    tabla = get_info("IDH_Entidad.csv",[String,String,Float64])
    try
      return filtrar(tabla,":ent == '$cve_entidad'")
    catch 
      error("No se encontro la clave $cve_entidad")
    end
  else
    tabla = get_info("IDH_Municipios.csv",[String,String,String,String,Float64,Float64,Float64,Float64])
    q1 = ":ent == '$cve_entidad'"
    q2 = ":mun == '$cve_municipio'"
    try 
      return filtrar(tabla,q1,q2)
    catch
      error("No se encontro la clave")
    end
  end
end
"""
    idh_todos_municipios()::DataFrame

Regresa un `DataFrame` con todos los valores agregados del índice de desarrollo humano de todos los municipios. Los datos son obtenidos de la página oficial de las Naciones Unidas, se pueden consultar [aquí.](https://www.mx.undp.org/content/mexico/es/home/library/poverty/idh-municipal-en-mexico--nueva-metodologia.html)

# Ejemplo
```julia-repl
julia> idh_todos_municipios()
2456×8 DataFrame
  Row │ ent     mun     entidad              municipio                     idh       anio_promedio_escolaridad  anios_esperados_escolaridad  ingreso_per_capita 
      │ String  String  String               String                        Float64   Float64                    Float64                      Float64            
──────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01      001     Aguascalientes       Aguascalientes                0.789432                    9.55307                      12.8703            17848.3
    2 │ 01      002     Aguascalientes       Asientos                      0.6615                      6.22975                      11.1364             6877.03
    3 │ 01      003     Aguascalientes       Calvillo                      0.669557                    5.95726                      10.8926             8764.94
  ⋮   │   ⋮       ⋮              ⋮                        ⋮                   ⋮                  ⋮                           ⋮                       ⋮
 2455 │ 32      057     Zacatecas            Trancoso                      0.673578                    6.24331                      10.8909             7555.7
 2456 │ 32      058     Zacatecas            Santa María de la Paz         0.668754                    5.86283                      12.143              8092.09
```
"""
function idh_todos_municipios()::DataFrame
   return get_info("IDH_Municipios.csv",[String,String,String,String,Float64,Float64,Float64,Float64])
 end

"""
    indicadores_pobreza(cve_entidad::String,cve_municipio::String)::DataFrame

Proporciona el número de personas que cumple con los indicadores de pobreza según el CONEVAL, del _municipio_ indicado.

Los datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México [datos.gob.mx](https://www.datos.gob.mx/busca/dataset/indicadores-de-pobreza-municipal-2010--2015/resource/d6d6e2a8-a2e3-4e7d-84f8-dd5ea9336671)
Consulta el [Diccionario de Datos, Indicadores de pobreza municipal (2015)](@ref)

# Ejemplo
```julia-repl
julia> df = indicadores_pobreza("01", "001")
1×20 DataFrame
  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯
      │ String   String               String     String           Int64    Int64      Int64     ⋯
──────┼────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes       001        Aguascalientes   224949      13650     211299 ⋯

```
"""
function indicadores_pobreza(cve_entidad::String,cve_municipio::String)::DataFrame
  cve_entidad, cve_municipio= check(cve_entidad,cve_municipio)
  try
    estado = ENTIDADES[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe ser de dos digitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  try
    municipio = MUNICIPIOS[cve_entidad*cve_municipio]
  catch e
    error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio '$cve_municipio' no existe.")
  end
  path = "indicadores_de_pobreza_municipal_2015_poblacion.csv"
  tabla = get_info(path, [String, String, String, String, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64, Int64])
  return filtrar(tabla, ":entidad=='$cve_entidad'", ":municipio=='$cve_municipio'")
end

"""
    indicadores_pobreza_porcentaje(cve_entidad::String,cve_municipio::String)::DataFrame

Proporciona el _porcentaje_ de personas que cumple con los indicadores de pobreza según el CONEVAL, del _municipio_ indicado.

Los datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México [datos.gob.mx](https://www.datos.gob.mx/busca/dataset/indicadores-de-pobreza-municipal-2010--2015/resource/d6d6e2a8-a2e3-4e7d-84f8-dd5ea9336671)
Consulta el [Diccionario de Datos, Indicadores de pobreza municipal (2015)](@ref)
```julia-repl
julia> df = indicadores_pobreza_porcentaje("01", "001")
1×20 DataFrame
  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯
      │ String   String               String     String           Float64  Float64    Float64   ⋯
──────┼─────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes       001        Aguascalientes      26.1        1.6       24.5 ⋯

```
"""
function indicadores_pobreza_porcentaje(cve_entidad::String,cve_municipio::String)::DataFrame
     cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 

  try
    estado = ENTIDADES[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe ser de dos digitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  try
    municipio = MUNICIPIOS[cve_entidad*cve_municipio]
  catch e
    error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio '$cve_municipio' no existe.")
  end

  path = "indicadores_de_pobreza_municipal_2015_porcentaje.csv"
  tabla = get_info(path, [String, String, String, String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64])
  return filtrar(tabla, ":entidad=='$cve_entidad'", ":municipio=='$cve_municipio'")
end

"""
    indicadores_pobreza_todos()::DataFrame

Proporciona el número de personas que cumple con los indicadores de pobreza según el CONEVAL, a nivel _nacional_ segregado por _municipios_.

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

Proporciona el _porcentaje_ de personas que cumple con los indicadores de pobreza según el CONEVAL, a nivel _nacional_ segregado por _municipios_.

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
    edad_municipios(cve_entidad::String,cve_municipio::String)::DataFrame

Da a conocer el primer y tercer cuartil, así como mediana(segundo cuartil) de las edades del municipio indicado en formato `DataFrame`.
Dichos datos de edades actualizados al año 2020 se obtuvieron de la página [INEGI.](https://www.inegi.org.mx/sistemas/Olap/Proyectos/bd/censos/cpv2020/pt.asp)
# Ejemplo
```julia-repl
julia> edad_municipios("01", "001")
1×7 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre    Q1             Q2            Q3
      │ String   String          String     String            Float64        Float64       Float64
──────┼──────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes        14           28              46
```
"""
function edad_municipios(cve_entidad::String,cve_municipio::String)::DataFrame
  cve_entidad, cve_municipio= check(cve_entidad,cve_municipio)
  try
    estado = ENTIDADES[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe ser de dos digitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  try
    municipio = MUNICIPIOS[cve_entidad*cve_municipio]
  catch e
    error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio '$cve_municipio' no existe.")
  end
    
  tabla = get_info("cuartiles_municipios_2020.csv",[String,String,String,String, Float64,Float64,Float64])
  return filtrar(tabla, ":entidad=='$cve_entidad'", ":municipio=='$cve_municipio'")
end

"""
    edad_municipios_todos()::DataFrame
Da a conocer el primer y tercer cuartil, así como mediana(segundo cuartil) de las edades, a nivel nacional segregado por municipio en formato `DataFrame`.
Dichos datos de edades actualizados al año 2020 se obtuvieron de la página [INEGI.](https://www.inegi.org.mx/sistemas/Olap/Proyectos/bd/censos/cpv2020/pt.asp)
# Ejemplo
```julia-repl
julia> edad_municipios_todos()
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
function edad_municipios_todos()::DataFrame
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
  Row │ entidad  entidad_nombre       Q1             Q2            Q3
      │ String   String                 Float64        Float64       Float64
──────┼───────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes            13           26              43
    2 │ 02       Baja California           15           28              44
    3 │ 03       Baja California Sur       14           28              43
   ⋮        ⋮             ⋮              ⋮             ⋮                ⋮
```
"""
function edad_entidades()::DataFrame
  return get_info("cuartiles_entidades_2020.csv",[String,String,Float64,Float64,Float64])
end

"""
    int_migratoria(cve_entidad::String, cve_municipio::String ="")::Float64

Devuelve el índice de intensidad migratoria del municipio indicado. En caso de omitir el parámetro `cve_municipio`, devuelve los datos de la entidad indicada.
Datos obtenidos de [aquí](https://www.datos.gob.mx/busca/dataset/indice-absoluto-de-intensidad-migratoria-mexico--estados-unidos-2000--2010).


# Ejemplo

```julia-repl
julia> int_migratoria(clave("Campeche"),"003")
0.288

julia> int_migratoria(clave("Campeche"))
0.64
```
"""
function int_migratoria(cve_entidad::String,cve_municipio::String ="")::Float64
   cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 

  q1 = ":ent == '$cve_entidad'"
  if cve_municipio == ""
    tabla = get_info("IAIM_Entidad.csv",[String,Float64])
    try
      return filtrar(tabla,":ENT == '$cve_entidad'").IAIM[1]
    catch
      error("Clave $cve_entidad no encontrada")
    end
  else
    q2 = ":mun == '$cve_municipio'"
    tabla = get_info("IAIM_Municipio.csv",[String,String,String,String,Float64])
    try
      return filtrar(tabla,q1,q2).iaim[1]
    catch
      error("Clave no encontrada")
    end
  end
end

"""
    int_migratoria_todos()::DataFrame

Regresa un `DataFrame` con los índices de intensidad migratoria de todos los municipios.
Datos obtenidos de [aquí](https://www.datos.gob.mx/busca/dataset/indice-absoluto-de-intensidad-migratoria-mexico--estados-unidos-2000--2010).

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


Devuelve un `DataFrame` con la latitud, longitud y altitud promedio del municipio indicado. En caso de omitir el parámetro `cve_municipio`, devuelve los datos de la entidad indicada. 
Datos obtenidos de [aquí](https://www.inegi.org.mx/app/ageeml/#).

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
   cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 
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
    Devuelve los datos geográficos de todos los municipios(latitud, longitud y altitud promedio), puedes consultar la información [aquí](https://www.inegi.org.mx/app/ageeml/#).

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
1×6 DataFrame
  Row │ entidad  entidad_nombre  municipio  municipio_nombre  número de códigos postales  códigos postales
      │ String   String          String     String            Int64                       String
──────┼────────────────────────────────────────────────────────────────────────────────────────────────────
    1 │ 01       Aguascalientes  001        Aguascalientes                           599  20000;20010;20010 ⋯
```
"""
function codigos_postales(cve_entidad::String, cve_municipio::String)::DataFrame

   cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 
  try
    estado = ENTIDADES[cve_entidad]
  catch e
    error("Verifica tu clave de entidad. Debe ser de dos digitos en el rango [01, 32]. cve_entidad '$cve_entidad' no existe.")
  end

  try
    municipio = MUNICIPIOS[cve_entidad*cve_municipio]
  catch e
    error("Verifica tu clave de municipio. Debe de ser de tres dígitos en el rango [001, 570]. cve_municipio '$cve_municipio' no existe.")
  end
  codigos = get_info("codigos_postales_municipios_2021.csv",[String,String,String,String,Int64,String])
  return filtrar(codigos, ":entidad=='$cve_entidad'", ":municipio=='$cve_municipio'")
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
    tasas_vitales(cve_entidad::String, cve_municipio::String="")::DataFrame

Proporciona un `DataFrame` con las tasas de natalidad, fecundidad y mortalidad del municipio indicado.
En caso de omitir el parámetro cve_municipio, se mostrarán datos de la entidad indicada.
Datos obtenidos del registro de nacimientos (2019), defunciones generales (2019) y población de mujeres en edad fértil (15-45 años, 2020) del INEGI.

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
function tasas_vitales(cve_entidad::String, cve_municipio::String="",token_INEGI="")::DataFrame
   cve_entidad, cve_municipio= check(cve_entidad,cve_municipio) 
     token_INEGI = token_check(token_INEGI)

  nacimientos = get_info("nacimientos.csv", [String, String, String, Int64])

  if(cve_municipio=="")
    localidad = poblacion_entidad(cve_entidad)
    pob_mujeres = localidad[:1, :4]

    estado = filtrar(nacimientos, ":entidad == '$cve_entidad'", ":municipio == '000'")
    nacimientos_ent = estado[:1, :4]
    if(nacimientos_ent == "")
      natalidad = 0
    else
      natalidad = nacimientos_ent/pob_mujeres
    end
  else
    localidad = poblacion_municipio(cve_entidad, cve_municipio)
    pob_mujeres = localidad[:1, :4]

    municipio = filtrar(nacimientos, ":entidad == '$cve_entidad'", ":municipio == '$cve_municipio'")
    nacimientos_muni = municipio[:1, :4]
    if(nacimientos_muni == "")
      natalidad = 0
    else
      natalidad = nacimientos_muni/pob_mujeres
    end
  end

  fertilidades = get_info("fertilidad_entidad_municipio_2020.csv", [String, String, String, Int64])

  if(cve_municipio=="")
    fertil_ent = filtrar(fertilidades, ":entidad == '$cve_entidad'", ":municipio == '000'")
    pob_fertil = fertil_ent[:1, :4]
    fecundidad = nacimientos_ent/pob_fertil
  else
    fertil_muni = filtrar(fertilidades, ":entidad == '$cve_entidad'", ":municipio == '$cve_municipio'")
    pob_fertil = fertil_muni[:1, :4]
    fecundidad = nacimientos_muni/pob_fertil
  end

  defunciones = get_info("defunciones_municipio_2019.csv", [String, String, String, Int64])

  pob_total = localidad[:1, :2]

  if(cve_municipio=="")
    estado = filtrar(nacimientos, ":entidad == '$cve_entidad'", ":municipio == '000'")
    defunciones_ent = estado[:1, :4]
    if(defunciones_ent == "")
      mortalidad = 0
    else
      mortalidad = defunciones_ent/pob_total
    end
  else
    municipio = filtrar(nacimientos, ":entidad == '$cve_entidad'", ":municipio == '$cve_municipio'")
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
  entidades_iter = collect(values(ENTIDADES))
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
  municipios_iter = collect(values(MUNICIPIOS))
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
  entidades_iter = collect(values(ENTIDADES))
  municipios_iter = collect(values(MUNICIPIOS))
  simil_entidades = colecta_similitud(id, entidades_iter)
  simil_municipio = colecta_similitud(id, municipios_iter)
  return [simil_entidades, simil_municipio]
end
function check(cve_entidad,cve_municipio)::Any
  cve_mun , cve_ent = cve_municipio, cve_entidad
  if !haskey(ENTIDADES,cve_entidad)
    cve_entidad = clave(cve_entidad)
  end
   if cve_municipio != "" && !haskey(MUNICIPIOS,cve_entidad*cve_municipio)
     cve_municipio =  clave(cve_municipio,false)
  end

  if haskey(MUNICIPIO_NOMBRE , cve_mun)
    if cve_entidad*cve_municipio != MUNICIPIO_NOMBRE[cve_mun]
      error("El municipio $(cve_mun) no pertenece la entidad $(ENTIDADES[cve_entidad]).")
    end
  end
  return (cve_entidad ,cve_municipio)
end

