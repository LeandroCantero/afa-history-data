# Guía — Primera División Argentina histórica con RSSSF + OpenFootball

## Objetivo

Construir localmente la historia completa de la **Primera División Argentina**, desde **2025 hacia atrás hasta 1891**, utilizando:

- **RSSSF como única fuente factual inmutable**.
- **Football.TXT 2026 Level 2-compatible** como formato canónico.
- **`Rsssf::Fmtfix` / `parse_schedules`** (gema oficial `rsssf` de Gerald Bauer) para normalización y división.
- **`fbtok`** para validación sintáctica estricta.
- **`fbtxt2sqlite` + `sportdb-models_v2`** para compilar la base de datos SQLite.

---

## Estructura del Proyecto y Layout Oficial

El ciclo de vida del dato sigue la arquitectura **`sources → data → build`**:

```text
afa-history-data /
├── config/
│   └── club_aliases.yml          # Tabla declarativa de aliases y normalización de clubes
├── sources/
│   └── rsssf/
│       └── 2025/
│           ├── arg2025.txt       # Captura inmutable original de RSSSF
│           └── manifest.yml      # Manifiesto de procedencia (URL, fecha de captura)
├── data/
│   └── primera/
│       └── 2025/
│           ├── 1-apertura.txt    # Torneo Apertura procesado con metadatos #
│           └── 2-clausura.txt    # Torneo Clausura procesado con metadatos #
├── compat/
│   └── fbtxt2sqlite_compat.rb   # Adaptador acotado de compatibilidad SQLite
├── scripts/
│   ├── prepare_2025.rb           # Extractor oficial (Rsssf::Fmtfix + parse_schedules)
│   └── build.rb                  # Pipeline reproducible (prepare -> fbtok -> SQLite)
├── docs/
│   ├── COMPATIBILITY_ADAPTER.md  # Contrato técnico del adaptador
│   ├── REPOSITORIOS.md           # Repositorios oficiales de referencia
│   └── AGENT_SEASON_AUDIT.md     # Protocolo de revisión final para agentes
├── README.md                     # Créditos y guía rápida de uso
└── build/                        # (Ignorado en Git) Base SQLite argentina.db
```

---

## Pipeline Reproducible (4 Fases Oficiales)

Al ejecutar `ruby scripts/build.rb`, se ejecutan las 4 fases oficiales de Gerald Bauer:

1. **Fase 1 (Fuentes)**: `sources/rsssf/2025/arg2025.txt` almacena la captura inalterada de RSSSF.
2. **Fase 2 (Normalización `Rsssf::Fmtfix` + Aliases)**:
   - `Rsssf::Fmtfix.fmtfix` aplica los autofixes globales de Gerald Bauer a la sintaxis 2026 (`▪ Round 1 ▪`, `_ Thu Jan 23 _`, bloques `>>> (begin)`).
   - Se aplica `config/club_aliases.yml` para normalizar los nombres locales de los clubes argentinos y etiquetar los estadios con `@` para que `fbtok` los reconozca.
3. **Fase 3 (División `parse_schedules`)**: Divide la salida en **`1-apertura.txt`** y **`2-clausura.txt`** e inserta los metadatos de resumen autogenerados (`# Date`, `# Teams`, `# Matches`, `# Stages`).
4. **Fase 4 (Compilación DB)**: `fbtok` valida los archivos y `fbtxt2sqlite` compila la base de datos `build/argentina.db`.

---

## Formato Canónico del Archivo Procesado (`1-apertura.txt`)

```text
= Argentina | Primera División 2025

# Date       Thu Jan 23 - Sun Jun 22 2025
# Teams      30
# Matches    240
# Stages     Torneo Apertura (240)

== Torneo Apertura

▪ Primera fase de zonas - Phase of groups ▪
▪ Round 1 ▪
Thu Jan 23
  CA Lanús  0-2  Deportivo Riestra AFBC  @ Ciudad de Lanús - Néstor Díaz Pérez, Remedios de Escalada
  CA Newell's Old Boys  0-1  CS Independiente Rivadavia  @ Marcelo A. Bielsa, Rosario
```

---

## Reglas de Automatización
- **100% Herramientas Oficiales**: Se utiliza el código de Gerald Bauer (`rsssf`, `fbtok`, `fbtxt2sqlite`). No se crean parsers propios.
- **Preservación Factual**: Se respetan los hechos informados por RSSSF. Nunca se inventan marcadores ni datos ausentes.
- **Revisión por Agente**: Al finalizar cada torneo o temporada, un agente puede realizar una revisión final (review) independiente comparando la fuente cruda de RSSSF contra los archivos formateados según `docs/AGENT_SEASON_AUDIT.md`.
