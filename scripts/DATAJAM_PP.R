# =============================================================================
# DATAJAM 2026 — PITAGÓRICAS PITONISAS
# =============================================================================
#
# PREGUNTA DE INVESTIGACIÓN:
# ¿En qué medida las características institucionales de las sedes educativas
# —disponibilidad de personal, tipo de jornada, dedicación horaria y dotación
# TIC— moderan el efecto de las condiciones territoriales del entorno
# (incidencia delictiva y tasas de deserción y reprobación a nivel localidad)
# sobre el desempeño de los colegios oficiales de Bogotá en Saber 11 (2024)?
#
# FUENTES DE DATOS:
#   1. Educación Formal 2024 — DANE (microdatos por sede educativa)
#   2. Delito de Alto Impacto (DAI) — SDSCJ (GeoJSON por localidad)
#   3. Incidentes C4 / Línea 123 — SDSCJ (CSV por incidente)
#   4. Resultados Saber 11 2024-2 — ICFES (GeoPackage por sede)
#   5. Proyecciones de población 2024 por localidad — DANE (Excel)
#   6. Tasa de deserción escolar oficial — SED Bogotá (GeoPackage)
#   7. Tasa de reprobación escolar oficial — SED Bogotá (GeoPackage)
#   8. Poblaciones diferenciales (discapacidad, desplazados, étnicos) — DANE
#
# ESTRUCTURA DEL SCRIPT:
#   PARTE 1 — Procesamiento de datos de seguridad (DAI + C4)
#   PARTE 2 — Procesamiento de datos educativos (DANE + ICFES)
#   PARTE 3 — Integración: base unificada sede × seguridad
#   PARTE 4 — Construcción de índices y variables derivadas
#   PARTE 5 — Agregación de tasas de deserción y reprobación por localidad
#   PARTE 6 — Regresiones: efecto del entorno sobre Saber 11
#   PARTE 7 — Moderaciones: características de sede como colchones
#   PARTE 8 — Base consolidada para Power BI
#
# INSTRUCCIONES:
#   1. Ajustar ruta_base en la Sección 0
#   2. Descargar los datos según /data/fuentes.md
#   3. Ejecutar el script completo en RStudio
#   4. Los outputs se guardan automáticamente en ruta_base

# -----------------------------------------------------------------------------
# 0. LIBRERÍAS Y RUTA BASE
# -----------------------------------------------------------------------------

library(sf)          # lectura de archivos geoespaciales (GeoJSON, GeoPackage)
library(tidyverse)   # manipulación de datos (dplyr, tidyr, ggplot2, etc.)
library(readr)       # lectura eficiente de CSV
library(readxl)      # lectura de archivos Excel
library(openxlsx)    # escritura de Excel formateado
library(broom)       # extracción de resultados de modelos estadísticos

# RUTA BASE
ruta_base <- "/Users/manuelaparra/Documents/OCE-SED/Bases de Datos/"

options(OutDec = ".") 


# =============================================================================
# PARTE 1 — PROCESAMIENTO DE DATOS DE SEGURIDAD
# =============================================================================

# -----------------------------------------------------------------------------
# DATASET 1: DELITO DE ALTO IMPACTO
# -----------------------------------------------------------------------------
# GeoJSON con registros de delitos de alto impacto en Bogotá D.C.
# st_read() lee archivos espaciales; list.files() busca automáticamente
# el archivo .geojson dentro de la carpeta descomprimida.

ruta_dai <- file.path(ruta_base, "SDSCJ01_dai_geojson")

archivo_dai <- list.files(ruta_dai, pattern = "\\.geojson$", full.names = TRUE)[1]

sdscj01_dai_geo <- st_read(archivo_dai)

# Exploramos la estructura espacial y los primeros registros
cat("\n>>> DATASET 1: Delito de Alto Impacto (DAI)\n")
print(st_crs(sdscj01_dai_geo))   # Sistema de coordenadas
glimpse(sdscj01_dai_geo)          # Variables y tipos
head(sdscj01_dai_geo, 3)          # Primeras filas

# -----------------------------------------------------------------------------
# DICCIONARIO DE VARIABLES - DATASET 1: DELITO DE ALTO IMPACTO
# -----------------------------------------------------------------------------
# Este data frame es como un diccionario del dataset.
# Relaciona: el nombre original en el GeoJSON (nombre_original),
# un nombre corto y limpio para usar en el análisis (nombre_nuevo),
# y la descripción completa oficial de la SDSCJ (etiqueta).

diccionario_dai <- tibble(
  nombre_original = c(
    "CMIULOCAL", "CMNOMLOCAL", "CMMES",
    # Homicidios
    "CMH18CONT", "CMH19CONT", "CMH20CONT", "CMH21CONT", "CMH22CONT",
    "CMH23CONT", "CMH24CONT", "CMH25CONT", "CMHVAR", "CMHTOTAL",
    # Lesiones personales
    "CMLP18CONT", "CMLP19CONT", "CMLP20CONT", "CMLP21CONT", "CMLP22CONT",
    "CMLP23CONT", "CMLP24CONT", "CMLP25CONT", "CMLPVAR", "CMLPTOTAL",
    # Hurto personas
    "CMHP18CONT", "CMHP19CONT", "CMHP20CONT", "CMHP21CONT", "CMHP22CONT",
    "CMHP23CONT", "CMHP24CONT", "CMHP25CONT", "CMHPVAR", "CMHPTOTAL",
    # Hurto residencias
    "CMHR18CONT", "CMHR19CONT", "CMHR20CONT", "CMHR21CONT", "CMHR22CONT",
    "CMHR23CONT", "CMHR24CONT", "CMHR25CONT", "CMHRVAR", "CMHRTOTAL",
    # Hurto automotores
    "CMHA18CONT", "CMHA19CONT", "CMHA20CONT", "CMHA21CONT", "CMHA22CONT",
    "CMHA23CONT", "CMHA24CONT", "CMHA25CONT", "CMHAVAR", "CMHATOTAL",
    # Hurto bicicletas
    "CMHB18CONT", "CMHB19CONT", "CMHB20CONT", "CMHB21CONT", "CMHB22CONT",
    "CMHB23CONT", "CMHB24CONT", "CMHB25CONT", "CMHBVAR", "CMHBTOTAL",
    # Hurto comercio
    "CMHC18CONT", "CMHC19CONT", "CMHC20CONT", "CMHC21CONT", "CMHC22CONT",
    "CMHC23CONT", "CMHC24CONT", "CMHC25CONT", "CMHCVAR", "CMHCTOTAL",
    # Hurto celulares (nombre truncado en GeoJSON)
    "CMHCE18CON", "CMHCE19CON", "CMHCE20CON", "CMHCE21CON", "CMHCE22CON",
    "CMHCE23CON", "CMHCE24CON", "CMHCE25CON", "CMHCEVAR", "CMHCETOTAL",
    # Hurto motocicletas
    "CMHM18CONT", "CMHM19CONT", "CMHM20CONT", "CMHM21CONT", "CMHM22CONT",
    "CMHM23CONT", "CMHM24CONT", "CMHM25CONT", "CMHMVAR", "CMHMTOTAL",
    # Delitos sexuales
    "CMDS18CONT", "CMDS19CONT", "CMDS20CONT", "CMDS21CONT", "CMDS22CONT",
    "CMDS23CONT", "CMDS24CONT", "CMDS25CONT", "CMDSVAR", "CMDSTOTAL",
    # Violencia intrafamiliar
    "CMVI18CONT", "CMVI19CONT", "CMVI20CONT", "CMVI21CONT", "CMVI22CONT",
    "CMVI23CONT", "CMVI24CONT", "CMVI25CONT", "CMVIVAR", "CMVITOTAL",
    # Geometría
    "SHAPE_AREA", "SHAPE_LEN", "geometry"
  ),
  nombre_nuevo = c(
    "cod_localidad", "nom_localidad", "mes",
    # Homicidios
    "hom_2018", "hom_2019", "hom_2020", "hom_2021", "hom_2022",
    "hom_2023", "hom_2024", "hom_2025", "hom_var_pct", "hom_total",
    # Lesiones personales
    "lp_2018", "lp_2019", "lp_2020", "lp_2021", "lp_2022",
    "lp_2023", "lp_2024", "lp_2025", "lp_var_pct", "lp_total",
    # Hurto personas
    "hp_2018", "hp_2019", "hp_2020", "hp_2021", "hp_2022",
    "hp_2023", "hp_2024", "hp_2025", "hp_var_pct", "hp_total",
    # Hurto residencias
    "hr_2018", "hr_2019", "hr_2020", "hr_2021", "hr_2022",
    "hr_2023", "hr_2024", "hr_2025", "hr_var_pct", "hr_total",
    # Hurto automotores
    "ha_2018", "ha_2019", "ha_2020", "ha_2021", "ha_2022",
    "ha_2023", "ha_2024", "ha_2025", "ha_var_pct", "ha_total",
    # Hurto bicicletas
    "hb_2018", "hb_2019", "hb_2020", "hb_2021", "hb_2022",
    "hb_2023", "hb_2024", "hb_2025", "hb_var_pct", "hb_total",
    # Hurto comercio
    "hc_2018", "hc_2019", "hc_2020", "hc_2021", "hc_2022",
    "hc_2023", "hc_2024", "hc_2025", "hc_var_pct", "hc_total",
    # Hurto celulares
    "hce_2018", "hce_2019", "hce_2020", "hce_2021", "hce_2022",
    "hce_2023", "hce_2024", "hce_2025", "hce_var_pct", "hce_total",
    # Hurto motocicletas
    "hm_2018", "hm_2019", "hm_2020", "hm_2021", "hm_2022",
    "hm_2023", "hm_2024", "hm_2025", "hm_var_pct", "hm_total",
    # Delitos sexuales
    "ds_2018", "ds_2019", "ds_2020", "ds_2021", "ds_2022",
    "ds_2023", "ds_2024", "ds_2025", "ds_var_pct", "ds_total",
    # Violencia intrafamiliar
    "vif_2018", "vif_2019", "vif_2020", "vif_2021", "vif_2022",
    "vif_2023", "vif_2024", "vif_2025", "vif_var_pct", "vif_total",
    # Geometría
    "shape_area", "shape_len", "geometry"
  ),
  etiqueta = c(
    "Código Localidad", "Nombre Localidad", "Mes",
    # Homicidios
    "Total Homicidios 2018", "Total Homicidios 2019", "Total Homicidios 2020",
    "Total Homicidios 2021", "Total Homicidios 2022", "Total Homicidios 2023",
    "Total Homicidios 2024", "Total Homicidios 2025", "Variación Homicidios %",
    "Total Homicidios Año Actual Bogotá D.C.",
    # Lesiones personales
    "Total Lesiones Personales 2018", "Total Lesiones Personales 2019",
    "Total Lesiones Personales 2020", "Total Lesiones Personales 2021",
    "Total Lesiones Personales 2022", "Total Lesiones Personales 2023",
    "Total Lesiones Personales 2024", "Total Lesiones Personales 2025",
    "Variación Lesiones Personales %", "Total Lesiones Personales Año Actual Bogotá D.C.",
    # Hurto personas
    "Total Hurto Personas 2018", "Total Hurto Personas 2019", "Total Hurto Personas 2020",
    "Total Hurto Personas 2021", "Total Hurto Personas 2022", "Total Hurto Personas 2023",
    "Total Hurto Personas 2024", "Total Hurto Personas 2025",
    "Variación Hurto Personas %", "Total Hurto Personas Año Actual Bogotá D.C.",
    # Hurto residencias
    "Total Hurto Residencias 2018", "Total Hurto Residencias 2019",
    "Total Hurto Residencias 2020", "Total Hurto Residencias 2021",
    "Total Hurto Residencias 2022", "Total Hurto Residencias 2023",
    "Total Hurto Residencias 2024", "Total Hurto Residencias 2025",
    "Variación Hurto Residencias %", "Total Hurto Residencias Año Actual Bogotá D.C.",
    # Hurto automotores
    "Total Hurto Automotores 2018", "Total Hurto Automotores 2019",
    "Total Hurto Automotores 2020", "Total Hurto Automotores 2021",
    "Total Hurto Automotores 2022", "Total Hurto Automotores 2023",
    "Total Hurto Automotores 2024", "Total Hurto Automotores 2025",
    "Variación Hurto Automotores %", "Total Hurto Automotores Año Actual Bogotá D.C.",
    # Hurto bicicletas
    "Total Hurto Bicicletas 2018", "Total Hurto Bicicletas 2019",
    "Total Hurto Bicicletas 2020", "Total Hurto Bicicletas 2021",
    "Total Hurto Bicicletas 2022", "Total Hurto Bicicletas 2023",
    "Total Hurto Bicicletas 2024", "Total Hurto Bicicletas 2025",
    "Variación Hurto Bicicletas %", "Total Hurto Bicicletas Año Actual Bogotá D.C.",
    # Hurto comercio
    "Total Hurto Comercio 2018", "Total Hurto Comercio 2019", "Total Hurto Comercio 2020",
    "Total Hurto Comercio 2021", "Total Hurto Comercio 2022", "Total Hurto Comercio 2023",
    "Total Hurto Comercio 2024", "Total Hurto Comercio 2025",
    "Variación Hurto Comercio %", "Total Hurto Comercio Año Actual Bogotá D.C.",
    # Hurto celulares
    "Total Hurto Celulares 2018", "Total Hurto Celulares 2019", "Total Hurto Celulares 2020",
    "Total Hurto Celulares 2021", "Total Hurto Celulares 2022", "Total Hurto Celulares 2023",
    "Total Hurto Celulares 2024", "Total Hurto Celulares 2025",
    "Variación Hurto Celulares %", "Total Hurto Celulares Año Actual Bogotá D.C.",
    # Hurto motocicletas
    "Total Hurto Motocicletas 2018", "Total Hurto Motocicletas 2019",
    "Total Hurto Motocicletas 2020", "Total Hurto Motocicletas 2021",
    "Total Hurto Motocicletas 2022", "Total Hurto Motocicletas 2023",
    "Total Hurto Motocicletas 2024", "Total Hurto Motocicletas 2025",
    "Variación Hurto Motocicletas %", "Total Hurto Motocicletas Año Actual Bogotá D.C.",
    # Delitos sexuales
    "Total Delitos Sexuales 2018", "Total Delitos Sexuales 2019", "Total Delitos Sexuales 2020",
    "Total Delitos Sexuales 2021", "Total Delitos Sexuales 2022", "Total Delitos Sexuales 2023",
    "Total Delitos Sexuales 2024", "Total Delitos Sexuales 2025",
    "Variación Delitos Sexuales %", "Total Delitos Sexuales Año Actual Bogotá D.C.",
    # Violencia intrafamiliar
    "Total Violencia Intrafamiliar 2018", "Total Violencia Intrafamiliar 2019",
    "Total Violencia Intrafamiliar 2020", "Total Violencia Intrafamiliar 2021",
    "Total Violencia Intrafamiliar 2022", "Total Violencia Intrafamiliar 2023",
    "Total Violencia Intrafamiliar 2024", "Total Violencia Intrafamiliar 2025",
    "Variación Violencia Intrafamiliar %", "Total Violencia Intrafamiliar Año Actual Bogotá D.C.",
    # Geometría
    "Área del polígono (sistema ESRI)", "Longitud del perímetro (sistema ESRI)",
    "Geometría espacial (polígono de localidad)"
  )
)

