using DataFrames
mutable struct tokens 
  literal::Any
  operador::String
  col::Any
  izq::String
  der::String
end
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
function Filtrar(tabla::DataFrame, condiciones...)::DataFrame
  condiciones = collect(condiciones)
  if length(condiciones) == 0
    return tabla
  end
  #los nombres de las colmnas 
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
  print(ans)
  return DataFrame()
end


function matcher(input::String)
  # input = ":col != 90"
  operadores_expr= r">=|<=|={2}|>{1}|<{1}|!="
  col_expr= r":[A-Za-z0-9]++"
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
      global literal = expr.match    
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

