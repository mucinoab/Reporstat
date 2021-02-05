push!(LOAD_PATH,"../src/")
using DataFrames,CSV
export seleccionar, filtrar, contar_renglones, unzip, cargar_csv, fechahoy, sumar_columna, sumar_fila,csv_a_DataFrame, jsonparse
"""
    seleccionar(Tabla::DataFrame, query::Vector{String})::DataFrame

Selecciona una o varias columnas del `DataFrame` puede ser por nombre o por número de columna y regresa un nuevo `DataFrame` con las columnas seleccionadas.

# Ejemplo
```julia-repl

julia> tabla = DataFrame(A = 1:3, B= 1:3)
3×2 DataFrame
 Row │ A      B
     │ Int32  Int32
─────┼──────────────
   1 │     1      1
   2 │     2      2
   3 │     3      3

julia> q1 = seleccionar(tabla,["1"])
3×1 DataFrame
 Row │ A
     │ Int32
─────┼───────
   1 │     1
   2 │     2
   3 │     3
```
"""
function seleccionar(Tabla::DataFrame,query::Vector{String})::DataFrame
  #las columnas no se pueden repetir
  #
  #caso base por si las listas CSV no tienen header
  #
  #Checar si la columna esta repetida o no
  checker = Dict()
  nombres_de_columnas = names(Tabla)
  # Procesar query
  for (indice,nombre_columna) in enumerate(query) # supongan que "1" es el nombre de la column      a
    idx = 0
    if !(nombre_columna in nombres_de_columnas)
      try
        idx = parse(Int32,nombre_columna)
      catch
        error("$nombre_columna no esta en al archivo CSV")
      end
      if idx > length(nombres_de_columnas)
        error("$idx esta fuera del rango de columnas: rango = 1-$(length(nombres_de_columnas))")
      else
        query[indice] = nombres_de_columnas[idx]
      end
    end
  end
  for nombre_columna in query
    #Checar si la columna esta en la tabla
    if !(nombre_columna in nombres_de_columnas)
      error("$nombre_columna no se encuentra en el archivo CSV")
    end
    #Checar si la columna esta repetida
    if haskey(checker , nombre_columna)
      error("Columna $nombre_columna repetida")
    else
      push!(checker, nombre_columna => 1)
    end
  end
  query_inversa= Vector{String}()
  for nombre_columna in nombres_de_columnas
    if !(nombre_columna in query)
      push!(query_inversa,nombre_columna)
    end
  end
  aux = Tabla
  q1 = select(Tabla, Not(query_inversa))
  return q1
end
# """
# formato(tabla::DataFrame, formato="latex", copiar= true)::Any

# Regresa una String con la tablANDREAa en el formato especificado, puede ser ``\\LaTeX`` o `markdown`, tambien se puede especificar si la string de regreso se copia al portapapeles por medio del parametro copiar, por default esta habilitado.
# ```julia-repl
# julia> formato(dt,"latex")
# "\\begin{tabular}{cc}
# A & B\\\\
# 1 & 1\\\\
# 2 & 2\\\\
# 3 & 3\\\\
# \\end{tabular}
# "

# julia> formato(dt,"md",false)
# A B
# – –
# 1 1
# 2 2
# 3 3
# ```
# """
# function formato(tabla::DataFrame, formato="latex", copiar= true)::Any
# copy_to_clipboard(copiar)
# if formato == "latex"
# return latexify(tabla,env=:table,latex=false)
# elseif formato == "md"
# return mdtable(tabla,latex=false)
# end
# end


mutable struct tokens
  literal::Any
  operador::String
  col::Any
  izq::String
der::String end

function evaluador(operador::String , izq::Any, der::Any)
  if operador == ">="
    return izq >= der
  end
  if operador == "<="
    return izq <= der
  end
  if operador == "=="
    return izq == der
  end
  if operador == "!="
    return izq != der
  end
  if operador == ">"
    return izq > der
  end
  if operador == "<"
    return izq < der
  end