# Verificación: cuántas variables quedaron documentadas
cat("Variables documentadas en el diccionario DAI:", nrow(diccionario_dai), "\n")
print(diccionario_dai)


# -----------------------------------------------------------------------------
# 3. IMPORTACIÓN - DATASET 2: CRIMEN / SEGURIDAD
# -----------------------------------------------------------------------------
# Segundo GeoJSON de la SDSCJ. Seguimos la misma lógica de lectura.
# Se almacena con nombre distinto para no pisar el primer objeto.

ruta_crn <- file.path(ruta_base, "SDSCJ02_crn_geojson")

archivo_crn <- list.files(ruta_crn, pattern = "\\.geojson$", full.names = TRUE)[1]

sdscj02_crn_geo <- st_read(archivo_crn)

cat("\n>>> DATASET 2: Crimen / Seguridad (CRN)\n")
print(st_crs(sdscj02_crn_geo))
glimpse(sdscj02_crn_geo)
head(sdscj02_crn_geo, 3)

# -----------------------------------------------------------------------------
# 3.1 DICCIONARIO DE VARIABLES - DATASET 2: COMPARENDOS (CRN)
# -----------------------------------------------------------------------------
# Nota: el dataset en R tiene nombres de UPZ mapeados como localidad
# (CMIULOCAL / CMNOMLOCAL en lugar de CMIUUPLA / CMNOMUPLA del servicio ESRI).
# CMRNDESCOMP aparece truncado como "CMRNDESCOM" por límite de caracteres.

diccionario_crn <- tibble(
  nombre_original = c(
    "CMRANK", "CMRNCONT", "CMIULOCAL", "CMNOMLOCAL",
    "CMRNART", "CMRNNUM", "CMRNDESCOM", "CMRNMES", "CMRNTOTAL",
    "SHAPE_AREA", "SHAPE_LEN", "geometry"
  ),
  nombre_nuevo = c(
    "ranking_comparendo", "n_comparendos", "cod_upz", "nom_upz",
    "articulo", "comportamiento", "desc_comportamiento", "mes", "comparendos_total",
    "shape_area", "shape_len", "geometry"
  ),
  etiqueta = c(
    "Ranking Comparendo",
    "Número de Comparendos",
    "Código UPZ (mapeado como localidad en el GeoJSON)",
    "Nombre UPZ (mapeado como localidad en el GeoJSON)",
    "Artículo del Código Nacional de Seguridad y Convivencia",
    "Comportamiento infractor",
    "Descripción del Comportamiento (truncado en GeoJSON)",
    "Mes de registro",
    "Total Comportamientos Año Actual Bogotá D.C.",
    "Área del polígono (sistema ESRI)",
    "Longitud del perímetro (sistema ESRI)",
    "Geometría espacial (polígono de UPZ)"
  )
)

cat("Variables documentadas en el diccionario CRN:", nrow(diccionario_crn), "\n")
print(diccionario_crn)

# -----------------------------------------------------------------------------
# IMPORTACIÓN - DATASET 3: LLAMADAS A LÍNEA 123 / C4
# -----------------------------------------------------------------------------
# Archivo CSV con registros de llamadas de emergencia al Centro de Comando,
# Control, Comunicaciones y Cómputo (C4) de Bogotá.
# read_csv() de readr es más robusto que read.csv() base:
# infiere tipos, maneja encoding y muestra un resumen de columnas.

ruta_c4 <- file.path(ruta_base, "SDSCJ03_LLAMADASC4.csv")

sdscj03_c4 <- read_csv2(ruta_c4, locale = locale(encoding = "latin1"))

cat("\n>>> DATASET 3: Llamadas C4 / Línea 123\n")
glimpse(sdscj03_c4)

# -----------------------------------------------------------------------------
# IMPORTACIÓN - GUÍA DE TIPIFICACIÓN DE INCIDENTES C4
# -----------------------------------------------------------------------------
# Tabla oficial de referencia con códigos, nombres y definiciones de incidentes
# del protocolo C4 / Línea 123. Se importa como catálogo independiente
# para luego hacer match con sdscj03_c4.

guia_tipificacion <- read_csv2(
  file.path(ruta_base, "guiatipificacionincidentes.csv"),
  locale = locale(encoding = "latin1")
)

cat(">>> Guía tipificación importada:", nrow(guia_tipificacion), "incidentes\n")
glimpse(guia_tipificacion)

# -----------------------------------------------------------------------------
#JOIN CON DATASET C4
# -----------------------------------------------------------------------------
# left_join conserva todos los registros de sdscj03_c4.
# Ajusta "COD_INCIDENTE" por el nombre real de la columna clave en guia_tipificacion


sdscj03_c4 <- sdscj03_c4 |>
  left_join(guia_tipificacion, by = c("TIPO_INCIDENTE" = "COD_INCIDENTE"))

cat(">>> Registros sin match (código no encontrado en guía):",
    sum(is.na(sdscj03_c4$DEFINICION)), "\n")

# -----------------------------------------------------------------------------
# 5. RESUMEN GENERAL DE LOS TRES DATASETS
# -----------------------------------------------------------------------------
# Vista rápida del número de registros y variables de cada base
# para confirmar que la importación fue exitosa.

cat("\n=== RESUMEN DE IMPORTACIÓN ===\n")
cat("DAI  (GeoJSON):", nrow(sdscj01_dai_geo), "registros |", ncol(sdscj01_dai_geo), "variables\n")
cat("CRN  (GeoJSON):", nrow(sdscj02_crn_geo), "registros |", ncol(sdscj02_crn_geo), "variables\n")
cat("C4   (CSV)    :", nrow(sdscj03_c4),      "registros |", ncol(sdscj03_c4),      "variables\n")

# =============================================================================
# CONSOLIDACIÓN: DF UNIFICADO DE SEGURIDAD
# Unidad de análisis: Localidad × Año
# Fuentes: Delitos de Alto Impacto + C4 Llamadas Línea 123
# =============================================================================


# -----------------------------------------------------------------------------
# PREPARACIÓN DAI - PIVOTEAR A FORMATO LARGO
# -----------------------------------------------------------------------------
# El DAI viene en formato ancho: una columna por año y tipo de delito.
# Lo convertimos a formato largo (localidad × año × tipo_delito × conteo)
# para poder unirlo con C4 que ya tiene estructura longitudinal.
# nos quedamos solo con los conteos anuales 2022-2025.

dai_largo <- sdscj01_dai_geo |>
  st_drop_geometry() |>                          # eliminamos geometría, solo tabla
  select(CMIULOCAL, CMNOMLOCAL,                  # identificadores de localidad
         # conteos anuales por tipo de delito (2022-2025)
         matches("(CMH|CMLP|CMHP|CMHR|CMHA|CMHB|CMHC|CMHCE|CMHM|CMDS|CMVI)(22|23|24|25)")) |>
  pivot_longer(
    cols = -c(CMIULOCAL, CMNOMLOCAL),
    names_to = "variable_original",
    values_to = "conteo"
  ) |>
  mutate(
    # Extraemos el año del nombre de la variable (ej: CMH22CONT → 2022)
    anio = as.integer(paste0("20", str_extract(variable_original, "\\d{2}(?=(CONT|CON))"))),
    # Extraemos el prefijo del delito (ej: CMH22CONT → CMH)
    prefijo = str_extract(variable_original, "^CM[A-Z]+(?=\\d{2})"),
    # Mapeamos prefijo a nombre legible del delito
    tipo_delito = case_when(
      prefijo == "CMH"   ~ "homicidios",
      prefijo == "CMLP"  ~ "lesiones_personales",
      prefijo == "CMHP"  ~ "hurto_personas",
      prefijo == "CMHR"  ~ "hurto_residencias",
      prefijo == "CMHA"  ~ "hurto_automotores",
      prefijo == "CMHB"  ~ "hurto_bicicletas",
      prefijo == "CMHC"  ~ "hurto_comercio",
      prefijo == "CMHCE" ~ "hurto_celulares",
      prefijo == "CMHM"  ~ "hurto_motocicletas",
      prefijo == "CMDS"  ~ "delitos_sexuales",
      prefijo == "CMVI"  ~ "violencia_intrafamiliar",
      TRUE ~ "otro"
    )
  ) |>
  filter(!is.na(anio), tipo_delito != "otro") |>
  select(cod_localidad = CMIULOCAL,
         nom_localidad = CMNOMLOCAL,
         anio, tipo_delito, conteo)

cat(">>> DAI largo:", nrow(dai_largo), "filas |",
    n_distinct(dai_largo$cod_localidad), "localidades |",
    n_distinct(dai_largo$anio), "años\n")


