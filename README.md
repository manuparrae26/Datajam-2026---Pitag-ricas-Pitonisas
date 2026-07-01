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
| 6 | SED — Tasa de deserción escolar oficial | Deserción por localidad (GeoPackage) | [datosabiertos.bogota.gov.co](https://datosabiertos.bogota.gov.co) |
| 7 | SED — Tasa de reprobación escolar oficial | Reprobación por localidad (GeoPackage) | [datosabiertos.bogota.gov.co](https://datosabiertos.bogota.gov.co) |
| 8 | DANE — Poblaciones diferenciales | Alumnos con discapacidad, desplazados y grupos étnicos por sede | [microdatos.dane.gov.co](https://microdatos.dane.gov.co/index.php/catalog/906) |

Ver instrucciones detalladas de descarga en [`/data/fuentes.md`](data/fuentes.md).

---

## Metodología general del análisis

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
