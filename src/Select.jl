push!(LOAD_PATH,"../src/")
module Selects
using DataFrames
export Select
  function Select(Tabla::DataFrame,query::Vector{String}, nombres_de_columnas::Vector{String} ,Formato::String)::DataFrame
    #las columnas no se pueden repetir 
    #
    #caso base por si las listas CSV no tienen header
    #
    #Checar si la columna esta repetida o no
    checker = Dict()

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
    q1 = select(Tabla, Not(query_inversa))
    # print(q1)
    return q1
  end
end
