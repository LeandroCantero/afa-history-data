# AFA History v2 — Primera División Argentina (1891–2025)

Reconstrucción histórica completa de la **Primera División Argentina** desde 2025 hacia atrás hasta 1891, representada en el formato **Football.TXT 2026 Level 2** y compilada en una base de datos SQLite reproducible.

---

## ⭐️ Créditos Especiales

- **Gerald Bauer ([@geraldb](https://github.com/geraldb))**: Creador y mantenedor de **OpenFootball** y **sport.db**, por definir la especificación Football.TXT 2026, la suite de herramientas (`fbtok`, `fbtxt2sqlite`, `rsssf`) y liderar los datos abiertos de fútbol mundial.
- **[RSSSF](https://www.rsssf.org/)**: Única fuente factual inmutable del proyecto.

---

## 🚀 Inicio Rápido

### Requisitos
- **Ruby 3.4+** con DevKit.
- Gemas instaladas: `rsssf`, `fbtok`, `fbtxt-parser`, `fbtxt2sqlite`, `sqlite3`.

### Ejecutar el Pipeline Completo
Para ejecutar las 4 fases (descarga inmutable, normalización `Rsssf::Fmtfix`, división `parse_schedules` y compilación SQLite):

```bash
ruby scripts/build.rb
```

### Validar Sintaxis de un Torneo
```bash
fbtok data/primera/2025/1-apertura.txt
fbtok data/primera/2025/2-clausura.txt
```

---

## 📁 Estructura de Carpetas

```text
afa-history-data /
├── config/
│   └── club_aliases.yml          # Mapeo canónico de aliases de clubes
├── sources/
│   └── rsssf/2025/               # Capturas inmutables originales de RSSSF
├── data/
│   └── primera/2025/             # Archivos por torneo con nomenclatura oficial:
│       ├── 1-apertura.txt        # Torneo Apertura con metadatos #
│       └── 2-clausura.txt        # Torneo Clausura con metadatos #
├── scripts/
│   ├── prepare_2025.rb           # Extractor oficial (Rsssf::Fmtfix + parse_schedules)
│   └── build.rb                  # Pipeline reproducible (prepare -> fbtok -> SQLite)
├── compat/                       # Adaptador acotado de compatibilidad SQLite
└── build/                        # Base SQLite compilada (argentina.db) [Ignorada en Git]
```

---

## 📚 Documentación Técnica

- 📄 **[`GUIA_PRIMERA_DIVISION_ARGENTINA_OPENFOOTBALL.md`](GUIA_PRIMERA_DIVISION_ARGENTINA_OPENFOOTBALL.md)**: Guía técnica completa del proyecto.
