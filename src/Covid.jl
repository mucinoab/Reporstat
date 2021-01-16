push!(LOAD_PATH,"../src/")
module Covid
#include("Stats.jl") #incluimos los archivos con las funciones
include("Utils.jl")
include("Operations.jl")
# export Utils :unzip,data_check,fechahoy
# export Operations: Select
end
