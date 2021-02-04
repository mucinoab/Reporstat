push!(LOAD_PATH,"../src/")
using Pkg
Pkg.activate(".")

using Documenter, Reporstat

makedocs(
sitename = "Reporstat.jl",
format = Documenter.HTML(),
modules = [Reporstat],
pages=["Home" => "index.md",])

deploydocs(repo = "github.com/mucinoab/Reporstat.git")
