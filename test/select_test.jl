# push!(LOAD_PATH,"../src/")
include("../src/Select.jl")
using .Selects
using DataFrames,CSV
# df = DataFrame(A = 1:4, B = ["M", "F", "F", "M"], C = 1:4, D= 1:4)  

path = "cities.csv"
df = CSV.read(path,DataFrame)
name= String.(names(df))
columnas = ["4","2","5","9"]
Selects.Select(df,columnas,name)


