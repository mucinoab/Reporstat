var documenterSearchIndex = {"docs":
[{"location":"#Reporstat.jl","page":"Home","title":"Reporstat.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Paquete que tiene como objetivo aprovechar la información a nivel municipal del INEGI, CONAPO y CONEVAL para consolidar en un solo lugar los datos abiertos de la Secretaría de Salud sobre COVID-19 en México, junto con información relevante del municipio de residencia de cada caso.","category":"page"},{"location":"#Indice","page":"Home","title":"Indice","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"index.md\"]","category":"page"},{"location":"#Funciones","page":"Home","title":"Funciones","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Order   = [:function]","category":"page"},{"location":"#Población","page":"Home","title":"Población","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Datos proporcionados por el INEGI, actualizados al 2020 a excepción del porcentaje de población que se considera indígena, que los últimos datos  proporcionados son del 2015 y la extensión territorial que se calcula con  la densidad y población total.","category":"page"},{"location":"","page":"Home","title":"Home","text":"idh\n\ngeografia\ncodigos_postales\n\npoblacion_mexico\npoblacion_entidad\npoblacion_municipio\npoblacion_todas_entidades\npoblacion_todos_municipios","category":"page"},{"location":"#Reporstat.idh","page":"Home","title":"Reporstat.idh","text":"idh(cve_entidad::String, cve_municipio::String=\"\")::Number\n\nRegresa el indice de desarrollo humano de una entidad o de un municipio se debe especificar la clave para ambos parametros, si solo se manda el parametro cveentidad_ se regresara el idh de la entidad.Los datos son obtenidos de  la pgina oficial de las naciones unidas  puedes consultar aquí.\n\nEjemplo\n\njulia> idh(clave(\"Campeche\"),\"002\")\n0.797\njulia> idh(clave(\"Campeche\"),\"003\")\n0.775\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.geografia","page":"Home","title":"Reporstat.geografia","text":"geografia(cve_entidad::String,cve_municipio::String =\"\")::DataFrame\n\nDevuelve un DataFrame con los valores clave de entidad, clave municipal ( si es requerida ), latitud, longitud, altitud.\n\nSe pueden hacer consultas de una entidad o de un municipio.\n\njulia> geografia(clave(\"Oaxaca\"),\"003\")\n1×5 DataFrame\n Row │ ent  mun  latitud       longitud       altitud \n     │ Any  Any  Any           Any            Any     \n─────┼────────────────────────────────────────────────\n   1 │ 20   003  17°04´10.549  095°58´04.929  1486\n\njulia> geografia(clave(\"Oaxaca\"),\"003\").latitud\n1-element Array{Any,1}:\n \"17°04´10.549\"\n\njulia> geografia(clave(\"Oaxaca\"),\"003\").altitud\n1-element Array{Any,1}:\n \"1486\"\n\njulia> geografia(clave(\"Campeche\"))\n1×4 DataFrame\n Row │ ent  latitud       longitud       altitud \n     │ Any  Any           Any            Any     \n─────┼───────────────────────────────────────────\n   1 │ 04   19°01´17.138  092°27´54.859  14\n\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.codigos_postales","page":"Home","title":"Reporstat.codigos_postales","text":"codigos_postales()::DataFrame\n\nProporciona todos los códigos postales de México, segregados por municpio, en un DataFrame. Los datos son obtenidos del Servicio Postal Mexicano.\n\nEjemplo\n\njulia> codigos_postales()\n2465×6 DataFrame\n  Row │ entidad  entidad_nombre  municipio  municipio_nombre  número de códigos postales  códigos postales\n      │ String   String          String     String            Int64                       String          \n──────┼────────────────────────────────────────────────────────────────────────────────────────────────────\n    1 │ 01       Aguascalientes  001        Aguascalientes                           599  20000;20010;20010 ⋯\n    2 │ 01       Aguascalientes  002        Asientos                                  82  20700;20700;20700 ⋯\n  ⋮   │    ⋮           ⋮             ⋮                   ⋮                ⋮                               ⋮\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.poblacion_mexico","page":"Home","title":"Reporstat.poblacion_mexico","text":"poblacion_mexico(token_INEGI::String=\"\")::DataFrame\n\nRegresa un DataFrame con los datos más recientes, a nivel nacional, proporcionados por la API de Indicadores del INEGI. Requiere el token (token_INEGI) de la API, puede obtenerse aquí. Se pude proporcionar el token directamente o por medio de una variable de entorno llamada de la misma manera, token_INEGI.\n\nEjemplo\n\njulia> ENV[\"token_INEGI\"] = \"00000000-0000-0000-0000-000000000000\"\n\"00000000-0000-0000-0000-000000000000\"\n\njulia> popu = poblacion_mexico()\n1×8 DataFrame\n Row │ lugar   total      hombres    mujeres    porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad\n     │ String  Float64    Float64    Float64    Float64             Float64             Float64              Float64\n─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n   1 │ México  1.19938e8  5.48552e7  5.74813e7               48.57               51.43              21.4965   60.9642\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.poblacion_entidad","page":"Home","title":"Reporstat.poblacion_entidad","text":"poblacion_entidad(cve_entidad::String, token_INEGI::String=\"\")::poblacion\n\nRegresa un una DataFrame con los datos más recientes, por entidad federativa, proporcionados por la API de Indicadores del INEGI. Requiere el token (token_INEGI) de la API, puede obtenerse aquí. Se pude proporcionar el token directamente o por medio de una variable de entorno, de la siguiente manera. \n\njulia> ENV[\"token_INEGI\"] = \"00000000-0000-0000-0000-000000000000\"\n\nEl DataFrame resultante contiene los siguientes datos.\n\nlugar\npoblación total\ndensidad de población (habitantes por kilómetro cuadrado) \npoblación total hombres\npoblación total mujeres\nporcentaje de hombres\nporcentaje de mujeres\nporcentaje de población que se considera indígena\n\nnote: Note\nÁrea geoestadística estatal (AGEE)La entidad federativa se codifica de acuerdo con el orden alfabético de sus nombres oficiales, con una longitud de dos dígitos, a partir del 01 en adelante, según el número de entidades federativas que dispongan las leyes vigentes; en este momento son 32 entidades federativas (Aguascalientes 01, Baja California 02,... y Zacatecas 32). Las puedes consultar aquí.\n\nClave Entidad Entidad\n01 Aguascalientes\n02 Baja California\n03 Baja California Sur\n⋮ ⋮\n30 Veracruz de Ignacio de la Llave\n31 Yucatán\n32 Zacatecas\n\nEjemplo\n\njulia> popu = poblacion_entidad(\"31\", token)\n1×8 DataFrame\n Row │ lugar    total      hombres   mujeres   porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad\n     │ String   Float64    Float64   Float64   Float64             Float64             Float64              Float64\n─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────\n   1 │ Yucatán  2.10226e6  963333.0  992244.0             48.9968             51.0032              65.4035   53.0607\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.poblacion_municipio","page":"Home","title":"Reporstat.poblacion_municipio","text":"poblacion_municipio(cve_entidad::String, cve_municipio::String, token_INEGI::String=\"\")::DataFrame\n\nRegresa un DataFrame con los datos más recientes, por municipio, proporcionados por la API de Indicadores del INEGI. Requiere el token (token_INEGI) de la API, puede obtenerse aquí. Se pude proporcionar el token directamente o por medio de una variable de entorno llamada de la misma manera, token_INEGI.\n\nnote: Note\nÁrea geoestadística municipal (AGEM)La clave del municipio está formada por tres números que se asignan de manera ascendente  a  partir  del  001,  de  acuerdo  con  el  orden  alfabético  de  los  nombres  de  los  municipios,  aunque  a  los  creados  posteriormente  a  la  clavificación  inicial,  se  les  asigna  la  clave  geoestadística  conforme se vayan creando. Las puedes consultar aquí.Clave Entidad Nombre Entidad Clave Municipio Nombre Municipio\n01 Aguascalientes 001 Aguascalientes\n01 Aguascalientes 002 Asientos\n01 Aguascalientes 003 Calvillo\n⋮ ⋮ ⋮ ⋮\n32 Zacatecas 056 Zacatecas\n32 Zacatecas 057 Trancoso\n32 Zacatecas 058 Santa María de la Paz\n\nEjemplo\n\njulia> ENV[\"token_INEGI\"] = \"00000000-0000-0000-0000-000000000000\"\n\"00000000-0000-0000-0000-000000000000\"\n\njulia> popu = poblacion_municipio(\"01\", \"002\")\n1×8 DataFrame\n Row │ lugar                     total    hombres  mujeres  porcentaje_hombres  porcentaje_mujeres  porcentaje_indigena  densidad\n     │ String                    Float64  Float64  Float64  Float64             Float64             Float64              Float64\n─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n   1 │ Aguascalientes, Asientos  45492.0  22512.0  22980.0             48.9519             51.0481              3.63938   84.6325\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.poblacion_todas_entidades","page":"Home","title":"Reporstat.poblacion_todas_entidades","text":"poblacion_todas_entidades()::DataFrame\n\nRegresa un DataFrame con los datos poblacionales de todas las entidades.\n\nclave de entidad \nnombre oficial de la entidad\npoblación total\ndensidad de población (habitantes por kilómetro cuadrado) \npoblación total hombres\npoblación total mujeres\nporcentaje de hombres\nporcentaje de mujeres\nporcentaje de población que se considera indígena\n\nEjemplo\n\njulia> poblacion_todas_entidades()\n32×9 DataFrame\n Row │ entidad  entidad_nombre     total         densidad    hombres         mujeres         porcentaje_hombres ⋯\n     │ String   String             Float64       Float64     Float64         Float64         Float64            ⋯\n─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────── \n   1 │ 01       Aguascalientes      1.185e6     233.729    576638.0        608358.0           48.7672 ⋯\n   2 │ 02       Baja California     3.15507e6    46.4066        1.59161e6       1.56346e6     49.7725 \n   ⋮ │ ⋮             ⋮               ⋮               ⋮            ⋮           ⋮                 ⋮      \n  32 │ 32       Zacatecas           1.49067e6    20.9791   726897.0        763771.0           48.7819\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.poblacion_todos_municipios","page":"Home","title":"Reporstat.poblacion_todos_municipios","text":"poblacion_todos_municipios()::DataFrame\n\nRegresa un DataFrame con los datos poblacionales de todos los municipios.\n\nnombre del lugar\nclave de entidad \nnombre de la entidad\nclave de municipio\nnombre de municipio\npoblación total\ndensidad de población (habitantes por kilómetro cuadrado) \npoblación total hombres\npoblación total mujeres\nporcentaje de hombres\nporcentaje de mujeres\nporcentaje de población que se considera indígena\n\nEjemplo\n\njulia> poblacion_todos_municipios()\n2469×11 DataFrame\n  Row │ entidad  entidad_nombre  municipio  municipio_nombre              total     densidad   hombres   mujeres   porcentaje_hombres  porcentajes_mujeres ⋯\n      │ String   String          String     String                        Float64   Float64    Float64   Float64   Float64             Float64             ⋯\n──────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n    1 │ 01       Aguascalientes  001        Aguascalientes                797010.0  744.58     386429.0  410581.0             48.5335              51.4665 ⋯\n    2 │ 01       Aguascalientes  002        Asientos                      797010.0  744.58     386429.0  410581.0             48.5335              51.4665 \n    ⋮   │    ⋮           ⋮             ⋮                   ⋮                   ⋮          ⋮         ⋮         ⋮              ⋮                    ⋮          ⋱\n 2468 │ 32       Zacatecas       057        Trancoso                      138176.0  331.026     66297.0   71879.0             48.482               51.518  ⋯\n 2469 │ 32       Zacatecas       058        Santa María de la Paz          16934.0   87.9192     8358.0    8576.0             48.962               51.038  \n\n\n\n\n\n","category":"function"},{"location":"#Indicadores-de-Pobreza","page":"Home","title":"Indicadores de Pobreza","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Datos proporcionados por el Consejo Nacional de Evaluación de la Política de Desarrollo Social, actualizados al año 2015.","category":"page"},{"location":"#Diccionario-de-Datos,-Indicadores-de-pobreza-municipal-(2015)","page":"Home","title":"Diccionario de Datos, Indicadores de pobreza municipal (2015)","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Abreviación Significado\npobreza Población en situación de pobreza\npobreza_e Población en situación de pobreza extrema\npobreza_m Población en situación de pobreza moderada\nvul_car Población vulnerable por carencias\nvul_ing Población vulnerable por ingreso\nnpnv Población no pobre y no vulnerable\nic_rezedu Población con rezago educativo\nic_asalud Población con carencia por acceso a los servicios de salud\nic_segsoc Población con carencia por acceso a la seguridad social\nic_cv Población con carencia por calidad y espacios en la vivienda\nic_sbv Población con carencia por acceso a los servicios básicos en la vivienda\nic_ali Población con carencia por acceso a la alimentación\ncarencias Población con al menos una carencia social\ncarencias3 Población con al menos tres carencias sociales\nplb Población con ingreso inferior a la línea de bienestar\nplbm Población con ingreso inferior a la línea de bienestar mínimo","category":"page"},{"location":"","page":"Home","title":"Home","text":"indicadores_pobreza\nindicadores_pobreza_porcentaje","category":"page"},{"location":"#Reporstat.indicadores_pobreza","page":"Home","title":"Reporstat.indicadores_pobreza","text":"indicadores_pobreza()::DataFrame\n\nProporciona el número de personas que cumple con los indicadores de pobreza según el CONEVAL, a nivel municipal. \n\nLos datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México datos.gob.mx Consulta el Diccionario de Datos, Indicadores de pobreza municipal (2015)\n\njulia> df = indicadores_pobreza() \n2457×20 DataFrame\n  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯\n      │ String   String               String     String           Int64    Int64      Int64     ⋯\n──────┼────────────────────────────────────────────────────────────────────────────────────────\n    1 │ 01       Aguascalientes       001        Aguascalientes   224949      13650     211299 ⋯\n    2 │ 01       Aguascalientes       002        Asientos          25169       2067      23101 ⋯\n   ⋮  │ ⋮             ⋮               ⋮               ⋮            ⋮            ⋮          ⋮   \n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.indicadores_pobreza_porcentaje","page":"Home","title":"Reporstat.indicadores_pobreza_porcentaje","text":"indicadores_pobreza_porcentaje()::DataFrame\n\nProporciona el porcentaje de personas que cumple con los indicadores de pobreza según el CONEVAL, a nivel municipal.\n\nLos datos son obtenidos de la página oficial de datos abiertos del gobierno federal de México datos.gob.mx Consulta el Diccionario de Datos, Indicadores de pobreza municipal (2015)\n\njulia> df = indicadores_pobreza_porcentaje() \n2457×20 DataFrame\n  Row │ entidad  entidad_nombre       municipio  municipio_nombre pobreza  pobreza_e  pobreza_m ⋯\n      │ String   String               String     String           Float64  Float64    Float64   ⋯\n──────┼─────────────────────────────────────────────────────────────────────────────────────────\n    1 │ 01       Aguascalientes       001        Aguascalientes      26.1        1.6       24.5 ⋯\n    2 │ 01       Aguascalientes       002        Asientos            54.0        4.4       49.5 ⋯\n   ⋮  │ ⋮             ⋮               ⋮               ⋮            ⋮            ⋮          ⋮    \n\n\n\n\n\n","category":"function"},{"location":"#Utilidades","page":"Home","title":"Utilidades","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Utilidades varias que tienen como objetivo facilitar la manipulación de archivos CSV, DataFrames, entre otras.","category":"page"},{"location":"","page":"Home","title":"Home","text":"clave\n\ncargar_csv\ncsv_a_DataFrame\n\nunzip\njsonparse\n\nfechahoy\n\nfiltrar\nseleccionar\n\ncontar_renglones\nsumar_columna\nsumar_fila","category":"page"},{"location":"#Reporstat.clave","page":"Home","title":"Reporstat.clave","text":"clave(id::String)::String\n\nToma como parámetro el nombre de algún municipio o entidad y regresa la clave de este.\n\nEjemplo\n\njulia> clave(\"Campeche\")\n\"04\"\njulia> clave(\"Calakmul\")\n\"010\"\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.cargar_csv","page":"Home","title":"Reporstat.cargar_csv","text":"cargar_csv(path_url::String, type::String=\"PATH\", encoding::String=\"UTF-8\")::DataFrame\n\nCrea un DataFrame dado un archivo CSV o una liga al archivo. Se pude especificar el encoding.\n\nEjemplo\n\njulia> url = \"http://www.conapo.gob.mx/work/models/OMI/Datos_Abiertos/DA_IAIM/IAIM_Municipio_2010.csv\"\njulia> first(cargar_csv(url, \"URL\", \"LATIN1\"))\njulia> first(cargar_csv(\"prueba.csv\"))\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.csv_a_DataFrame","page":"Home","title":"Reporstat.csv_a_DataFrame","text":"csv_a_DataFrame(path_url::String, encoding::String=\"UTF-8\")::DataFrame\n\nLee un archivo CSV con el encoding indicado y regresa un DataFrame.\n\nEjemplo\n\njulia> df = DataFrameEncode(\"datos.csv\")\njulia> df_latin1 = DataFrameEncode(\"datos.csv\", \"LATIN1\")\n\nLos encodings soportados dependen de la plataforma, obtén la lista de la siguiente manera.\n\njulia> using StringEncodings\njulia> encodings()\n\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.unzip","page":"Home","title":"Reporstat.unzip","text":"unzip(path::String, dest::String=\"\")\n\nDescomprime y guarda el archivo en el destino indicado(dest), si no se proporciona un destino, se guarda en el directorio actual.\n\nEjemplo\n\njulia> unzip(\"datos.zip\")\njulia> unzip(\"datos.zip\", pwd()*\"/datos\")\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.jsonparse","page":"Home","title":"Reporstat.jsonparse","text":"jsonparse(url::String)::Dict\n\nHace un http request al url especificado y convierte el json obtenido del sitio web en un diccionario. En caso de que el servidor devuelva un status distinto a 200, se arroja un error.\n\nEjemplo\n\njulia> datos = jsonparse(\"https://sitioweb.com/datos.json\")\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.fechahoy","page":"Home","title":"Reporstat.fechahoy","text":"fechahoy()::String\n\nCrea un string con la fecha de hoy utilizando el formato \"yyyymmdd\". Año con cuarto dígitos, mes y día con dos.\n\nEjemplo\n\njulia> fechahoy()\n\"20210112\"\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.filtrar","page":"Home","title":"Reporstat.filtrar","text":"filtrar(tabla::DataFrame, condiciones...)::DataFrame\n\nFiltra un DataFrame de acuerdo a los parámetros que sean pasados, en este caso los parámetros actúan como expresiones, los nombres de las columnas deben siempre tener el prefijo : , y puede ser especificada por nombre o por numero de columna.\n\nEjemplo\n\njulia> dt= DataFrame(A = [1,2,2,3],B = [\"A\",\"A\",\"B\",\"BB\"])\n4×2 DataFrame\n Row │ A      B      \n     │ Int32  String \n─────┼───────────────\n   1 │     1  A\n   2 │     2  A\n   3 │     2  B\n   4 │     3  BB\n\njulia> Filtrar(dt, \":1 == 2\")\n2×2 DataFrame\n Row │ A    B   \n     │ Any  Any \n─────┼──────────\n   1 │ 2    A\n   2 │ 2    B\n\nEn caso de que se trate de una string se deben siempre encerrar entre comillas simples.\n\njulia> Filtrar(dt, \"'A' == :2\")\n2×2 DataFrame\n Row │ A    B   \n     │ Any  Any \n─────┼──────────\n   1 │ 1    A\n   2 │ 2    A\n\nLas condiciones se deben poner en parametros diferentes.\n\njulia> Filtrar(dt, \"2 == :A\" , \"'A'== :B\")\n1×2 DataFrame\n Row │ A    B   \n     │ Any  Any \n─────┼──────────\n   1 │ 2    A\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.seleccionar","page":"Home","title":"Reporstat.seleccionar","text":"seleccionar(Tabla::DataFrame, query::Vector{String})::DataFrame\n\nSelecciona una o varias columnas del DataFrame puede ser por nombre o por número de columna y regresa un nuevo DataFrame con las columnas seleccionadas.\n\nEjemplo\n\n\njulia> tabla = DataFrame(A = 1:3, B= 1:3)\n3×2 DataFrame\n Row │ A      B\n     │ Int32  Int32\n─────┼──────────────\n   1 │     1      1\n   2 │     2      2\n   3 │     3      3\n\njulia> q1 = seleccionar(tabla,[\"1\"])\n3×1 DataFrame\n Row │ A\n     │ Int32\n─────┼───────\n   1 │     1\n   2 │     2\n   3 │     3\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.contar_renglones","page":"Home","title":"Reporstat.contar_renglones","text":"contar_renglones(tabla::DataFrame, condiciones...)::Number\n\nLlama internamente a la función Reporstat.filtrar con los mismos argumentos y regresa el numero de renglones que tiene el DataFrame que retorna  Reporstat.filtrar\n\nEjemplo\n\njulia> dt\n4×2 DataFrame\n Row │ A      B      \n     │ Int32  String \n─────┼───────────────\n   1 │     1  A\n   2 │     2  A\n   3 │     2  B\n   4 │     3  BB\n\njulia> Filtrar(dt, \"2 == :A\" , \"'A'== :B\")\n1×2 DataFrame\n Row │ A    B   \n     │ Any  Any \n─────┼──────────\n   1 │ 2    A\n\njulia> contar_renglones(dt, \"2 == :A\" , \"'A'== :B\")\n1\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.sumar_columna","page":"Home","title":"Reporstat.sumar_columna","text":"sumar_columna(tabla::DataFrame, col::Int)::Number\nsumar_columna(tabla::DataFrame, col::String)::Number\n\nSuma todos los valores de una determinada columna en un DataFrame. Para hacer referencia a que columna se desea sumar se pude usar la posición de la columna o el nombre que tiene.\n\nEjemplo\n\njulia> df = cargar_csv(\"datos.csv\")\n4×2 DataFrame\n Row │ x      y\n     │ Int64  Int64\n─────┼──────────────\n   1 │     0     11\n   2 │     2     12\n   3 │     0     13\n   4 │    40     14\n\njulia> sumar_columna(df, 1)\n42\n\njulia> sumar_columna(df, \"x\")\n42\n\n\n\n\n\n","category":"function"},{"location":"#Reporstat.sumar_fila","page":"Home","title":"Reporstat.sumar_fila","text":"sumar_fila(tabla::DataFrame, fila::Int)::Number\n\nSuma todos los valores de una determinada fila en un DataFrame. La fila se especifica con la posición en la que se encuentra.\n\nEjemplo\n\njulia> df = cargar_csv(\"datos.csv\")\n4×2 DataFrame\n Row │ x      y\n     │ Int64  Int64\n─────┼──────────────\n   1 │     0     11\n   2 │     2     12\n   3 │     0     13\n   4 │    40     14\n\njulia> sumar_fila(df, 2)\n14\n\njulia> sumar_fila(df, 4)\n54\n\n\n\n\n\n","category":"function"}]
}