end
"""
    filtrar(tabla::DataFrame, condiciones...)::DataFrame

Filtra un `DataFrame` de acuerdo a las condiciones indicadas en los parametros (los parámetros actúan como expresiones). Los nombres de las columnas deben siempre tener el prefijo `:` , y puede ser especificada por nombre o por numero de columna.
# Ejemplo
```julia-repl
julia> dt= DataFrame(A = [1,2,2,3],B = ["A","A","B","BB"])
4×2 DataFrame
 Row │ A      B
     │ Int32  String
─────┼───────────────
   1 │     1  A
   2 │     2  A
   3 │     2  B
   4 │     3  BB

julia> filtrar(dt, ":1 == 2")
2×2 DataFrame
 Row │ A    B
     │ Any  Any
─────┼──────────
   1 │ 2    A
   2 │ 2    B
```
En caso de que se trate de una string se deben siempre encerrar entre comillas simples.

```julia-repl
julia> filtrar(dt, "'A' == :2")
2×2 DataFrame
 Row │ A    B
     │ Any  Any
─────┼──────────
   1 │ 1    A
   2 │ 2    A
```
Las condiciones se deben poner en parámetros diferentes.

```julia-repl
julia> filtrar(dt, "2 == :A" , "'A'== :B")
1×2 DataFrame
 Row │ A    B
     │ Any  Any
─────┼──────────
   1 │ 2    A
```
"""
function filtrar(tabla::DataFrame, condiciones...)::DataFrame
  aux = collect(condiciones)
  condiciones = []
  for cond in aux
    if isa(cond,Tuple)
      v = collect(cond)
      condiciones = cat(condiciones,v,dims= (1,1))
    else
      push!(condiciones, cond)
    end
  end

  if length(condiciones) == 0
    return tabla
  end
  #los nombres de las columnas
  nombres_columnas = names(tabla)
  posicion_columnas = Dict()
  # para poder acceder por medio del numero de la columna a la columna
  for (idx,nombre_columna) in enumerate(nombres_columnas)
    push!(posicion_columnas, nombre_columna => idx)
  end
  tokens_arr= []
  for (idx , condicion) in enumerate(condiciones )
    data = matcher(condicion)  #
    if data.col in nombres_columnas
      data.col = posicion_columnas[data.col]
    else
      try
        data.col = parse(Int32,data.col)
      catch
        error("$(data.col) no existe en la tabla")
      end
      if length(nombres_columnas) < data.col
        error("$(data.col) fuera de rango ")
      end
    end
    push!(tokens_arr,data)
  end
  #iterar sobre la tabla
  ans = DataFrame()
  for nombre in nombres_columnas
    ans[:,nombre] = []
  end
  for renglon in eachrow(tabla)
    ban = true
    for tokens in tokens_arr
      aux = renglon[tokens.col]
      if tokens.der == "literal"
        if !evaluador(tokens.operador, aux,tokens.literal)
          ban = false
          break
        end
      else
        if !evaluador(tokens.operador, tokens.literal, aux)
          ban = false
          break
        end
      end
    end
    if ban
      push!(ans,renglon)
    end
  end
  return ans
end
function matcher(input::String)
  # input = ":col != 90"
  operadores_expr= r">=|<=|={2}|>{1}|<{1}|!="
  col_expr= r":[^\s]++"
  string_expr = r"'.*'"
  numero_expr  = r"[+-]?((\d+\.?\d*)|(\.\d+))"
  izquierdo = "izq"
  derecha = ""
  izquierda =""
  columna = ""
  literal = ""
  operador = match(operadores_expr, input)
  operadores_reales =["==","<=","!=",">=",">","<"]
  if operador === nothing
    error("No hay operador")
  end
  args = split(input, operador.match)
  if !(operador.match in operadores_reales)
    error("No hay operador")
  end

  if (local columna_reg = match( col_expr,args[1][1:end])) !== nothing
    global columna = columna_reg.match
    if (local expr = match(string_expr,args[2]) ) !== nothing
      global literal = expr.match[2:end-1]
    else
      if (local expr = match(numero_expr,args[2]))  !== nothing
        global literal = parse(Float64,String(expr.match))
      end
    end
    global derecha = "literal"
    global izquierda = "columna"
  elseif (local columna_reg = match( col_expr,args[2][1:end])) !== nothing
    global columna = columna_reg.match
    if (local expr = match(string_expr,args[1]) ) !== nothing
      global literal = expr.match[2:end-1]
    else
      if (local expr = match(numero_expr,args[1]))  !== nothing
        global literal = parse(Float64,expr.match)
      end
    end
    global izquierda = "literal"
    global derecha = "columna"
  else
    error("No hay columna")
  end
  return tokens(literal,"$(operador.match)", "$(columna[2:end])","$izquierda","$derecha")
