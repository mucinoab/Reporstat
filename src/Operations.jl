push!(LOAD_PATH,"../src/")
using DataFrames, Latexify
 export Select,formato
"""
    Select(Tabla::DataFrame,query::Vector{String})::DataFrame

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

julia> q1 = Select(tabla,["1"])
3×1 DataFrame
 Row │ A
     │ Int32
─────┼───────
   1 │     1
   2 │     2
   3 │     3
```
"""
  function Select(Tabla::DataFrame,query::Vector{String})::DataFrame
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
        error("$x no se encuentra en el archivo CSV")
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
    q1 = select!(Tabla, Not(query_inversa))
    # print(q1)
    return q1
  end
"""
    formato(tabla::DataFrame, formato="latex", copiar= true)::Any

Regresa una String con la tabla en el formato especificado, puede ser ``\\LaTeX`` o `markdown`, tambien se puede especificar si la string de regreso se copia al portapapeles por medio del parametro copiar, por default esta habilitado.
```julia-repl
julia> formato(dt,"latex")
"\\begin{tabular}{cc}
A & B\\\\
1 & 1\\\\
2 & 2\\\\
3 & 3\\\\
\\end{tabular}
"

julia> formato(dt,"md",false)
A B
– –
1 1
2 2
3 3
```
"""
function formato(tabla::DataFrame, formato="latex", copiar= true)::Any
  copy_to_clipboard(copiar)
  if formato == "latex"
    return latexify(tabla,env=:table,latex=false)
  elseif formato == "md"
    return mdtable(tabla,latex=false)
  end
end
