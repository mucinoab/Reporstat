# Covid.jl

Paquete que tiene como objetivo aprovechar la información a nivel municipal del INEGI, CONAPO y CONEVAL para consolidar en un solo lugar los datos abiertos de la Secretaría de Salud sobre COVID-19 en México, junto con información relevante del municipio de residencia de cada caso.

## Indice
```@contents
Pages = ["index.md"]
```

## Funciones
```@index
Order   = [:function]
```

## INEGI
```@docs
poblacion_mexico
poblacion_entidad
poblacion_municipio
poblacion_todos_entidades
poblacion_todos_municipios
```

## Utilidades
```@docs
data_check
CSV_to_DataFrame

unzip
jsonparse

fechahoy

filtrar
seleccionar

contar_renglones
sumacolumna
sumafila
```
