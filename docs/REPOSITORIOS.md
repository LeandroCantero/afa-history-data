# Repositorios y Herramientas Oficiales del Proyecto

Documentación completa de los repositorios y herramientas oficiales/relevantes de **OpenFootball**, **sport.db** y **RSSSF** para la reconstrucción de la Primera División Argentina.

---

## 1. OpenFootball — formato, datos de ejemplo y documentación

* **`openfootball/spec`** — especificación actual de Football.TXT, samples y tests  
  [github.com/openfootball/spec](https://github.com/openfootball/spec)

* **`openfootball/quick-starter`** — ejemplos de uso y conversión/build  
  [github.com/openfootball/quick-starter](https://github.com/openfootball/quick-starter)

* **`openfootball/docs`** — documentación histórica/general  
  [github.com/openfootball/docs](https://github.com/openfootball/docs)

* **`openfootball/help`** — FAQ, troubleshooting y guías  
  [github.com/openfootball/help](https://github.com/openfootball/help)

* **`openfootball/clubs`** — catálogo de clubes y aliases; sólo referencia de naming para nosotros  
  [github.com/openfootball/clubs](https://github.com/openfootball/clubs)

* **`openfootball/leagues`** — catálogo de ligas/competiciones  
  [github.com/openfootball/leagues](https://github.com/openfootball/leagues)

* **`openfootball/south-america`** — datasets Football.TXT sudamericanos, incluidos ejemplos argentinos  
  [github.com/openfootball/south-america](https://github.com/openfootball/south-america)

* **`openfootball/world`** — datasets Football.TXT de otras regiones  
  [github.com/openfootball/world](https://github.com/openfootball/world)

* **`openfootball/football.json`** — JSON autogenerado desde Football.TXT; útil como ejemplo de outputs, no como fuente nuestra  
  [github.com/openfootball/football.json](https://github.com/openfootball/football.json)

---

## 2. sportdb — tooling Ruby

Organización principal:  
[github.com/sportdb](https://github.com/sportdb)

Repositorios clave:

* **`sportdb/sport.db.v2`** — tooling moderno, lexer/parser y arquitectura v2  
  [github.com/sportdb/sport.db.v2](https://github.com/sportdb/sport.db.v2)

* **`sportdb/footty`** — CLI y conversores: `fbtxt`, `fbtxt2json`, `fbtxt2csv`, `fbtxt2sqlite`  
  [github.com/sportdb/footty](https://github.com/sportdb/footty)

* **`sportdb/sport.db`** — repo grande/histórico; todavía contiene `sportdb-models_v2` que usa `fbtxt2sqlite`  
  [github.com/sportdb/sport.db](https://github.com/sportdb/sport.db)

* **`sportdb/sport.db.sources`** — helpers para preparar fuentes externas  
  [github.com/sportdb/sport.db.sources](https://github.com/sportdb/sport.db.sources)

* **`sportdb/sport.db.archive`** — versiones experimentales/antiguas; sólo referencia  
  [github.com/sportdb/sport.db.archive](https://github.com/sportdb/sport.db.archive)

La propia organización destaca `footty`, `sport.db`, `sport.db.v2`, `sport.db.web` y `docs`; `sport.db.v2` y `footty` están activos en 2026.

### Herramientas que usamos

```text
fbtok
fbtree
fbtxt2sqlite
```

Opcionales:

```text
fbtxt
fbtxt2json
fbtxt2csv
footty
```

Nuestro stack verificado:

```text
fbtok 0.9.1
fbtxt-parser 0.9.1
fbtxt-document 0.9.1
sportdb-quick 0.8.0
sportdb-models_v2 0.0.1
fbtxt2sqlite 0.0.1
```

---

## 3. RSSSF — fuente factual y tooling

Organización principal:  
[github.com/rsssf](https://github.com/rsssf)

Repositorios clave:

* **`rsssf/tables`** — mirror TXT de páginas RSSSF convertidas; nuestra primera opción  
  [github.com/rsssf/tables](https://github.com/rsssf/tables)

* **`rsssf/scripts`** — herramientas oficiales de preparación/conversión  
  [github.com/rsssf/scripts](https://github.com/rsssf/scripts)

* **`rsssf/clubs`** — páginas procesadas orientadas a clubes  
  [github.com/rsssf/clubs](https://github.com/rsssf/clubs)

* **`rsssf/world`** — páginas procesadas internacionales  
  [github.com/rsssf/world](https://github.com/rsssf/world)

* **`rsssf/worldcup`** — páginas procesadas de Mundiales  
  [github.com/rsssf/worldcup](https://github.com/rsssf/worldcup)

### Herramientas de `rsssf/scripts`

```text
prepare
fmtfix
mirror
report
export
```

Para nosotros, principalmente:

```text
rsssf/tables
→ prepare si hace falta bajar/convertir
→ fmtfix si hace falta preparar el TXT
```

`mirror` no hace falta para empezar porque clona prácticamente todo RSSSF y genera un `mirror.db`.

---

## 4. Prioridad para este proyecto

```text
1. rsssf/tables / RSSSF original
2. rsssf/scripts
3. openfootball/spec
4. sportdb/sport.db.v2
5. fbtok / fbtree
6. sportdb/footty / fbtxt2sqlite
7. sportdb-models_v2
8. openfootball/clubs sólo para naming/aliases
9. datasets OpenFootball sólo como ejemplos de formato
```
