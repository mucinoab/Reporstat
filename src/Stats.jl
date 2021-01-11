# module Stat
# using lectura
# Tabla::DataFrame 
# numero= "23"
using DataFrames
 push!(LOAD_PATH,"../src/") #eso es por si Julia no encuentra el ./src
Tabla = DataFrame()
function Stats(Path::String,Tipo::String,Formato="csv")
	# global Tabla = lectura.lecturas(Path,Tipo,Formato)
end
function consulta(queries::Vector{String})
	print(numero)
end
