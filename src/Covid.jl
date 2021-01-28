push!(LOAD_PATH,"../src/")
module Covid

#include("Stats.jl") #incluimos los archivos con las funciones
include("Filter.jl")
include("Utils.jl")
include("Operations.jl")
end
