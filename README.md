# Datajam 2026 — Pitagóricas Pitonisas
**Bogotá Datajam: Uso y Aprovechamiento de Datos (Edición 2) - 2026**

---

## Descripción del problema abordado

En Bogotá se observan desigualdades en los resultados Saber 11 asociadas a condiciones adversas del entorno escolar (como el índice de violencia, el índice de factores de riesgo relacionados con seguridad, y las tasas de deserción y reprobación agregadas por localidad) que afectan a estudiantes de educación media de colegios oficiales durante el año 2024.

Este análisis examina si las características y recursos internos de las sedes educativas (disponibilidad de personal, tipo de jornada, dedicación horaria y dotación TIC) pueden amortiguar el efecto de dichos factores de riesgo sobre el desempeño académico medido por el puntaje global Saber 11.

**Pregunta de investigación:** ¿En qué medida las características institucionales de las sedes educativas moderan el efecto de las condiciones territoriales del entorno sobre el desempeño de los colegios oficiales de Bogotá en las pruebas Saber 11 (2024)?

---

## Fuentes de datos utilizadas

| # | Fuente | Descripción | Enlace |
|---|---|---|---|
| 1 | DANE — Educación Formal 2024 | Matrícula, personal, TIC e intensidad horaria por sede educativa oficial | [microdatos.dane.gov.co](https://microdatos.dane.gov.co/index.php/catalog/906) |
| 2 | SDSCJ — Delito de Alto Impacto (DAI) | Conteo de delitos por localidad 2018-2025 (GeoJSON) | [datosabiertos.bogota.gov.co](https://datosabiertos.bogota.gov.co/dataset/delito-de-alto-impacto-bogota-d-c) |
| 3 | SDSCJ — Incidentes C4 / Línea 123 | Incidentes reportados por localidad 2015-2026 (CSV) | [datosabiertos.bogota.gov.co](https://datosabiertos.bogota.gov.co/dataset/incidentes) |
| 4 | ICFES — Saber 11 2024-2 | Resultados agregados por sede educativa (GeoPackage) | [icfes.gov.co](https://www.icfes.gov.co) |
| 5 | DANE — Proyecciones de población Bogotá 2018-2035 | Población por localidad 2024 (Excel) | [dane.gov.co](https://www.dane.gov.co/index.php/estadisticas-por-tema/demografia-y-poblacion/proyecciones-de-poblacion/proyecciones-de-poblacion-bogota) |
| 6 | Tasa de deserción escolar oficial | Deserción por localidad (GeoPackage) | [datosabiertos.bogota.gov.co]([https://datosabiertos.bogota.gov.co](https://datosabiertos.bogota.gov.co/dataset/tasa-de-desercion-escolar-en-colegios-oficiales-por-localidad-bogota-d-c)) |
| 7 | Tasa de reprobación escolar oficial | Reprobación por localidad (GeoPackage) | [datosabiertos.bogota.gov.co]([https://datosabiertos.bogota.gov.co](https://datosabiertos.bogota.gov.co/dataset/tasa-de-reprobacion-escolar-en-colegios-oficiales-por-localidad-bogota-d-c)) |
| 8 | DANE — Poblaciones diferenciales | Alumnos con discapacidad, desplazados y grupos étnicos por sede | [microdatos.dane.gov.co](https://microdatos.dane.gov.co/index.php/catalog/906) |

Ver instrucciones detalladas de descarga en [`/data/fuentes.md`](data/fuentes.md).

---

## Paso a paso del código en R

El análisis se desarrolló en ocho etapas documentadas en el script principal:

**Parte 1: Seguridad:** procesamiento de los datos del DAI (GeoJSON) y las llamadas al C4 (CSV), consolidados por localidad y año.

**Parte 2: Educación:** procesamiento de los seis archivos del DANE (matrícula, personal, TIC, intensidad horaria, situación académica y carátula de sede) y los resultados Saber 11 del ICFES.

**Parte 3: Integración:** unión de la base educativa con los datos de seguridad usando el código de localidad como llave territorial.

**Parte 4: Variables derivadas:** construcción del índice de violencia estructural (DAI ponderado por gravedad, por 100.000 habitantes), índice de entorno escolar (incidentes C4 relevantes para NNAJ, por 100.000 habitantes), cuadrantes de riesgo territorial, ratios de personal por rol, índice TIC e índice de servicios.

**Parte 5: Tasas territoriales:** incorporación de las tasas oficiales de deserción y reprobación por localidad desde los GeoPackages de la SED.

**Parte 6: Regresiones:** estimación de regresiones lineales por bloques. Bloque A: efecto simple de cada predictor territorial sobre el ICFES. Bloque B: mismo efecto controlando por proporciones de estudiantes con discapacidad, desplazados del conflicto y pertenecientes a grupos étnicos.

**Parte 7: Moderaciones:** pruebas de interacción entre cada predictor territorial y cada característica institucional de la sede (jornada, horas académicas, ratios de personal, índice TIC). Se evalúa si las características de la sede amortiguan el efecto negativo del entorno sobre el ICFES.

**Parte 8: Exportación:** generación de la base consolidada para Power BI con ICFES predicho, residuos y clasificación de sobre/sub-rendimiento por sede.

---

## Metodología general del análisis

Inicialmente, se realizó una exploración de las variables disponibles en distintas fuentes de información relacionadas con educación, seguridad y población disponibles en las plataformas de Datos Abiertos Bogotá o Datos Abiertos Colombia. En particular, se revisaron las bases Educación Formal 2024 y Educación Formal —sedes educativas oficiales y no oficiales, urbanas y rurales— del Departamento Administrativo Nacional de Estadística —DANE, Dirección de Metodología y Producción Estadística —DIMPE—; la base de Delitos de Alto Impacto en Bogotá D.C. de la Secretaría Distrital de Seguridad, Convivencia y Justicia; la base de Incidentes Tramitados en el C4 - Número Único de Seguridad y Emergencias —NUSE— de la misma Secretaría; y la base de Proyecciones y retroproyecciones desagregadas de población de Bogotá para el periodo 2018-2035 por localidades y UPZ 2018-2024, con base en el CNPV 2018 del DANE. A partir de esta revisión, se identificaron variables pertinentes para caracterizar las condiciones institucionales de las sedes educativas, las condiciones adversas del entorno y los resultados académicos medidos a través de los resultados globales por sede en las pruebas Saber 11. 

Posteriormente, se realizó la integración de las bases utilizando como llave principal la sede educativa, identificada mediante el código DANE12. Las variables agregadas a nivel de localidad se vincularon a cada sede a partir del número y nombre de la localidad, asignando a cada establecimiento educativo los valores correspondientes al territorio en el que se encuentra ubicado. Para garantizar la consistencia del análisis, se aplicaron filtros por territorio, clase educativa y periodo de referencia. En particular, se incluyeron únicamente sedes ubicadas en Bogotá, pertenecientes al sector oficial, y variables con información disponible para el año 2024. 

Después de la integración, se construyeron variables agrupadas para sintetizar dimensiones relevantes del análisis. En primer lugar, se creó un índice de violencia, definido como una variable continua construida a partir del promedio ponderado de las tasas de homicidios, delitos sexuales, lesiones personales, violencia intrafamiliar y hurto a personas, con ponderaciones de 4, 3, 2, 2 y 1, respectivamente. Para cada tipo de delito, la tasa se calculó como el número de casos reportados en la base de delitos de alto impacto, dividido entre el total de habitantes de la localidad y multiplicado por 100.000. En segundo lugar, se construyó un índice de factores de riesgo asociados a seguridad, correspondiente a una variable continua calculada a partir de la tasa de incidentes reportados mediante llamadas al C4 en cada localidad. Este índice incluyó las categorías de maltrato, violencia sexual, exhibiciones o actos obscenos, lesiones personales, disparos, narcóticos, riñas, menor o persona abandonada, menor en establecimiento para mayores, pandillas juveniles y porte ilegal de armas. La tasa se calculó como la suma de los incidentes reportados en estas categorías, dividida entre el total de la población de la localidad y multiplicada por 100.000. 

También se construyeron variables relacionadas con la disponibilidad de recursos humanos en las sedes educativas. Para ello, se calcularon razones entre el número de personas disponibles por rol y el total de estudiantes matriculados en la sede. En este grupo se incluyeron la disponibilidad de personal directivo, de docentes de aula, de orientadores, de líderes de apoyo en el aula y docentes de apoyo en el aula.  

Adicionalmente, se construyó un índice TIC, definido como una variable continua calculada a partir del promedio entre las variables dicotómicas de presencia de aulas de informática, la presencia de computadores o equipos de cómputo en cada sede educativa, y la presencia de un plan de gestión TIC en la sede.  

Como variables de control, se calcularon las proporciones de estudiantes con discapacidad, pertenecientes a grupos étnicos y de estudiantes víctimas del conflicto armado, respecto al total de estudiantes matriculados en cada sede educativa. 

Además de las variables calculadas, se incluyeron variables originales disponibles en las bases de datos. Entre ellas se consideraron la jornada escolar, las horas de dedicación académica en básica secundaria y en educación media, la presencia de PAE en la sede, la proporción de deserción escolar y la reprobación escolar por localidad, y el puntaje general en las pruebas Saber 11 por sede. 

Finalmente, se realizó un ejercicio de moderación estadística entre las variables del entorno, las características institucionales de las sedes educativas y los resultados en Saber 11. En una primera fase, se estimaron regresiones lineales entre cada una de las variables de riesgo del entorno escolar (deserción y reprobación agregada por localidad, índice de violencia e índice de factores de riesgo asociados a seguridad) como variables predictoras del puntaje general en Saber 11. Posteriormente, se estimaron regresiones entre los posibles factores protectores o moderadores (índice TIC, horas de dedicación académica por nivel, tipo de jornada y razones de personal disponible por rol) como variables predictoras de los resultados en Saber 11. En estas ecuaciones se incluyeron como controles las proporciones de matrícula correspondientes a estudiantes con discapacidad, estudiantes víctimas del conflicto armado y estudiantes pertenecientes a grupos étnicos. Luego, se realizaron pruebas de moderación entre cada variable de riesgo y las características institucionales que, según las hipótesis del análisis, podrían atenuar el efecto adverso del entorno sobre los resultados académicos. 

Los resultados iniciales se analizaron a nivel de sede educativa, considerando un umbral de significancia estadística de p<0,05. Posteriormente, las sedes fueron agrupadas por localidad con el fin de incorporar un enfoque territorial al análisis e identificar en qué territorios ciertos factores institucionales podrían tener mayor capacidad compensatoria frente a condiciones adversas del entorno. En particular, se profundizó en las localidades con mayores niveles de riesgo y en aquellas donde las interacciones de moderación sugieren que una mayor presencia de recursos institucionales podría asociarse con una menor incidencia de los factores de riesgo sobre los resultados en las pruebas Saber 11.  

---

##Instrucciones para ejecutar el código

1. Descargue las bases de datos siguiendo las instrucciones del archivo fuentes.md ubicado en la carpeta /data de este repositorio. Guarde todos los archivos en una carpeta local de su equipo.
2. Descargue el script analisis_datajam_completo.R ubicado en la carpeta /scripts. Ábralo en RStudio y modifique la variable ruta_base (línea 50) para que corresponda a la ruta de la carpeta donde guardó los datos:

rruta_base <- "ruta/a/su/carpeta/"

3. Ejecute el script completo. Si todos los archivos se encuentran en la ubicación correcta, los resultados generados serán equivalentes a los disponibles en la carpeta /outputs del repositorio.

---

## Estructura del repositorio

```
/data
  fuentes.md                    # instrucciones de descarga de cada dataset
/scripts
  analisis_datajam_completo.R   # script unificado de análisis 
/outputs
  BASE_POWERBI.xlsx             # base consolidada para Power BI (una fila por sede)
  resultados_estadisticos.xlsx  # regresiones y moderaciones
README.md
LICENSE
```

---

## Equipo

**Pitagóricas Pitonisas**
Secretaría de Educación de Bogotá - Oficina para la Convivencia Escolar
Bogotá Datajam 2026 
