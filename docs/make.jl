push!(LOAD_PATH,"../src/") #eso es por si Julia no encuentra el ./src
using Pkg
Pkg.activate(".")

using Documenter, Covid

makedocs(
    sitename = "Covid",
    format = Documenter.HTML(),
    modules = [Covid],
    pages=[
           "Home" => "index.md"
          ])
#aqui esta la informacion general de la pagina
deploydocs(
    repo = "github.com/mucinoab/Covid.git"
)
