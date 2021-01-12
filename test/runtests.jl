#Correr este archivo para correr todos los tests
using Test

using Covid

#agregar aquí el nombre del archivo donde hagan los test de su módulo
tests = [
"utils.jl",
"select.jl"
]

for test in tests
  @testset "$test" begin
    include(test)
  end
end
