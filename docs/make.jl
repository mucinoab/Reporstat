push!(LOAD_PATH,"../src/") #eso es por si Julia no encuentra el ./src
using Pkg
Pkg.activate(".")

using Documenter, Reporstat

makedocs(
    sitename = "Reporstat.jl",
    format = Documenter.HTML(),
    modules = [Reporstat],
    pages=[
           "Home" => "index.md",
          ])
#aqui esta la informacion general de la pagina
deploydocs(
    repo = "github.com/mucinoab/Reporstat.git"
)