# -----------------------------------------------------------------------------
# PREPARACIÓN DAI - PIVOTEAR A FORMATO ANCHO POR DELITO
# -----------------------------------------------------------------------------
# Ahora lo pasamos a ancho pero con una columna por tipo de delito,
# manteniendo localidad × año como unidad de análisis.

dai_ancho <- dai_largo |>
  pivot_wider(
    names_from  = tipo_delito,
    values_from = conteo,
    values_fn   = sum      # por si hay duplicados por mes dentro del año
  )

cat(">>> DAI ancho:", nrow(dai_ancho), "filas |", ncol(dai_ancho), "columnas\n")


# -----------------------------------------------------------------------------
# PREPARACIÓN C4 - AGREGAR POR LOCALIDAD × AÑO × TIPO DE INCIDENTE
# -----------------------------------------------------------------------------
# C4 tiene un registro por incidente. Lo agregamos contando incidentes
# por localidad, año y tipo de incidente (formato ancho).
# Cada tipo de incidente queda como columna independiente,
# permitiendo analizar la composición del perfil de emergencias por localidad.
# Filtramos 2022-2025 para que coincida con DAI.

c4_agregado <- sdscj03_c4 |>
  filter(ANIO %in% 2022:2025) |>
  group_by(
    cod_localidad  = COD_LOCALIDAD,
    nom_localidad  = LOCALIDAD,
    anio           = ANIO,
    tipo_incidente = TIPO_INCIDENTE
  ) |>
  summarise(n_incidentes = sum(CANT_INCIDENTES, na.rm = TRUE),
            .groups = "drop")

# Pivoteamos a ancho: una columna por tipo de incidente
# El prefijo "c4_" identifica que la variable viene del dataset C4
c4_ancho <- c4_agregado |>
  mutate(tipo_incidente = paste0("c4_", str_to_lower(str_replace_all(tipo_incidente, "[^A-Za-z0-9]", "_")))) |>
  pivot_wider(
    names_from  = tipo_incidente,
    values_from = n_incidentes,
    values_fill = 0            # localidades sin ese incidente quedan en 0, no NA
  )

# Total general como columna adicional de resumen
c4_ancho <- c4_ancho |>
  mutate(total_incidentes_c4 = rowSums(across(starts_with("c4_")), na.rm = TRUE))

cat(">>> C4 ancho:", nrow(c4_ancho), "filas |",
    ncol(c4_ancho), "columnas |",
    n_distinct(c4_ancho$cod_localidad), "localidades\n")


# -----------------------------------------------------------------------------
# JOIN: DF UNIFICADO DE SEGURIDAD
# -----------------------------------------------------------------------------
# Unimos DAI (delitos por localidad × año) y C4 (incidentes por localidad × año
# × tipo) en un solo df con unidad de análisis: localidad × año.
# Usamos full_join para detectar si alguna localidad aparece en uno
# pero no en el otro (importante para diagnóstico de cobertura).

df_seguridad <- dai_ancho |>
  full_join(c4_ancho,
            by = c("cod_localidad", "anio")) |>
  # Consolidamos la columna de nombre de localidad (viene de ambos datasets)
  mutate(nom_localidad = coalesce(nom_localidad.x, nom_localidad.y)) |>
  select(-matches("nom_localidad\\.")) |>
  # Reordenamos: identificadores primero
  relocate(cod_localidad, nom_localidad, anio) |>
  arrange(cod_localidad, anio)

cat("\n=== DF SEGURIDAD UNIFICADO ===\n")
cat("Filas        :", nrow(df_seguridad), "\n")
cat("Columnas     :", ncol(df_seguridad), "\n")
cat("Localidades  :", n_distinct(df_seguridad$cod_localidad), "\n")
cat("Años         :", paste(sort(unique(df_seguridad$anio)), collapse = ", "), "\n")

# -----------------------------------------------------------------------------
# DIAGNÓSTICO DE COBERTURA
# -----------------------------------------------------------------------------
# Verificamos que el join haya sido limpio: sin localidades huérfanas
# y sin pérdida de registros inesperada.

cat("\n--- Localidades sin datos DAI ---\n")
df_seguridad |>
  filter(is.na(homicidios)) |>
  distinct(cod_localidad, nom_localidad) |>
  print()

cat("\n--- Localidades sin datos C4 ---\n")
df_seguridad |>
  filter(is.na(total_incidentes_c4)) |>
  distinct(cod_localidad, nom_localidad) |>
  print()

cat("\n--- Registros por año ---\n")
df_seguridad |>
  count(anio) |>
  print()

glimpse(df_seguridad)


# =============================================================================


# =============================================================================
# PARTE 2 — PROCESAMIENTO DE DATOS EDUCATIVOS (DANE + ICFES)
# =============================================================================
# Fuente: Educación Formal 2024 — DANE
# Fuente: Resultados Saber 11 2024-2 — ICFES
# Filtro: solo sedes de Bogotá, sector oficial
# Producto: df_educacion_sede_icfes (sedes con puntajes Saber 11)
# =============================================================================

# -----------------------------------------------------------------------------
# IMPORTACIÓN DE LOS 6 ARCHIVOS
# -----------------------------------------------------------------------------
# Todos usan coma como separador y encoding UTF-8 (estándar DANE).
# Filtramos Bogotá (CODIGOINTERNOMUNI == 11001) y sector oficial
# desde la carátula para luego aplicar ese filtro a las demás tablas.

ruta_dane <- paste0(ruta_base, "DANE01_EDUFORMAL24/CSV")

# Carátula: información maestra de cada sede
dane_caratula <- read_csv(
  file.path(ruta_dane, "Carátula única de la sede educativa.csv"),
  locale = locale(encoding = "UTF-8")
)

# Personal ocupado por categoría y sexo
dane_personal <- read_csv(
  file.path(ruta_dane, "Personal ocupado en la sede educativa.csv"),
  locale = locale(encoding = "UTF-8")
)

# Alumnos matriculados por jornada, nivel y modelo educativo
dane_matricula <- read_csv(
  file.path(ruta_dane, "Alumnos matriculados por jornadas y nivel educativo (educación tradicional, CLEI y modelos educativos).CSV"),
  locale = locale(encoding = "UTF-8")
)

# Situación académica al finalizar 2023 (aprobados, reprobados, desertores)
dane_situacion <- read_csv(
  file.path(ruta_dane, "Situación académica al finalizar el año escolar 2023 según educación tradicional por jornada.CSV"),
  locale = locale(encoding = "UTF-8")
)

# TIC: tenencia, acceso y uso por sede
dane_tic <- read_csv(
  file.path(ruta_dane, "Tenencia, acceso y uso de los bienes y servicios TIC por sede educativa.CSV"),
  locale = locale(encoding = "UTF-8")
)

# Intensidad horaria por nivel y jornada
dane_intensidad <- read_csv(
  file.path(ruta_dane, "Intensidad horaria en educación tradicional por nivel educativo y jornada.CSV"),
  locale = locale(encoding = "UTF-8")
)

cat(">>> Archivos importados:\n")
cat("Carátula   :", nrow(dane_caratula),   "sedes\n")
cat("Personal   :", nrow(dane_personal),   "filas\n")
cat("Matrícula  :", nrow(dane_matricula),  "filas\n")
cat("Situación  :", nrow(dane_situacion),  "filas\n")
cat("TIC        :", nrow(dane_tic),        "filas\n")
cat("Intensidad :", nrow(dane_intensidad), "filas\n")


# -----------------------------------------------------------------------------
# FILTRO: BOGOTÁ + SECTOR OFICIAL DESDE LA CARÁTULA
# -----------------------------------------------------------------------------
# CODIGOINTERNOMUNI == 11001 → Bogotá D.C.
# SECTOR_NOMBRE == "Oficial" → solo sedes oficiales
# Obtenemos el listado de SEDE_CODIGO válidos para filtrar las demás tablas.

sedes_bogota_oficial <- dane_caratula |>
  filter(CODIGOINTERNOMUNI == 11001,
         SECTOR_NOMBRE == "Oficial") |>
  select(SEDE_CODIGO, SEDE_NOMBRE, LOCALIDAD_ID, CODLOCALIDAD, LOCALIDAD,
         SECTOR_NOMBRE, NATURALEZA, AREA_NOMBRE, SEDE_PAE, ES_SEDE_PAE,
         SEDE_BILINGUE, ES_BILINGUE, SEDE_ETNOEDUCATIVA, ES_ETNOEDUCATIVA,
         SEDE_EDUCACION_ESPECDIS, ES_EDUCACION_ESPECDIS,
         SUBSEDE_CODIGO, SUBSEDE_NOMBRE)   # SUBSEDE_CODIGO = código IED principal

cat("\n>>> Sedes Bogotá oficiales:", nrow(sedes_bogota_oficial), "\n")
cat(">>> IEDs distintas (sedes principales):",
    n_distinct(sedes_bogota_oficial$SUBSEDE_CODIGO), "\n")


# -----------------------------------------------------------------------------
# FILTRO DE LAS TABLAS SECUNDARIAS A BOGOTÁ OFICIAL
# -----------------------------------------------------------------------------
# Usamos semi_join para conservar solo los registros de sedes bogotanas oficiales.

codigos_validos <- sedes_bogota_oficial |> select(SEDE_CODIGO)

dane_personal_bog   <- dane_personal   |> semi_join(codigos_validos, by = "SEDE_CODIGO")
dane_matricula_bog  <- dane_matricula  |> semi_join(codigos_validos, by = "SEDE_CODIGO")
dane_situacion_bog  <- dane_situacion  |> semi_join(codigos_validos, by = "SEDE_CODIGO")
dane_tic_bog        <- dane_tic        |> semi_join(codigos_validos, by = "SEDE_CODIGO")
dane_intensidad_bog <- dane_intensidad |> semi_join(codigos_validos, by = "SEDE_CODIGO")

cat("\n>>> Filtrado a Bogotá oficial:\n")
cat("Personal   :", nrow(dane_personal_bog),   "filas\n")
cat("Matrícula  :", nrow(dane_matricula_bog),  "filas\n")
cat("Situación  :", nrow(dane_situacion_bog),  "filas\n")
cat("TIC        :", nrow(dane_tic_bog),        "filas\n")
cat("Intensidad :", nrow(dane_intensidad_bog), "filas\n")


# -----------------------------------------------------------------------------
# PERSONAL POR IED - FORMATO ANCHO (1 FILA POR SEDE)
# -----------------------------------------------------------------------------
# Cada sede tiene múltiples filas (una por categoría de personal).
# Sumamos hombres + mujeres por categoría y pivoteamos a ancho,
# quedando 1 fila por SEDE_CODIGO con una columna por categoría.

