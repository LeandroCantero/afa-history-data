# AFA History v2 — Primera División Argentina (1891–2025)

Base de datos abierta y reconstrucción histórica completa de la **Primera División Argentina** desde 2025 hacia atrás hasta 1891, representada en el formato canónico **Football.TXT 2026 Level 2** y compilada en SQLite reproducible.

---

## ⭐️ Agradecimientos y Créditos Especiales

Este proyecto se construye sobre el extraordinario ecosistema de datos abiertos y herramientas de software libre desarrolladas por:

- **Gerald Bauer ([@geraldb](https://github.com/geraldb))**: Creador y mantenedor de **OpenFootball** y **sport.db**, por definir la especificación Football.TXT, las herramientas de tokenización/parsing (`fbtok`, `fbtree`, `footty`, `sportdb`) y liderar el movimiento de datos abiertos de fútbol a nivel mundial.
- **[OpenFootball](https://openfootball.github.io/)**: Por la especificación técnica Football.TXT 2026 y los estándares de datasets deportivos públicos.
- **[sport.db](https://github.com/sportdb)**: Por la suite de gemas y herramientas de parsing de torneos en Ruby.
- **[RSSSF (Rec.Sport.Soccer Statistics Foundation)](https://www.rsssf.org/)**: Única fuente factual de verdad del proyecto, por preservar la historia estadística del fútbol mundial y argentino.

---

## 🎯 Objetivo

Reconstruir localmente y de forma automatizada toda la historia de la máxima categoría del fútbol argentino (campeonatos anuales, Metropolitano, Nacional, Apertura, Clausura, Inicial, Final, ligas y asociaciones simultáneas):

1. **RSSSF como única fuente factual**: No se inventan datos ni se consulta Wikipedia/Transfermarkt.
2. **Football.TXT 2026 (Level 2-compatible)**: Formato canónico legible tanto por humanos como por parsers.
3. **Tooling oficial**: Validación con `fbtok` / `fbtree` y generación de la base SQLite `build/argentina.db` mediante `compat/fbtxt2sqlite_compat.rb`.

---

## 🚀 Inicio Rápido

### Requisitos
- **Ruby 3.4+** con DevKit.
- Gemas instaladas: `fbtok`, `fbtxt-parser`, `fbtxt-document`, `sportdb-quick`, `sportdb-models_v2`, `fbtxt2sqlite`, `sqlite3`.

### Ejecutar el Pipeline Completo
Para preparar las temporadas, validar sintaxis y generar la base de datos SQLite `build/argentina.db`:

```bash
ruby scripts/build.rb
```

### Validar Sintaxis de una Temporada
```bash
fbtok data/primera/2025/2025.txt
fbtree data/primera/2025/2025.txt
```

---

## 📁 Estructura del Proyecto

```text
.
├── data/                  # Datasets canónicos Football.TXT (un archivo por temporada)
│   └── primera/2025/      # Temporada 2025 (Torneo Apertura y Clausura)
├── sources/               # Capturas inmutables originales de RSSSF y manifiestos
│   └── rsssf/2025/        # Fuente inmutable y manifest.yml
├── config/                # Mapeos declarativos de nombres y aliases de clubes
│   └── club_aliases.yml
├── scripts/               # Scripts de preparación y orquestación (build.rb)
├── compat/                # Adaptador externo para fbtxt2sqlite y sportdb-models_v2
├── tests/                 # Suite de pruebas automatizadas fail-closed
├── build/                 # SQLite compilada (build/argentina.db) [Ignorada en Git]
├── vendor/                # Herramientas y repositorios externos clonados [Ignorado en Git]
└── docs/                  # Documentación técnica y mapa de repositorios
```

---

## 📚 Documentación Técnica

- 📄 **[`GUIA_PRIMERA_DIVISION_ARGENTINA_OPENFOOTBALL.md`](GUIA_PRIMERA_DIVISION_ARGENTINA_OPENFOOTBALL.md)**: Guía maestra con las reglas de layout, arquitectura del pipeline y alcance histórico.
- 📄 **[`docs/REPOSITORIOS.md`](docs/REPOSITORIOS.md)**: Índice completo de repositorios y herramientas oficiales de OpenFootball, sportdb y RSSSF.
- 📄 **[`docs/COMPATIBILITY_ADAPTER.md`](docs/COMPATIBILITY_ADAPTER.md)**: Especificación técnica del adaptador `compat/`.

---

## 📄 Licencia

El dataset y las herramientas siguen el espíritu de datos abiertos en el dominio público ([Public Domain / CC0 / MIT](LICENSE)) promovido por OpenFootball y RSSSF.
