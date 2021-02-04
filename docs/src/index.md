# Reporstat.jl

Paquete que tiene como objetivo aprovechar la información a nivel municipal del INEGI, CONAPO y CONEVAL para consolidar en un solo lugar los datos abiertos de la Secretaría de Salud sobre COVID-19 en México, junto con información relevante del municipio de residencia de cada caso.

## Indice
```@contents
Pages = ["index.md"]
```

## Funciones
```@index
Order   = [:function]
```

## Población

Datos proporcionados por el INEGI, actualizados al 2020 a excepción del
porcentaje de población que se considera indígena, que los últimos datos 
proporcionados son del 2015 y la extensión territorial que se calcula con 
la densidad y población total.

```@docs
idh

int_migratoria
int_migratoria_todos

edad_entidades
edad_municipios

tasas_vitales

geografia
geografia_todos_municipios

codigos_postales
codigos_postales_todos

poblacion_mexico
poblacion_entidad
poblacion_municipio
poblacion_todas_entidades
poblacion_todos_municipios

similitud_region
similitud_entidad
similitud_municipio
```

## Indicadores de Pobreza 
Datos proporcionados por el Consejo Nacional de Evaluación de la Política de Desarrollo Social, actualizados al año 2015.

### Diccionario de Datos, Indicadores de pobreza municipal (2015)

|Abreviación| Significado            |
|     :---  |     :---               |
|pobreza    | Población en situación de pobreza|
|pobreza_e  | Población en situación de pobreza extrema|
|pobreza_m  | Población en situación de pobreza moderada|
|vul_car    | Población vulnerable por carencias|
|vul_ing    | Población vulnerable por ingreso|
|npnv       | Población no pobre y no vulnerable|
|ic_rezedu  | Población con rezago educativo|
|ic_asalud  | Población con carencia por acceso a los servicios de salud|
|ic_segsoc  | Población con carencia por acceso a la seguridad social|
|ic_cv      | Población con carencia por calidad y espacios en la vivienda|
|ic_sbv     | Población con carencia por acceso a los servicios básicos en la vivienda|
|ic_ali     | Población con carencia por acceso a la alimentación|
|carencias  | Población con al menos una carencia social|
|carencias3 | Población con al menos tres carencias sociales|
|plb        | Población con ingreso inferior a la línea de bienestar|
|plbm       | Población con ingreso inferior a la línea de bienestar mínimo|

```@docs
indicadores_pobreza
indicadores_pobreza_porcentaje
indicadores_pobreza_todos
indicadores_pobreza_porcentaje_todos
```

## Utilidades

Utilidades varias que tienen como objetivo facilitar la manipulación de
archivos CSV, DataFrames, entre otras.

```@docs
clave

cargar_csv
csv_a_DataFrame

unzip
jsonparse

fechahoy

filtrar
seleccionar

contar_renglones
sumar_columna
sumar_fila
```