dane_personal_bog_ancho <- dane_personal_bog |>
  mutate(
    total_categoria = SEDEPERO_CANTIDAD_HOMBRE + SEDEPERO_CANTIDAD_MUJER,
    # Usamos CATEGORIA_ID para nombres cortos y estables
    col_nombre = paste0("personal_cat", CATEGORIA_ID)
  ) |>
  group_by(SEDE_CODIGO, col_nombre) |>
  summarise(total = sum(total_categoria, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = col_nombre, values_from = total, values_fill = 0)

cat(">>> Personal ancho:", nrow(dane_personal_bog_ancho), "sedes |",
    ncol(dane_personal_bog_ancho), "columnas\n")
print(dane_personal_bog_ancho)

# -----------------------------------------------------------------------------
# ATRÍCULA POR SEDE - FORMATO ANCHO (1 FILA POR SEDE)
# -----------------------------------------------------------------------------
# Cada sede tiene múltiples filas (nivel × jornada × modelo).
# Construimos dos grupos de columnas:
#   1. matricula_<nivel>: total de alumnos por nivel educativo (suma todas las jornadas)
#   2. jornada_<nombre>: indicador 1/0 si la sede tiene esa jornada
# El problema: NIVELENSE_NOMBRE y JORNADA_NOMBRE quedaron como columnas
# identificadoras adicionales, impidiendo que el pivot colapsara a 1 fila.
# Solución: eliminarlas antes de pivotar, igual que hicimos con situación.

# -- Parte 1: matrícula total por nivel educativo --
matricula_por_nivel <- dane_matricula_bog |>
  group_by(SEDE_CODIGO, NIVELENSE_NOMBRE) |>
  summarise(total = sum(SEDEALUM_CANTIDAD, na.rm = TRUE), .groups = "drop") |>
  mutate(col_nombre = paste0("mat_",
                             str_to_lower(
                               str_replace_all(NIVELENSE_NOMBRE, "[^A-Za-záéíóúüñÁÉÍÓÚÜÑ\\s]", "") |>
                                 str_squish() |>
                                 str_replace_all("\\s+", "_")
                             ))) |>
  select(-NIVELENSE_NOMBRE) |>          # <-- eliminamos antes de pivotar
  pivot_wider(names_from  = col_nombre,
              values_from = total,
              values_fill = 0,
              values_fn   = sum)

# Parte 2: indicador 1/0 de jornadas por sede 
jornadas_por_sede <- dane_matricula_bog |>
  distinct(SEDE_CODIGO, JORNADA_NOMBRE) |>
  mutate(
    tiene = 1L,
    col_nombre = paste0("jornada_",
                        str_to_lower(
                          str_replace_all(JORNADA_NOMBRE, "[^A-Za-záéíóúüñÁÉÍÓÚÜÑ\\s]", "") |>
                            str_squish() |>
                            str_replace_all("\\s+", "_")
                        ))
  ) |>
  select(-JORNADA_NOMBRE) |>            # <-- eliminamos antes de pivotar
  pivot_wider(names_from  = col_nombre,
              values_from = tiene,
              values_fill = 0L,
              values_fn   = max)

# Join de ambas partes
dane_matricula_bog_ancho <- matricula_por_nivel |>
  left_join(jornadas_por_sede, by = "SEDE_CODIGO")

cat(">>> Matrícula ancho:", nrow(dane_matricula_bog_ancho), "sedes |",
    n_distinct(dane_matricula_bog_ancho$SEDE_CODIGO), "únicas |",
    ncol(dane_matricula_bog_ancho), "columnas\n")

# -----------------------------------------------------------------------------
#SITUACIÓN ACADÉMICA POR SEDE - FORMATO ANCHO (1 FILA POR SEDE)
# -----------------------------------------------------------------------------
# Primero sumamos por SEDE_CODIGO × SITUACADE_NOMBRE (colapsando grados y jornadas),
# luego pivoteamos. Así cada sede queda en 1 sola fila.

dane_situacion_bog_ancho <- dane_situacion_bog |>
  mutate(total_situacion = JORNSITU_CANTIDAD_HOMBRE + JORNSITU_CANTIDAD_MUJER) |>
  group_by(SEDE_CODIGO, SITUACADE_NOMBRE) |>
  summarise(total = sum(total_situacion, na.rm = TRUE), .groups = "drop") |>
  mutate(col_nombre = paste0("sit_",
                             str_to_lower(
                               str_replace_all(SITUACADE_NOMBRE, "[^A-Za-záéíóúüñÁÉÍÓÚÜÑ\\s]", "") |>
                                 str_squish() |>
                                 str_replace_all("\\s+", "_")
                             ))) |>
  select(-SITUACADE_NOMBRE) |>        # <-- eliminamos antes de pivotar
  pivot_wider(names_from  = col_nombre,
              values_from = total,
              values_fill = 0,
              values_fn   = sum)       # <-- por si aún hay duplicados residuales

cat(">>> Situación ancho:", nrow(dane_situacion_bog_ancho), "sedes |",
    ncol(dane_situacion_bog_ancho), "columnas\n")
glimpse(dane_situacion_bog_ancho)

# -----------------------------------------------------------------------------
# RECURSOS TIC POR SEDE - FORMATO ANCHO (1 FILA POR SEDE)
# -----------------------------------------------------------------------------
# Cada sede tiene  una única fila (especialidad × jornada × nivel). No es necesario
# convertir la base de datos en longitudinal.


# -----------------------------------------------------------------------------
# INTENSIDAD HORARIA POR SEDE - FORMATO ANCHO (1 FILA POR SEDE)
# -----------------------------------------------------------------------------
# Cada sede tiene múltiples filas (especialidad × jornada × nivel).
# Sumamos el total de horas por nivel educativo y pivoteamos a ancho:
#   horas_<nivel>: total de horas en ese nivel (suma todas las especialidades y jornadas)

dane_intensidad_bog_ancho <- dane_intensidad_bog |>
  group_by(SEDE_CODIGO, NIVELENSE_NOMBRE) |>
  summarise(total_horas = sum(JORNINTE_CANTIDAD_HORA, na.rm = TRUE), .groups = "drop") |>
  mutate(col_nombre = paste0("horas_",
                             str_to_lower(
                               str_replace_all(NIVELENSE_NOMBRE, "[^A-Za-záéíóúüñÁÉÍÓÚÜÑ\\s]", "") |>
                                 str_squish() |>
                                 str_replace_all("\\s+", "_")
                             ))) |>
  select(-NIVELENSE_NOMBRE) |>
  pivot_wider(names_from  = col_nombre,
              values_from = total_horas,
              values_fill = 0,
              values_fn   = sum)

cat(">>> Intensidad horaria ancho:", nrow(dane_intensidad_bog_ancho), "sedes |",
    ncol(dane_intensidad_bog_ancho), "columnas\n")
glimpse(dane_intensidad_bog_ancho)


# -----------------------------------------------------------------------------
# JOIN: DF UNIFICADO EDUCACIÓN A NIVEL SEDE
# -----------------------------------------------------------------------------
# Aseguramos que cada tabla tenga exactamente 1 fila por SEDE_CODIGO
# antes del join usando distinct() o re-agregando.

# Verificamos unicidad de cada tabla antes del join
cat("Filas por tabla (deben coincidir con n° de sedes únicas):\n")
cat("sedes_bogota_oficial  :", nrow(sedes_bogota_oficial),      "| sedes únicas:", n_distinct(sedes_bogota_oficial$SEDE_CODIGO), "\n")
cat("dane_matricula_ancho  :", nrow(dane_matricula_bog_ancho),  "| sedes únicas:", n_distinct(dane_matricula_bog_ancho$SEDE_CODIGO), "\n")
cat("dane_personal_ancho   :", nrow(dane_personal_bog_ancho),   "| sedes únicas:", n_distinct(dane_personal_bog_ancho$SEDE_CODIGO), "\n")
cat("dane_situacion_ancho  :", nrow(dane_situacion_bog_ancho),  "| sedes únicas:", n_distinct(dane_situacion_bog_ancho$SEDE_CODIGO), "\n")
cat("dane_tic_bog          :", nrow(dane_tic_bog),              "| sedes únicas:", n_distinct(dane_tic_bog$SEDE_CODIGO), "\n")
cat("dane_intensidad_ancho :", nrow(dane_intensidad_bog_ancho), "| sedes únicas:", n_distinct(dane_intensidad_bog_ancho$SEDE_CODIGO), "\n")

# -----------------------------------------------------------------------------
# JOIN FINAL CORREGIDO: DF UNIFICADO EDUCACIÓN A NIVEL SEDE
# -----------------------------------------------------------------------------
# Todas las tablas tienen 1 fila por SEDE_CODIGO — join limpio garantizado.
# left_join desde sedes_bogota_oficial (776) como base:
# las sedes sin datos en alguna tabla quedarán con NA en esas columnas.

df_educacion_sede <- sedes_bogota_oficial |>
  left_join(dane_matricula_bog_ancho,   by = "SEDE_CODIGO") |>
  left_join(dane_personal_bog_ancho,    by = "SEDE_CODIGO") |>
  left_join(dane_situacion_bog_ancho,   by = "SEDE_CODIGO") |>
  left_join(dane_tic_bog |>
              select(-PERIODO_ID, -PERIODO_ANIO),
            by = "SEDE_CODIGO") |>
  left_join(dane_intensidad_bog_ancho,  by = "SEDE_CODIGO") |>
  arrange(CODLOCALIDAD, SEDE_NOMBRE)

cat("\n=== DF EDUCACIÓN A NIVEL SEDE ===\n")
cat("Sedes      :", nrow(df_educacion_sede), "\n")
cat("Columnas   :", ncol(df_educacion_sede), "\n")
cat("Localidades:", n_distinct(df_educacion_sede$CODLOCALIDAD), "\n")

# Diagnóstico de NAs por tabla
cat("\n--- NAs por bloque ---\n")
cat("Sin matrícula  :", sum(is.na(df_educacion_sede$mat_básica_primaria)), "sedes\n")
cat("Sin personal   :", sum(is.na(df_educacion_sede$personal_cat2)), "sedes\n")
cat("Sin situación  :", sum(is.na(df_educacion_sede$sit_aprobados)), "sedes\n")
cat("Sin TIC        :", sum(is.na(df_educacion_sede$SEDETE_INTERNET)), "sedes\n")
cat("Sin intensidad :", sum(is.na(df_educacion_sede$horas_media)), "sedes\n")

glimpse(df_educacion_sede)

# -----------------------------------------------------------------------------
# INCORPORACIÓN DE RESULTADOS SABER 11 A NIVEL SEDE
# -----------------------------------------------------------------------------
# Fuente: archivo saber11.gpkg (datos espaciales del ICFES)
# Se extrae la tabla, se seleccionan variables desde FECHA en adelante,
# y se une a df_educacion_sede por SEDE_CODIGO = DANE12_SED.

# Lectura del GeoPackage y extracción de tabla
# st_read() lee el archivo espacial; st_drop_geometry() elimina la geometría
# para trabajar solo con la tabla de atributos.

saber11_geo <- st_read(file.path(ruta_base, "pruebassaber11_2024.gpkg"))
saber11      <- st_drop_geometry(saber11_geo)

cat(">>> Saber11 importado:", nrow(saber11), "filas |", ncol(saber11), "columnas\n")

# Selección de variables relevantes
# Conservamos el código DANE de la sede (llave de join) y todas las
# variables desde FECHA en adelante (puntajes, percentiles, etc.)

cols_desde_fecha <- which(names(saber11) == "FECHA")

saber11_join <- saber11 |>
  select(DANE12_SED, all_of(names(saber11)[cols_desde_fecha:ncol(saber11)]))

cat(">>> Saber11 para join:", nrow(saber11_join), "filas |",
    ncol(saber11_join), "columnas\n")

# Join con df_educacion_sede
# left_join conserva todas las sedes; las que no tengan resultados
# ICFES (ej. preescolar, primaria) quedarán con NA.

df_educacion_sede_icfes <- df_educacion_sede |>
  left_join(saber11_join, by = c("SEDE_CODIGO" = "DANE12_SED"))

cat("\n=== DF EDUCACIÓN SEDE + SABER 11 ===\n")
cat("Filas  :", nrow(df_educacion_sede_icfes), "\n")
cat("Columnas:", ncol(df_educacion_sede_icfes), "\n")


# Diagnóstico de match
# Es esperado que muchas sedes no tengan ICFES (solo aplica a grado 11)
sin_match <- sum(is.na(df_educacion_sede_icfes$FECHA))
cat("Sedes sin datos ICFES:", sin_match,
    "(", round(sin_match / nrow(df_educacion_sede_icfes) * 100, 1), "%)\n")
cat("Sedes con datos ICFES:",  nrow(df_educacion_sede_icfes) - sin_match,
    "(", round((nrow(df_educacion_sede_icfes) - sin_match) / nrow(df_educacion_sede_icfes) * 100, 1), "%)\n")

# Filtrar solo sedes con datos ICFES completos
# Eliminamos sedes sin resultados SABER 11 (preescolar, primaria, secundaria
# sin grado 11) ya que no aportan al análisis de trayectorias posmedia.

df_educacion_sede_icfes <- df_educacion_sede_icfes |>
  filter(!is.na(FECHA))

cat("\n=== DF FILTRADO: SOLO SEDES CON ICFES ===\n")
cat("Sedes con ICFES:", nrow(df_educacion_sede_icfes), "\n")
cat("Localidades    :", n_distinct(df_educacion_sede_icfes$CODLOCALIDAD), "\n")

# Eliminamos sedes de Régimen Especial (ej. Fuerzas Militares, Policía)
# que aunque son oficiales, no pertenecen al sistema educativo distrital regular.

df_educacion_sede_icfes <- df_educacion_sede_icfes |>
  filter(NATURALEZA != "Régimen Especial")

cat(">>> Sedes tras excluir Régimen Especial:", nrow(df_educacion_sede_icfes), "\n")
cat(">>> Localidades                        :", n_distinct(df_educacion_sede_icfes$CODLOCALIDAD), "\n")


# -----------------------------------------------------------------------------
# FILTRAR df_seguridad PARA 2024 + SELECCIÓN DE INCIDENTES C4 RELEVANTES
# -----------------------------------------------------------------------------
# Solo conservamos los incidentes C4 relacionados con violencia, delitos
# y situaciones de riesgo para NNAJ, relevantes para la pregunta de investigación.
# Códigos seleccionados: violencia (906, 910, 911), hurtos (904, 905, 912),
# narcóticos (922), riña (934), pandillas (968), porte armas (969),
# menores en riesgo (952, 967), actos obscenos (909), etc.

codigos_c4_seleccionados <- c(
  "c4_611",   # Maltrato
  "c4_903",   # Rapto / Secuestro
  "c4_904",   # Hurto efectuado
  "c4_905",   # Atraco / Hurto en proceso
  "c4_906",   # Violencia sexual
  "c4_909",   # Exhibiciones y/o actos obscenos
  "c4_910",   # Lesiones personales
  "c4_911",   # Disparos
  "c4_912",   # Daños en propiedad pública/privada
  "c4_915",   # Intento/Violación de domicilio
  "c4_922",   # Narcóticos
  "c4_933",   # Delincuente capturado por civil
  "c4_934",   # Riña
  "c4_952",   # Menor o persona abandonada
  "c4_967",   # Menor en establecimiento de mayores
  "c4_968",   # Pandillas juveniles
  "c4_969"    # Porte ilegal de armas
)

df_seguridad_2024 <- df_seguridad |>
  filter(anio == 2024) |>
  select(
    cod_localidad, nom_localidad, anio,
    # Delitos de alto impacto (DAI)
    homicidios, lesiones_personales, hurto_personas,
    hurto_residencias, hurto_automotores, hurto_bicicletas,
    hurto_celulares, hurto_motocicletas, hurto_comercio,
    delitos_sexuales, violencia_intrafamiliar,
    # Incidentes C4 seleccionados
    any_of(codigos_c4_seleccionados),
    total_incidentes_c4
  )

cat(">>> Seguridad 2024:", nrow(df_seguridad_2024), "localidades |",
    ncol(df_seguridad_2024), "columnas\n")
cat(">>> Columnas C4 incluidas:",
    sum(str_detect(names(df_seguridad_2024), "^c4_")), "\n")
print(names(df_seguridad_2024))

write_xlsx(df_seguridad_2024,
           path = file.path(ruta_base, "df_seguridad_2024.xlsx"))

cat(">>> Archivo guardado: df_seguridad_2024.xlsx\n")

# -----------------------------------------------------------------------------
# VERIFICAR COMPATIBILIDAD DE LLAVES ANTES DEL JOIN
# -----------------------------------------------------------------------------
# Revisamos que los códigos de localidad coincidan entre ambas bases.
# df_educacion_sede_icfes usa CODLOCALIDAD
# df_seguridad_2024 usa cod_localidad

cat("\n--- Códigos localidad en sedes ICFES ---\n")
sort(unique(df_educacion_sede_icfes$CODLOCALIDAD))

cat("\n--- Códigos localidad en seguridad 2024 ---\n")
sort(unique(df_seguridad_2024$cod_localidad))

cat("\n--- Localidades en sedes SIN match en seguridad ---\n")
df_educacion_sede_icfes |>
  filter(!CODLOCALIDAD %in% df_seguridad_2024$cod_localidad) |>
  distinct(CODLOCALIDAD, LOCALIDAD) |>
  print()

# -----------------------------------------------------------------------------
# JOIN FINAL: SEDES ICFES + SEGURIDAD 2024
# -----------------------------------------------------------------------------
# Unimos por código de localidad. Cada sede hereda las condiciones de
# seguridad de su localidad en 2024.
# Excluimos la sede con CODLOCALIDAD = NA antes del join.

df_final <- df_educacion_sede_icfes |>
  filter(!is.na(CODLOCALIDAD)) |>
  left_join(
    df_seguridad_2024 |> select(-anio, -nom_localidad),  # evitamos columna nombre duplicada
    by = c("CODLOCALIDAD" = "cod_localidad")
  )

cat("\n=== DF FINAL UNIFICADO ===\n")
cat("Sedes      :", nrow(df_final), "\n")
cat("Columnas   :", ncol(df_final), "\n")
cat("Localidades:", n_distinct(df_final$CODLOCALIDAD), "\n")

# Diagnóstico: sedes sin datos de seguridad
sin_seg <- sum(is.na(df_final$homicidios))
cat("Sedes sin match seguridad:", sin_seg, "\n")

# =============================================================================
# PARTE 3 — INTEGRACIÓN: BASE UNIFICADA SEDE × SEGURIDAD
# =============================================================================
# Une la base educativa (sede) con los datos de seguridad (localidad)
# usando CODLOCALIDAD como llave de unión territorial.
# Producto: df_final_sedes_seguridad.xlsx — base de punto de partida alternativo

# =============================================================================
# =============================================================================
# MODELO DE MODERACIÓN: CARACTERÍSTICAS DE SEDE × ENTORNO TERRITORIAL
# Variable dependiente: P_Puntaje_ (puntaje global Saber 11)
# =============================================================================

library(tidyverse)
library(corrplot)
library(broom)
library(ggplot2)


# -----------------------------------------------------------------------------
# PREPARACIÓN DEL DF ANALÍTICO
# -----------------------------------------------------------------------------
# Seleccionamos solo las variables que entran al modelo y eliminamos NAs.
# Construimos variables derivadas útiles:
#   - tasa_desercion: proporción de desertores sobre total de estudiantes
#   - tasa_reprobacion: proporción de reprobados
#   - ratio_docente: alumnos por docente (proxy de carga docente) y por rol (no solo docentes)

# Total de personal sumando todas las categorías disponibles
df_final <- df_final |>
  mutate(
    total_personal = rowSums(across(c(personal_cat1, personal_cat2,
                                      personal_cat4, personal_cat5,
                                      personal_cat7)), na.rm = TRUE),
    matricula_total = rowSums(across(starts_with("mat_")), na.rm = TRUE)
  )


# Reemplazar intensidad_horas_promedio por horas_media (nivel media = relevante para Saber 11)
# y crear un promedio general de horas como variable adicional

df_final <- df_final |>
  mutate(horas_promedio = rowMeans(across(starts_with("horas_")), na.rm = TRUE))

df_modelo <- df_final |>
  mutate(
    total_estudiantes = sit_aprobados + sit_desertores + sit_reprobados +
      sit_transferidostransladados,
    tasa_desercion    = if_else(total_estudiantes > 0,
                                sit_desertores / total_estudiantes, NA_real_),
    tasa_reprobacion  = if_else(total_estudiantes > 0,
                                sit_reprobados / total_estudiantes, NA_real_),
    ratio_docente     = if_else(total_personal > 0,
                                matricula_total / total_personal, NA_real_),
    estrato_num       = suppressWarnings(as.numeric(as.character(estrato_geo))),
    indice_tic        = (SEDETE_ELECTRICIDAD + SEDETE_INTERNET +
                           SEDETE_AULAS_INFOR  + SEDETE_EQUIPO_COMPUTO) / 4,
    delitos_total     = homicidios + lesiones_personales + hurto_personas +
      delitos_sexuales + violencia_intrafamiliar
  ) |>
  select(
    SEDE_CODIGO, SEDE_NOMBRE, CODLOCALIDAD, LOCALIDAD,
    P_Puntaje_,
    delitos_total, homicidios, hurto_personas,
    lesiones_personales, delitos_sexuales, violencia_intrafamiliar,
    total_incidentes_c4,
    estrato_num, indice_tic, ratio_docente,
    horas_media, horas_promedio,          # <-- corregido
    jornada_única_oficiales, jornada_mañana, jornada_tarde,
    tasa_desercion, tasa_reprobacion, matricula_total
  ) |>
  filter(!is.na(P_Puntaje_),
         !is.na(delitos_total),
         !is.na(estrato_num))

cat(">>> Sedes para el modelo:", nrow(df_modelo), "\n")
cat(">>> NAs por variable:\n")
df_modelo |>
  summarise(across(everything(), ~sum(is.na(.)))) |>
  pivot_longer(everything(), names_to = "variable", values_to = "n_na") |>
  filter(n_na > 0) |>
  print()

# -----------------------------------------------------------------------------
# ESTANDARIZACIÓN DE VARIABLES CONTINUAS
# -----------------------------------------------------------------------------
# Estandarizamos (z-score) para que los coeficientes sean comparables
# y las interacciones sean interpretables.

df_modelo_std <- df_modelo |>
  mutate(across(
    c(delitos_total, homicidios, hurto_personas, lesiones_personales,
      delitos_sexuales, violencia_intrafamiliar, total_incidentes_c4,
      indice_tic, ratio_docente, horas_media,
      tasa_desercion, tasa_reprobacion, matricula_total, estrato_num),
    ~ scale(.)[,1],
    .names = "z_{.col}"
  ))


# -----------------------------------------------------------------------------
# ANÁLISIS EXPLORATORIO: CORRELACIONES
# -----------------------------------------------------------------------------
# Revisamos correlaciones entre variables antes de modelar.

vars_cor <- df_modelo_std |>
  select(P_Puntaje_, starts_with("z_")) |>
  drop_na()

cat("\n>>> Correlaciones con P_Puntaje_:\n")
cor(vars_cor)["P_Puntaje_", ] |> sort() |> round(3) |> print()


# -----------------------------------------------------------------------------
# MODELOS DE REGRESIÓN
# -----------------------------------------------------------------------------

# Modelo 1: Solo entorno territorial --
# Línea base: ¿el entorno predice los puntajes sin considerar la sede?
modelo_1 <- lm(P_Puntaje_ ~
                 z_delitos_total +
                 z_total_incidentes_c4 +
                 z_tasa_desercion,
               data = df_modelo_std)

# Modelo 2: Entorno + características de sede --
# ¿Las características de la sede agregan poder explicativo?
modelo_2 <- lm(P_Puntaje_ ~
                 z_delitos_total +
                 z_total_incidentes_c4 +
                 z_tasa_desercion +
                 z_estrato_num +
                 z_indice_tic +
                 z_ratio_docente +
                 z_intensidad_horas_promedio,
               data = df_modelo_std)

# Modelo 3: Moderación (interacciones entorno × sede) --
# ¿Las características de la sede MODERAN el efecto del entorno?
modelo_3 <- lm(P_Puntaje_ ~
                 z_delitos_total +
                 z_total_incidentes_c4 +
                 z_tasa_desercion +
                 z_estrato_num +
                 z_indice_tic +
                 z_ratio_docente +
                 z_intensidad_horas_promedio +
                 # Interacciones: entorno × moderador
                 z_delitos_total : z_indice_tic +
                 z_delitos_total : z_estrato_num +
                 z_delitos_total : z_ratio_docente +
                 z_delitos_total : z_intensidad_horas_promedio,
               data = df_modelo_std)

# -----------------------------------------------------------------------------
# COMPARACIÓN DE MODELOS
# -----------------------------------------------------------------------------

cat("\n=== RESUMEN COMPARATIVO DE MODELOS ===\n")
cat("\n--- Modelo 1: Solo entorno ---\n")
summary(modelo_1)

cat("\n--- Modelo 2: Entorno + sede ---\n")
summary(modelo_2)

cat("\n--- Modelo 3: Moderación ---\n")
summary(modelo_3)

# Comparación de R² y AIC
cat("\n--- Tabla comparativa ---\n")
tibble(
  modelo = c("M1: Solo entorno", "M2: Entorno + sede", "M3: Moderación"),
  R2     = c(summary(modelo_1)$r.squared,
             summary(modelo_2)$r.squared,
             summary(modelo_3)$r.squared),
  R2_adj = c(summary(modelo_1)$adj.r.squared,
             summary(modelo_2)$adj.r.squared,
             summary(modelo_3)$adj.r.squared),
  AIC    = c(AIC(modelo_1), AIC(modelo_2), AIC(modelo_3))
) |> mutate(across(where(is.numeric), ~round(., 3))) |> print()

# Test ANOVA para comparar modelos anidados
cat("\n--- ANOVA entre modelos ---\n")
anova(modelo_1, modelo_2, modelo_3)



# =============================================================================
# PARTE 4 — ÍNDICES DE INSEGURIDAD Y VARIABLES DERIVADAS
# =============================================================================

# Se construyen:
#   - Índice de violencia estructural (DAI ponderado, por 100k hab.)
#   - Índice de entorno escolar (incidentes C4 relevantes, por 100k hab.)
#   - Ratios de personal por rol (docentes, directivos, orientadores, etc.)
#   - Índice TIC (aulas informática + equipos + plan TIC)
#   - Índice de servicios (PAE + electricidad + internet)
#   - Tasas académicas a nivel sede (deserción, reprobación, aprobación)
#   - Proporciones de poblaciones diferenciales (discapacidad, desplazados, étnicos)
# =============================================================================

if (!exists("df_final")) {
  cat(">>> df_final no encontrado. Cargando desde df_final_sedes_seguridad.xlsx...\n")
  df_final <- read_excel(paste0(ruta_base, "df_final_sedes_seguridad.xlsx"))
} else {
  cat(">>> df_final ya existe en el entorno (continuando desde Parte 3).\n")
}
cat(">>> df_final:", nrow(df_final), "sedes |", ncol(df_final), "columnas\n")

# =============================================================================
# PARTE A — INDICES DE INSEGURIDAD POR LOCALIDAD + UNION A NIVEL SEDE
# =============================================================================

# -----------------------------------------------------------------------------
# A.1 CARGAR Y LIMPIAR POBLACION 2024 POR LOCALIDAD
# -----------------------------------------------------------------------------

pob_raw <- read_excel(
  paste0(ruta_base, "poblacionbog.xlsx"),
  skip      = 11,
  col_names = FALSE
)

nombres <- pob_raw[1, ] |> as.character()
pob_raw <- pob_raw[-1, ]
colnames(pob_raw) <- nombres

pob_2024 <- pob_raw |>
  filter(AREA == "Total", AÑO == 2024) |>
  select(
    cod_localidad   = COD_LOC,
    nom_localidad   = NOM_LOC,
    poblacion_total = TOTAL
  ) |>
  mutate(
    cod_localidad   = as.integer(cod_localidad),
    poblacion_total = as.numeric(poblacion_total)
  )

cat(">>> Poblacion 2024 cargada:", nrow(pob_2024), "localidades\n")


# -----------------------------------------------------------------------------
# A.2 EXTRAER DELITOS Y C4 A NIVEL LOCALIDAD
# -----------------------------------------------------------------------------
# df_final esta a nivel sede, pero los valores de seguridad se repiten para
# todas las sedes de una misma localidad. distinct() evita duplicar conteos.

delitos_local <- df_final |>
  distinct(CODLOCALIDAD, .keep_all = TRUE) |>
  select(
    cod_localidad = CODLOCALIDAD,
    homicidios, lesiones_personales, hurto_personas,
    hurto_residencias, hurto_automotores, hurto_bicicletas,
    hurto_celulares, hurto_motocicletas, hurto_comercio,
    delitos_sexuales, violencia_intrafamiliar, total_incidentes_c4
  ) |>
  mutate(cod_localidad = as.integer(cod_localidad))

c4_escolar_local <- df_final |>
  distinct(CODLOCALIDAD, .keep_all = TRUE) |>
  mutate(
    c4_entorno_escolar = rowSums(
      across(c(c4_611, c4_906, c4_909, c4_910, c4_911, c4_922,
               c4_934, c4_952, c4_967, c4_968, c4_969)),
      na.rm = TRUE
    )
  ) |>
  select(cod_localidad = CODLOCALIDAD, c4_entorno_escolar) |>
  mutate(cod_localidad = as.integer(cod_localidad))

cat(">>> Localidades con datos de seguridad:", nrow(delitos_local), "\n")


# -----------------------------------------------------------------------------
# A.3 CONSTRUIR INDICES DE INSEGURIDAD POR LOCALIDAD
# -----------------------------------------------------------------------------
# Indice 1 - Violencia estructural (fuente: DAI), ponderado por gravedad,
#            tasa por 100.000 habitantes. Pesos: homicidios x4, delitos
#            sexuales x3, lesiones x2, VIF x2, hurto personas x1.
# Indice 2 - Entorno escolar (fuente: C4 relevante para NNAJ), tasa por
#            100.000 habitantes.

df_indices_local <- delitos_local |>
  left_join(c4_escolar_local, by = "cod_localidad") |>
  left_join(pob_2024,         by = "cod_localidad") |>
  mutate(
    tasa_homicidios       = homicidios              / poblacion_total * 100000,
    tasa_lesiones         = lesiones_personales     / poblacion_total * 100000,
    tasa_hurto_personas   = hurto_personas          / poblacion_total * 100000,
    tasa_delitos_sexuales = delitos_sexuales        / poblacion_total * 100000,
    tasa_vif              = violencia_intrafamiliar / poblacion_total * 100000,
    tasa_incidentes_c4    = total_incidentes_c4     / poblacion_total * 100000,
    
    indice_violencia_estructural = (
      tasa_homicidios       * 4 +
        tasa_delitos_sexuales * 3 +
        tasa_lesiones         * 2 +
        tasa_vif              * 2 +
        tasa_hurto_personas   * 1
    ),
    
    indice_entorno_escolar = c4_entorno_escolar / poblacion_total * 100000,
    
    cat_violencia = case_when(
      indice_violencia_estructural >= quantile(indice_violencia_estructural, 0.75, na.rm = TRUE) ~ "Critica",
      indice_violencia_estructural >= quantile(indice_violencia_estructural, 0.50, na.rm = TRUE) ~ "Alta",
      indice_violencia_estructural >= quantile(indice_violencia_estructural, 0.25, na.rm = TRUE) ~ "Media",
      TRUE ~ "Baja"
    ),
    cat_entorno = case_when(
      indice_entorno_escolar >= quantile(indice_entorno_escolar, 0.75, na.rm = TRUE) ~ "Critico",
      indice_entorno_escolar >= quantile(indice_entorno_escolar, 0.50, na.rm = TRUE) ~ "Alto",
      indice_entorno_escolar >= quantile(indice_entorno_escolar, 0.25, na.rm = TRUE) ~ "Moderado",
      TRUE ~ "Bajo"
    ),
    cuadrante_riesgo = case_when(
      cat_entorno %in% c("Critico","Alto") & cat_violencia %in% c("Critica","Alta") ~ "Doble riesgo",
      cat_entorno %in% c("Critico","Alto") ~ "Riesgo entorno",
      cat_violencia %in% c("Critica","Alta") ~ "Riesgo estructural",
      TRUE ~ "Riesgo bajo"
    )
  ) |>
  mutate(across(where(is.numeric), ~round(., 2)))

cat("\n=== INDICES DE INSEGURIDAD POR LOCALIDAD ===\n")
df_indices_local |>
  select(nom_localidad, poblacion_total,
         indice_violencia_estructural, cat_violencia,
         indice_entorno_escolar, cat_entorno, cuadrante_riesgo) |>
  arrange(desc(indice_violencia_estructural)) |>
  print(n = 20)


# -----------------------------------------------------------------------------
# A.4 PEGAR INDICES A NIVEL SEDE Y RENOMBRAR
# -----------------------------------------------------------------------------

cols_nuevas <- df_indices_local |>
  select(
    cod_localidad, poblacion_total,
    tasa_homicidios, tasa_lesiones, tasa_hurto_personas,
    tasa_delitos_sexuales, tasa_vif, tasa_incidentes_c4,
    c4_entorno_escolar, indice_entorno_escolar, cat_entorno,
    indice_violencia_estructural, cat_violencia, cuadrante_riesgo
  )

df_datajam <- df_final |>
  mutate(CODLOCALIDAD = as.integer(CODLOCALIDAD)) |>
  left_join(cols_nuevas, by = c("CODLOCALIDAD" = "cod_localidad")) |>
  rename(
    DANE_SEDE        = SEDE_CODIGO,
    SEDE             = SEDE_NOMBRE,
    ID_LOC           = LOCALIDAD_ID,
    COD_LOC          = CODLOCALIDAD,
    MAT_BAS_SEC      = mat_básica_secundaria,
    MAT_MED          = mat_media,
    MAT_BAS_PRIM     = mat_básica_primaria,
    MAT_PRE          = mat_preescolar,
    MAT_CLEI         = mat_clei_ciclos_lectivos_integrados_decreto_de,
    JORNADA_U        = jornada_única_oficiales,
    JORNADA_M        = jornada_mañana,
    JORNADA_T        = jornada_tarde,
    JORNADA_N        = jornada_nocturna,
    JORNADA_FDS      = jornada_fin_de_semana,
    DIRECTIVOS       = personal_cat1,
    DOCENTES_AULA    = personal_cat2,
    ADMIN            = personal_cat3,
    APOYO_AULAS      = personal_cat5,
    ORIENTADORES     = personal_cat7,
    LID_APOYO        = personal_cat4,
    DOC_ADMIN        = personal_cat6,
    APROB            = sit_aprobados,
    DESERTORES       = sit_desertores,
    REPROBADOS       = sit_reprobados,
    TRASLADOS        = sit_transferidostransladados,
    ELECTRICIDAD     = SEDETE_ELECTRICIDAD,
    TELEVISION       = SEDETE_TELEVISION,
    TELEFONO         = SEDETE_LINEA_TEL,
    INTERNET         = SEDETE_INTERNET,
    HORAS_BASICA_SEC = horas_básica_secundaria,
    HORAS_MEDIA      = horas_media,
    HORAS_BASICA_PRIM= horas_básica_primaria,
    HORAS_PRE        = horas_preescolar,
    ICFES            = P_Puntaje_,
    EE               = indice_entorno_escolar,
    INDICE_EE        = indice_entorno_escolar,
    INDICE_VIOLENCIA = indice_violencia_estructural,
    TASA_HOMICIDIO   = tasa_homicidios,
    TASA_LESIONES    = tasa_lesiones,
    TASA_HURTO       = tasa_hurto_personas,
    TASA_DELITOS_SEX = tasa_delitos_sexuales,
    TASA_VIF         = tasa_vif,
    TASA_C4          = tasa_incidentes_c4,
    CUADRANTE_RIESGO = cuadrante_riesgo
  )

write.xlsx(df_datajam, paste0(ruta_base, "df_datajam.xlsx"), overwrite = TRUE)

cat("\n>>> df_datajam.xlsx guardado:", nrow(df_datajam), "sedes |",
    ncol(df_datajam), "columnas\n")
cat("=============================================================\n")
cat("  PARTE A COMPLETADA — indices + union a nivel sede\n")
cat("=============================================================\n\n")




# =============================================================================
# PARTE 5 — TASAS DE DESERCIÓN Y REPROBACIÓN POR LOCALIDAD
# =============================================================================
# Fuente: SED Bogotá (GeoPackage)
# Se agregan las tasas oficiales de deserción y reprobación a nivel de
# localidad, que sirven como variables predictoras del entorno territorial
# (distintas de las tasas a nivel de sede calculadas en la Parte 4).
# Producto: columnas TASA_DESERCION_LOC y TASA_REPROBACION_LOC en la base
# =============================================================================
# =============================================================================
# AGREGAR TASA DE DESERCION Y REPROBACION A NIVEL LOCALIDAD
# =============================================================================

library(sf)
library(tidyverse)
library(readxl)
library(openxlsx)

ruta <- "/Users/manuelaparra/Documents/OCE-SED/Bases de Datos/"


# -----------------------------------------------------------------------------
# 1. CARGAR BASE PRINCIPAL
# -----------------------------------------------------------------------------

df <- read_excel(paste0(ruta_base, "datajam1.xlsx"))
cat("Base principal:", nrow(df), "sedes |", ncol(df), "columnas\n")


# -----------------------------------------------------------------------------
# 2. CARGAR GPKG Y EXTRAER TABLA SIN GEOMETRIA
# -----------------------------------------------------------------------------

deser_geo <- st_read(paste0(ruta_base, "tdesercionof.gpkg"))
repro_geo  <- st_read(paste0(ruta_base, "treprobacionof.gpkg"))

deser <- st_drop_geometry(deser_geo)
repro <- st_drop_geometry(repro_geo)

cat("Desercion: ", nrow(deser), "localidades\n")
cat("Reprobacion:", nrow(repro), "localidades\n")


# -----------------------------------------------------------------------------
# 3. CALCULAR TASA TOTAL POR LOCALIDAD
# -----------------------------------------------------------------------------
# Thombre y Tmujer son los totales por sexo para la localidad.
# Promedio de ambos = tasa general de la localidad.
# Las tasas ya vienen en porcentaje (ej: 3.8 = 3.8%)

deser_local <- deser |>
  select(COD_LOCA, Thombre_des = Thombre, Tmujer_des = Tmujer) |>
  mutate(
    TASA_DESERCION_LOC = round((Thombre_des + Tmujer_des) / 2, 2),
    COD_LOCA = str_pad(as.character(COD_LOCA), 2, pad = "0")
  )

repro_local <- repro |>
  select(COD_LOCA, Thombre_rep = Thombre, Tmujer_rep = Tmujer) |>
  mutate(
    TASA_REPROBACION_LOC = round((Thombre_rep + Tmujer_rep) / 2, 2),
    COD_LOCA = str_pad(as.character(COD_LOCA), 2, pad = "0")
  )

cat("\n=== TASAS POR LOCALIDAD ===\n")
deser_local |>
  left_join(repro_local, by = "COD_LOCA") |>
  select(COD_LOCA, TASA_DESERCION_LOC, TASA_REPROBACION_LOC) |>
  arrange(COD_LOCA) |>
  print()


# -----------------------------------------------------------------------------
# 4. DICCIONARIO: codigo → nombre de localidad
# -----------------------------------------------------------------------------
# Nombres exactos tal como aparecen en df$LOCALIDAD
# (verificados con print(sort(unique(df$LOCALIDAD))))

diccionario <- tibble(
  COD_LOCA  = c("01","02","03","04","05","06","07","08","09","10",
                "11","12","13","14","15","16","17","18","19","20"),
  LOCALIDAD = c(
    "USAQUEN",
    "CHAPINERO",
    "SANTAFE",
    "SAN CRISTOBAL",
    "USME",
    "TUNJUELITO",
    "BOSA",
    "KENNEDY",
    "FONTIBON",
    "ENGATIVA",
    "SUBA",
    "BARRIOS UNIDOS",
    "TEUSAQUILLO",
    "LOS MARTIRES",
    "ANTONIO NARI\u00d1O",   # \u00d1 = N con tilde (evita problemas de encoding)
    "PUENTE ARANDA",
    "CANDELARIA",
    "RAFAEL URIBE URIBE",
    "CIUDAD BOLIVAR",
    "SUMAPAZ"
  )
)

# Pegar nombre a los datos de localidad
deser_local <- deser_local |>
  left_join(diccionario, by = "COD_LOCA")

repro_local <- repro_local |>
  left_join(diccionario, by = "COD_LOCA")


# -----------------------------------------------------------------------------
# 5. VERIFICAR QUE LOS NOMBRES CALZAN CON df
# -----------------------------------------------------------------------------

cat("\n=== VERIFICACION DE NOMBRES ===\n")
cat("En diccionario pero NO en df (solo Sumapaz es esperado):\n")
print(setdiff(diccionario$LOCALIDAD, unique(df$LOCALIDAD)))

cat("\nEn df pero NO en diccionario (debe estar vacio):\n")
print(setdiff(unique(df$LOCALIDAD), diccionario$LOCALIDAD))


# -----------------------------------------------------------------------------
# 6. UNION A LA BASE PRINCIPAL POR NOMBRE DE LOCALIDAD
# -----------------------------------------------------------------------------

df <- df |>
  left_join(
    deser_local |> select(LOCALIDAD, TASA_DESERCION_LOC),
    by = "LOCALIDAD"
  ) |>
  left_join(
    repro_local |> select(LOCALIDAD, TASA_REPROBACION_LOC),
    by = "LOCALIDAD"
  )


# -----------------------------------------------------------------------------
# 7. VERIFICAR RESULTADO
# -----------------------------------------------------------------------------

cat("\n=== VERIFICACION DEL JOIN ===\n")
cat("Sedes sin TASA_DESERCION_LOC :",
    sum(is.na(df$TASA_DESERCION_LOC)), "\n")
cat("Sedes sin TASA_REPROBACION_LOC:",
    sum(is.na(df$TASA_REPROBACION_LOC)), "\n")

cat("\nEstadisticas de las tasas a nivel localidad:\n")
df |>
  select(TASA_DESERCION_LOC, TASA_REPROBACION_LOC) |>
  summary() |>
  print()

cat("\nMuestra (una sede por localidad):\n")
df |>
  distinct(LOCALIDAD, .keep_all = TRUE) |>
  select(LOCALIDAD, TASA_DESERCION_LOC, TASA_REPROBACION_LOC) |>
  arrange(LOCALIDAD) |>
  print()


# -----------------------------------------------------------------------------
# 8. GUARDAR
# -----------------------------------------------------------------------------

write.xlsx(df, paste0(ruta_base, "datajam1_v2.xlsx"), overwrite = TRUE)

cat("\n")
cat("=============================================================\n")
cat("  LISTO\n")
cat("=============================================================\n")
cat("  Archivo: datajam1_v2.xlsx\n")
cat("  Columnas nuevas:\n")
cat("    TASA_DESERCION_LOC   - tasa desercion a nivel localidad (%)\n")
cat("    TASA_REPROBACION_LOC - tasa reprobacion a nivel localidad (%)\n")
cat("  Nota: estas tasas son iguales para todas las sedes\n")
cat("  de una misma localidad (dato territorial, no de sede).\n")
cat("=============================================================\n")

# =============================================================================
# PARTE 6 — REGRESIONES: EFECTO DEL ENTORNO SOBRE SABER 11
# =============================================================================
# Se estiman regresiones lineales en dos bloques:
#
# BLOQUE A — Regresiones simples (sin controles):
#   ICFES ~ predictor_entorno
#   Predictores: INDICE_EE, INDICE_VIOLENCIA,
#                TASA_DESERCION_LOC, TASA_REPROBACION_LOC
#
# BLOQUE B — Con controles sociodemográficos:
#   ICFES ~ predictor_entorno + INDICE_SERVICIOS +
#           PROP_DISCAPACIDAD + PROP_DESPLAZADOS + PROP_ETNICOS
#
# La comparación sin/con controles muestra cuánto cambia el efecto del
# entorno al descontar las características sociodemográficas de la sede.
# Todas las variables continuas están estandarizadas (z-scores).
# Umbral de significancia: p < 0.05
# =============================================================================

# Convertir columnas de texto con coma a numérico (problema de configuración regional)
cols_conv <- c("TASA_DESERCION_LOC", "TASA_REPROBACION_LOC", "INDICE_SERVICIOS",
               "RATIO_DOC_AULA", "RATIO_DIRECTIVOS", "RATIO_ORIENTADORES",
               "RATIO_APOYO", "RATIO_LID_APOYO", "INDICE_TIC")

df <- df |>
  mutate(across(
    all_of(intersect(cols_conv, names(df))),
    ~ as.numeric(str_replace_all(as.character(.), ",", "."))
  ))

# Estandarización (z-scores): beta = cambio en ICFES por 1 DS de cambio en X
vars_std <- c(
  "INDICE_EE", "INDICE_VIOLENCIA",
  "TASA_DESERCION_LOC", "TASA_REPROBACION_LOC",
  "INDICE_SERVICIOS", "PROP_DISCAPACIDAD", "PROP_DESPLAZADOS", "PROP_ETNICOS",
  "HORAS_BASICA_SEC", "HORAS_MEDIA",
  "RATIO_DOC_AULA", "RATIO_DIRECTIVOS", "RATIO_ORIENTADORES",
  "RATIO_APOYO", "RATIO_LID_APOYO", "INDICE_TIC"
)

vars_std_ok <- vars_std[
  vars_std %in% names(df) &
    map_lgl(vars_std[vars_std %in% names(df)],
            ~ sd(df[[.x]], na.rm = TRUE) > 0)
]

df <- df |>
  mutate(across(all_of(vars_std_ok),
                ~ as.numeric(scale(.)), .names = "z_{.col}"))

cat(">>> Estandarización OK:", length(vars_std_ok), "variables\n")

# Dataset limpio para modelos
controles_formula <- "z_INDICE_SERVICIOS + z_PROP_DISCAPACIDAD + z_PROP_DESPLAZADOS + z_PROP_ETNICOS"

df_limpio <- df |>
  drop_na(z_INDICE_EE, z_INDICE_VIOLENCIA,
          z_TASA_DESERCION_LOC, z_TASA_REPROBACION_LOC,
          z_INDICE_SERVICIOS, z_PROP_DISCAPACIDAD,
          z_PROP_DESPLAZADOS, z_PROP_ETNICOS)

cat(">>> N para modelos:", nrow(df_limpio), "sedes\n")

# Función auxiliar para significancia
sig_stars <- function(p) {
  case_when(p < 0.001 ~ "***", p < 0.01 ~ "**",
            p < 0.05 ~ "*",   p < 0.1  ~ ".",
            TRUE ~ "ns")
}

# Predictores del entorno
predictores_entorno <- list(
  "Indice entorno escolar C4"    = "z_INDICE_EE",
  "Indice violencia estructural" = "z_INDICE_VIOLENCIA",
  "Tasa desercion (localidad)"   = "z_TASA_DESERCION_LOC",
  "Tasa reprobacion (localidad)" = "z_TASA_REPROBACION_LOC"
)

# BLOQUE A y B: tabla comparativa sin vs con controles
cat("\n=== BLOQUE A+B: REGRESIONES SIN VS CON CONTROLES ===\n")

resultados_reg <- map_dfr(names(predictores_entorno), function(nombre) {
  var <- predictores_entorno[[nombre]]

  m_sin <- lm(as.formula(paste("ICFES ~", var)), data = df_limpio)
  m_con <- lm(as.formula(paste("ICFES ~", var, "+", controles_formula)),
              data = df_limpio)

  b_sin <- tidy(m_sin) |> filter(term == var)
  b_con <- tidy(m_con) |> filter(term == var)

  tibble(
    Predictor   = nombre,
    beta_sin    = round(b_sin$estimate, 3),
    p_sin       = round(b_sin$p.value,  3),
    sig_sin     = sig_stars(b_sin$p.value),
    R2_sin      = round(summary(m_sin)$r.squared, 3),
    beta_con    = round(b_con$estimate, 3),
    p_con       = round(b_con$p.value,  3),
    sig_con     = sig_stars(b_con$p.value),
    R2_con      = round(summary(m_con)$r.squared, 3),
    cambio_beta = round(b_con$estimate - b_sin$estimate, 3),
    N           = nrow(df_limpio)
  )
})

print(resultados_reg)

# Modelo conjunto: todos los predictores + controles
m_conjunto <- lm(as.formula(paste(
  "ICFES ~ z_INDICE_EE + z_INDICE_VIOLENCIA +",
  "z_TASA_DESERCION_LOC + z_TASA_REPROBACION_LOC +",
  controles_formula)),
  data = df_limpio)

cat("\n=== MODELO CONJUNTO (todos los predictores + controles) ===\n")
print(summary(m_conjunto))


# =============================================================================
# PARTE 7 — MODERACIONES: CARACTERÍSTICAS DE SEDE COMO COLCHONES
# =============================================================================
# Pregunta: ¿las características institucionales de la sede amortiguan
# el efecto negativo del entorno adverso sobre el ICFES?
#
# Para cada combinación predictor_entorno × colchon_sede se estima:
#   ICFES ~ predictor + controles_SD + colchon + predictor:colchon
#
# La interacción (predictor:colchon) es la clave:
#   - Si beta_inter es NEGATIVO y sig con un RATIO → menos docentes amplifica el daño
#     (al revés: más docentes amortigua, porque ratio alto = menos personal)
#   - Si beta_inter es POSITIVO y sig con TIC/horas/jornada → ese recurso amortigua
#
# Colchones evaluados:
#   - Jornada: JORNADA_U, JORNADA_M, JORNADA_T, JORNADA_N, JORNADA_FDS
#   - Horas: HORAS_BASICA_SEC, HORAS_MEDIA
#   - Personal (ratios): RATIO_DOC_AULA, RATIO_DIRECTIVOS, RATIO_ORIENTADORES,
#                        RATIO_APOYO, RATIO_LID_APOYO
#   - Recursos: INDICE_TIC
# =============================================================================

colchones_cont  <- intersect(
  c("z_HORAS_BASICA_SEC","z_HORAS_MEDIA",
    "z_RATIO_DOC_AULA","z_RATIO_DIRECTIVOS","z_RATIO_ORIENTADORES",
    "z_RATIO_APOYO","z_RATIO_LID_APOYO","z_INDICE_TIC"),
  names(df_limpio)
)
colchones_dummy <- intersect(
  c("JORNADA_U","JORNADA_M","JORNADA_T","JORNADA_N","JORNADA_FDS"),
  names(df_limpio)
)
colchones_ok <- c(colchones_cont, colchones_dummy)

# Nombres legibles para la tabla de resultados
nombres_colchones <- c(
  "z_HORAS_BASICA_SEC"   = "Horas basica secundaria",
  "z_HORAS_MEDIA"        = "Horas media",
  "z_RATIO_DOC_AULA"     = "Ratio est./docente aula",
  "z_RATIO_DIRECTIVOS"   = "Ratio est./directivo",
  "z_RATIO_ORIENTADORES" = "Ratio est./orientador",
  "z_RATIO_APOYO"        = "Ratio est./docente apoyo",
  "z_RATIO_LID_APOYO"    = "Ratio est./lider apoyo",
  "z_INDICE_TIC"         = "Indice TIC",
  "JORNADA_U"            = "Jornada unica",
  "JORNADA_M"            = "Jornada manana",
  "JORNADA_T"            = "Jornada tarde",
  "JORNADA_N"            = "Jornada nocturna",
  "JORNADA_FDS"          = "Jornada fin de semana"
)

df_mod <- df_limpio |> drop_na(all_of(colchones_cont))
cat(">>> N para moderaciones:", nrow(df_mod), "sedes\n")

# Correr moderaciones: un modelo por predictor × colchon
resultados_mod <- list()

for (nombre_pred in names(predictores_entorno)) {
  var_pred <- predictores_entorno[[nombre_pred]]

  df_base <- df_mod |> drop_na(all_of(var_pred))
  m_base  <- lm(as.formula(paste("ICFES ~", var_pred, "+", controles_formula)),
                data = df_base)
  b_ref   <- tidy(m_base) |> filter(term == var_pred)

  # Fila base (referencia sin colchon)
  resultados_mod[[paste0(nombre_pred, "_BASE")]] <- tibble(
    Predictor    = nombre_pred,
    Colchon      = "--- BASE (sin colchon) ---",
    N            = nrow(df_base),
    beta_pred    = round(b_ref$estimate, 3),
    p_pred       = round(b_ref$p.value,  3),
    sig_pred     = sig_stars(b_ref$p.value),
    beta_colchon = NA_real_, p_colchon = NA_real_, sig_colchon = "",
    beta_inter   = NA_real_, p_inter   = NA_real_, sig_inter   = ""
  )

  for (colchon in colchones_ok) {
    df_c   <- df_base |> drop_na(all_of(colchon))
    f_mod  <- as.formula(paste("ICFES ~", var_pred, "+", controles_formula,
                               "+", colchon, "+",
                               paste0(var_pred, ":", colchon)))
    m_mod  <- tryCatch(lm(f_mod, data = df_c), error = function(e) NULL)
    if (is.null(m_mod)) next

    coefs   <- tidy(m_mod)
    b_pred  <- coefs |> filter(term == var_pred)
    b_col   <- coefs |> filter(term == colchon)
    b_inter <- coefs |> filter(str_detect(term, ":"))

    resultados_mod[[paste0(nombre_pred, "_", colchon)]] <- tibble(
      Predictor    = nombre_pred,
      Colchon      = nombres_colchones[colchon],
      N            = nrow(df_c),
      beta_pred    = round(b_pred$estimate,  3),
      p_pred       = round(b_pred$p.value,   3),
      sig_pred     = sig_stars(b_pred$p.value),
      beta_colchon = if(nrow(b_col)>0)  round(b_col$estimate,  3) else NA_real_,
      p_colchon    = if(nrow(b_col)>0)  round(b_col$p.value,   3) else NA_real_,
      sig_colchon  = if(nrow(b_col)>0)  sig_stars(b_col$p.value) else "",
      beta_inter   = if(nrow(b_inter)>0) round(b_inter$estimate, 3) else NA_real_,
      p_inter      = if(nrow(b_inter)>0) round(b_inter$p.value,  3) else NA_real_,
      sig_inter    = if(nrow(b_inter)>0) sig_stars(b_inter$p.value) else ""
    )
  }
}

moderaciones <- bind_rows(resultados_mod)

cat("\n=== MODERACIONES SIGNIFICATIVAS (p_inter < 0.05) ===\n")
moderaciones |>
  filter(!is.na(p_inter), p_inter < 0.05) |>
  select(Predictor, Colchon, beta_inter, p_inter, sig_inter) |>
  print()


# =============================================================================
# PARTE 8 — EXPORTAR RESULTADOS Y BASE PARA POWER BI
# =============================================================================
# Productos:
#   - tabla_comparativa.xlsx  → regresiones sin vs con controles
#   - moderaciones.xlsx       → resultados de moderaciones
#   - BASE_POWERBI.xlsx       → base consolidada (una fila por sede)
# =============================================================================

# ── 8.1 ICFES PREDICHO Y RESIDUOS (para identificar sobre/sub-rendimiento) ──
# Usamos el modelo conjunto como referencia.
# Residuo > 0 = sede que rinde MÁS de lo esperado dado su entorno
# Residuo < 0 = sede que rinde MENOS de lo esperado dado su entorno

df_limpio <- df_limpio |>
  mutate(
    ICFES_PREDICHO = round(fitted(m_conjunto), 2),
    RESIDUO        = round(resid(m_conjunto),  2),
    RENDIMIENTO    = case_when(
      RESIDUO >  10 ~ "Sobre-rinde",
      RESIDUO < -10 ~ "Sub-rinde",
      TRUE          ~ "Esperado"
    )
  )

cat("\n=== DISTRIBUCIÓN DE RENDIMIENTO ===\n")
print(table(df_limpio$RENDIMIENTO))

cat("\n=== TOP 10 SEDES QUE MÁS SOBRE-RINDEN ===\n")
df_limpio |>
  slice_max(RESIDUO, n = 10) |>
  select(SEDE, LOCALIDAD, ICFES, ICFES_PREDICHO, RESIDUO, CUADRANTE_RIESGO) |>
  print()

# ── 8.2 GUARDAR TABLA COMPARATIVA ────────────────────────────────────────────
write.xlsx(
  list(
    "Regresiones"  = resultados_reg,
    "Moderaciones" = moderaciones
  ),
  paste0(ruta_base, "resultados_estadisticos.xlsx"),
  overwrite = TRUE
)
cat(">>> Guardado: resultados_estadisticos.xlsx\n")

# ── 8.3 BASE CONSOLIDADA PARA POWER BI ───────────────────────────────────────
# Una fila por sede con todas las variables necesarias para el dashboard.
# Incluye: identificadores, ICFES, predicho y residuo, contexto territorial,
# características de sede, personal, poblaciones diferenciales.

# Unir predicho y residuo a la base completa
df_powerbi <- df |>
  left_join(
    df_limpio |> select(DANE_SEDE, ICFES_PREDICHO, RESIDUO, RENDIMIENTO),
    by = "DANE_SEDE"
  ) |>
  select(
    # Identificadores
    DANE_SEDE, SEDE, LOCALIDAD,
    # ICFES
    ICFES, ICFES_PREDICHO, RESIDUO, RENDIMIENTO,
    P_Lectura, P_Matemati, P_Sociales, P_Ciencias, P_Ingles,
    EVALUADOS,
    # Contexto territorial
    CUADRANTE_RIESGO, cat_violencia, cat_entorno,
    INDICE_VIOLENCIA, INDICE_EE,
    TASA_HOMICIDIO, TASA_LESIONES, TASA_HURTO,
    TASA_DELITOS_SEX, TASA_VIF, TASA_C4,
    homicidios, lesiones_personales, hurto_personas,
    delitos_sexuales, violencia_intrafamiliar,
    poblacion_total,
    TASA_DESERCION_LOC, TASA_REPROBACION_LOC,
    # Características de sede
    JORNADA_U, JORNADA_M, JORNADA_T, JORNADA_N, JORNADA_FDS,
    SEDE_PAE, HORAS_BASICA_SEC, HORAS_MEDIA,
    INDICE_TIC, INDICE_SERVICIOS, MAT_TOTAL,
    # Personal
    DIRECTIVOS, DOCENTES_AULA, ORIENTADORES, APOYO_AULAS, LID_APOYO,
    RATIO_DOC_AULA, RATIO_DIRECTIVOS, RATIO_ORIENTADORES,
    RATIO_APOYO, RATIO_LID_APOYO,
    # Tasas académicas sede
    TASA_DESERCION, TASA_REPROBACION, TASA_APROBACION,
    # Poblaciones diferenciales
    n_discapacidad, n_desplazados, n_etnicos,
    PROP_DISCAPACIDAD, PROP_DESPLAZADOS, PROP_ETNICOS
  ) |>
  mutate(across(where(is.numeric), ~ round(., 4)))

write.xlsx(df_powerbi,
           paste0(ruta_base, "BASE_POWERBI.xlsx"),
           overwrite = TRUE)

cat(">>> Guardado: BASE_POWERBI.xlsx\n")
cat("    Sedes:", nrow(df_powerbi), "| Columnas:", ncol(df_powerbi), "\n")

# ── 8.4 ARCHIVO DE DEPENDENCIAS ───────────────────────────────────────────────
writeLines(
  capture.output(sessionInfo()),
  paste0(ruta_base, "requirements.txt")
)
cat(">>> Guardado: requirements.txt (versiones de paquetes)\n")

cat("\n")
cat("=============================================================\n")
cat("  ANÁLISIS COMPLETADO\n")
cat("=============================================================\n")
cat("  Archivos generados en:", ruta_base, "\n")
cat("    resultados_estadisticos.xlsx  — regresiones y moderaciones\n")
cat("    BASE_POWERBI.xlsx             — base para dashboard\n")
cat("    requirements.txt              — dependencias del análisis\n")
cat("=============================================================\n")