end


"""
    contar_renglones(tabla::DataFrame, condiciones...)::Number

Llama internamente a la función [`Reporstat.filtrar`](@ref Reporstat.filtrar) con los mismos argumentos y regresa el número de renglones que tiene el `DataFrame` que retorna  [`Reporstat.filtrar`](@ref Reporstat.filtrar)
# Ejemplo

```julia-repl
julia> dt
4×2 DataFrame
 Row │ A      B
     │ Int32  String
─────┼───────────────
   1 │     1  A
   2 │     2  A
   3 │     2  B
   4 │     3  BB

julia> filtrar(dt, "2 == :A" , "'A'== :B")
1×2 DataFrame
 Row │ A    B
     │ Any  Any
─────┼──────────
   1 │ 2    A

julia> contar_renglones(dt, "2 == :A" , "'A'== :B")
1
```
"""
function contar_renglones(tabla::DataFrame, condiciones...)::Number
  return nrow(filtrar(tabla, condiciones))
end

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
    csv_a_DataFrame(path_url::String, encoding::String="UTF-8")::DataFrame

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
function csv_a_DataFrame(path::String, encoding::String="UTF-8")
  f = open(path, "r")
  s = StringDecoder(f, encoding, "UTF-8")
  data = DataFrame(CSV.File(s))
  close(s)
  close(f)
  return data
end


"""
    cargar_csv(path_url::String, type::String="PATH", encoding::String="UTF-8")::DataFrame

Crea un `DataFrame` dado un archivo CSV o una liga al archivo.
Se pude especificar el _encoding_.

# Ejemplo
```julia-repl
julia> url = "http://www.conapo.gob.mx/work/models/OMI/Datos_Abiertos/DA_IAIM/IAIM_Municipio_2010.csv"
julia> first(cargar_csv(url, "URL", "LATIN1"))
julia> first(cargar_csv("prueba.csv"))
```
"""
function cargar_csv(path_url::String, type::String="PATH", encoding::String="UTF-8")::DataFrame
  if type == "PATH"
    return csv_a_DataFrame(path_url, encoding)
  elseif type == "URL"
    path = HTTP.download(path_url, pwd())
    return csv_a_DataFrame(path, encoding)
  else
    error("'type' debe de ser 'PATH' o 'URL'")
  end
end

"""
    sumar_columna(tabla::DataFrame, col::Int)::Number
    sumar_columna(tabla::DataFrame, col::String)::Number

Suma todos los valores de una determinada columna en un `DataFrame`.
Para hacer referencia a que columna se desea sumar se pude usar la posición de la columna o el nombre que tiene.

# Ejemplo
```julia-repl
julia> df = cargar_csv("datos.csv")
4×2 DataFrame
 Row │ x      y
     │ Int64  Int64
─────┼──────────────
   1 │     0     11
   2 │     2     12
   3 │     0     13
   4 │    40     14

julia> sumar_columna(df, 1)
42

julia> sumar_columna(df, "x")
42
```
"""
function sumar_columna(tabla::DataFrame, col)::Number
  return sum(eachcol(tabla)[col])
end


"""
    sumar_fila(tabla::DataFrame, fila::Int)::Number

Suma todos los valores de una determinada fila en un `DataFrame`.
La fila se especifica con la posición en la que se encuentra.

# Ejemplo
```julia-repl
julia> df = cargar_csv("datos.csv")
4×2 DataFrame
 Row │ x      y
     │ Int64  Int64
─────┼──────────────
   1 │     0     11
   2 │     2     12
   3 │     0     13
   4 │    40     14

julia> sumar_fila(df, 2)
14

julia> sumar_fila(df, 4)
54
```
"""
function sumar_fila(tabla::DataFrame, fila::Int)::Number
  return sum(eachrow(tabla)[fila])
end

"""
    jsonparse(url::String)::Dict

Del `url` indicado,convierte el `json` obtenido del sitio web en un diccionario.
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

function get_info(path::String,tipos=[])::DataFrame
  if !isfile(path)
    path = HTTP.download("https://raw.githubusercontent.com/mucinoab/mucinoab.github.io/dev/extras/$path", pwd())
  end
  if length(tipos) > 0
    return DataFrame(CSV.File(path,types=tipos))
  else
    return DataFrame(CSV.File(path))
  end
end
