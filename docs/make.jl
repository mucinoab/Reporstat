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

deploydocs(
    repo = "github.com/mucinoab/Covid.git"
)
