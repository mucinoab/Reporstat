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


# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "github.com/mucinoab/Julia-COVID.git"
)=#
