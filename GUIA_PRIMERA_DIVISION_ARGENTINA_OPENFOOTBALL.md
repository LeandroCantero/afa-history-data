# Guía — Primera División Argentina histórica con RSSSF + OpenFootball

## Objetivo

Construir localmente la historia completa de la **Primera División Argentina**, desde **2025 hacia atrás hasta 1891**, usando:

- **RSSSF como única fuente factual**.
- **Football.TXT 2026, Level 2-compatible** como formato canónico.
- **sport.db.v2 / fbtok / fbtree** para parsing y validación.
- **fbtxt2sqlite + sportdb/models_v2** para generar SQLite.
- Código Ruby oficial **sin modificarlo**.

No crear parser, schema ni modelo alternativo.

---

## Estructura del proyecto

El ciclo de vida autorizado es **`sources → staging → data → build`**. Cada directorio tiene una única responsabilidad:

| Ruta | Responsabilidad |
| --- | --- |
| `sources/rsssf/` | Capturas inmutables de RSSSF y su manifiesto de procedencia. Nunca se corrigen ni normalizan aquí. |
| `staging/` | Salidas descartables de las herramientas oficiales durante preparación, inspección y conversión. |
| `data/primera/<season>/` | Football.TXT canónico: un archivo por cada torneo confirmado por RSSSF para esa temporada. |
| `config/club_aliases.yml` | Única tabla declarativa de aliases y normalización de clubes. |
| `scripts/` | Orquestación reproducible exclusivamente; nunca contiene un parser, schema o modelo alternativo. |
| `compat/` | Adaptación externa y acotada entre el parser moderno y `fbtxt2sqlite`; su contrato está en [`docs/COMPATIBILITY_ADAPTER.md`](docs/COMPATIBILITY_ADAPTER.md). |
| `tests/` | Fixtures y pruebas de compatibilidad, validación y rechazo fail-closed. |
| `build/` | SQLite, logs y demás resultados regenerables. Nunca es fuente canónica. |
| `vendor/` | Repositorios externos y herramientas de terceros clonados de referencia (RSSSF, OpenFootball). |
| `docs/` | Documentación técnica complementaria. |

Reglas de layout y versionado Git:

- **Versionado en Git**: Se incluyen en Git el dataset (`data/`), las fuentes (`sources/`), configuraciones (`config/`), scripts (`scripts/`), adaptadores/tests (`compat/`, `tests/`) y la documentación (`docs/`).
- **Ignorados en Git (`.gitignore`)**: Se excluyen los artefactos regenerables (`build/`), salidas temporales (`staging/`, `scratch/`) y repositorios de terceros (`vendor/`).
- **Nunca editar la base SQLite**: cualquier corrección vuelve a `sources`, `config` o `data` según corresponda y regenera `build` ejecutando `ruby scripts/build.rb`.
- **No dejar artefactos sueltos en la raíz**: Esta guía principal permanece en la raíz como punto de entrada.

---

## 1. Alcance

El índice maestro es:

https://www.rsssf.org/tablesa/argchamp.html

Ese documento decide qué torneos pertenecen a la historia de la máxima categoría.

Se incluye todo lo que RSSSF catalogue como **Argentine Amateur First Division** o **Argentine Professional First Division**, aunque el formato o nombre haya cambiado.

Ejemplos históricos que deben contemplarse cuando aparezcan en RSSSF:

```text
campeonatos anuales
asociaciones/federaciones simultáneas
Metropolitano
Nacional
Apertura / Clausura
Inicial / Final
zonas
fases finales
desempates
otros formatos de Primera División
```

Se comienza por **2025** y se avanza hacia atrás.

RSSSF marca **1892 como año sin campeonato**: no se inventan datos.

---

## 2. Fuente de datos

### Única fuente factual: RSSSF

Prioridad:

1. https://www.rsssf.org/tablesa/argchamp.html
2. https://github.com/rsssf/tables
3. página RSSSF original enlazada por el índice
4. https://github.com/rsssf/scripts para preparación/conversión

No completar con:

```text
Wikipedia
AFA
Transfermarkt
diarios
otras bases
```

### Datos faltantes

Se guarda solamente lo que RSSSF informe y Football.TXT pueda representar.

Si RSSSF no tiene:

```text
goleadores
árbitro
estadio
hora
alineaciones
tarjetas
```

se omite.

La ausencia de datos no es un error ni una tarea pendiente.

---

## 3. Fuente canónica local

Los datos principales son los archivos **Football.TXT**.

```text
RSSSF
  ↓
preparación / fmtfix
  ↓
normalización de nombres
  ↓
Football.TXT moderno
  ↓
fbtok + fbtree
  ↓
fbtxt2sqlite
  ↓
argentina.db
```

SQLite, JSON y CSV son artefactos regenerables.

Nunca corregir partidos directamente en la DB.

---

## 4. Formato objetivo: Football.TXT 2026 Level 2-compatible

Autoridad principal:

https://openfootball.github.io/spec/

Repo de spec, samples y tests:

https://github.com/openfootball/spec

Portada con cambios actuales:

https://openfootball.github.io/

El target del proyecto es:

```text
Football.TXT 2026
Level 2-compatible
```

Esto significa:

- usar siempre la sintaxis vigente de 2026;
- Level 2 es el máximo nivel de detalle admitido por el proyecto;
- Level 1 funciona como subconjunto cuando RSSSF sólo tenga datos básicos;
- nunca rellenar campos para “alcanzar” Level 2;
- si RSSSF tiene datos Level 2 compatibles, se incorporan;
- si no los tiene, se omiten.

Ejemplo conceptual:

```text
RSSSF sólo tiene fecha + equipos + resultado
→ Football.TXT mínimo válido

RSSSF además tiene HT
→ agregar HT

RSSSF además tiene estadio
→ agregar @ ground

RSSSF además tiene goleadores
→ agregar goal scorer line

RSSSF además tiene árbitro, asistencia, alineaciones, etc.
→ usar la sintaxis Level 2 correspondiente
```

La documentación 2026 establece, entre otras cosas:

```text
round lines → deben comenzar con ▪ o ::
goal scorer lines → deben seguir la sintaxis moderna de la spec
```

Para mantener consistencia interna, el proyecto usará preferentemente:

```text
▪
```

para encabezados de round.

No copiar sintaxis vieja si contradice la spec actual.

### Regla de prioridad

Ante contradicciones:

```text
1. openfootball.github.io/
2. openfootball.github.io/spec/
3. openfootball/spec
4. sportdb/sport.db.v2
5. sportdb/footty
6. sportdb/models_v2
7. rsssf/scripts
8. ejemplos/datasets OpenFootball
9. documentación/schema históricos
```

---

## 5. Parser y herramientas modernas

### Parser

https://github.com/sportdb/sport.db.v2

La arquitectura v2 actual considera canónico:

```text
Football.TXT + lexer + parser
```

y ya no exige un único schema SQL compartido.

### Validación

```bash
gem install fbtok

fbtok archivo.txt
fbtree archivo.txt
```

Fuente:

https://github.com/sportdb/sport.db.v2/tree/master/fbtok

### CLI y SQLite

https://github.com/sportdb/footty

Herramientas principales:

```text
fbtxt
fbtxt2json
fbtxt2csv
fbtxt2sqlite
```

`fbtxt2sqlite` actual usa `sportdb/models_v2` y `fbtok`.

### Versiones verificadas y compatibilidad

El pipeline fue probado con:

```text
Ruby 3.4.10 + DevKit
fbtok / fbtxt-parser / fbtxt-document 0.9.1
sportdb-quick 0.8.0
sportdb-models_v2 0.0.1
fbtxt2sqlite 0.0.1
```

`fbtxt2sqlite` y `sportdb-models_v2` todavía esperan interfaces legacy que ya no
expone el stack moderno. El proyecto las adapta externamente desde `compat/`, sin
modificar gems, Football.TXT ni schema. Los casos sin equivalencia demostrada fallan
explícitamente.

Código:

https://github.com/sportdb/footty/blob/master/fbtxt2sqlite/bin/fbtxt2sqlite

Modelo SQLite actual:

https://github.com/sportdb/sport.db/tree/master/sportdb-models_v2

Construir mediante el script de orquestación del proyecto o el adapter verificado:

```bash
# Pipeline automatizado (preparación, validación fbtok y compilación SQLite)
ruby scripts/build.rb

# O comando directo del adapter:
ruby compat/fbtxt2sqlite_compat.rb build/argentina.db data/primera/2025/2025.txt
```

---

## 6. RSSSF tooling

Herramientas:

https://github.com/rsssf/scripts

Repositorio de tablas convertidas:

https://github.com/rsssf/tables

### `prepare`

Convierte RSSSF HTML → TXT.

### `fmtfix`

Aplica autofixes orientados al parsing Football.TXT.

```bash
ruby fmtfix/fmtfix.rb archivo.txt
```

### `mirror`

Permite espejar RSSSF completo, pero no es necesario para comenzar.

Usar primero `rsssf/tables`.

---

## 7. Primera División desde cero y normalización de equipos

La historia de la Primera División se construye **desde cero a partir de RSSSF**.

No se parte de:

- temporadas argentinas existentes en OpenFootball;
- catálogos argentinos prearmados;
- listas históricas de participantes;
- partidos ya cargados;
- tablas previas.

RSSSF determina qué equipos participaron y cómo se llamaban en cada temporada.

### Problema de identidad

La DB v2 puede crear duplicados si recibe variantes textuales distintas para un mismo club.

Ejemplo:

```text
Club Atlético River Plate
CA River Plate
River Plate
```

deben resolverse a una única identidad, por ejemplo:

```text
River Plate
```

### Regla de normalización

1. extraer los nombres desde RSSSF;
2. construir un mapa local de aliases propio del proyecto;
3. elegir un nombre base único y estable por club;
4. reutilizarlo en todas las temporadas;
5. registrar cada variante RSSSF encontrada;
6. evitar duplicados por abreviación, ciudad o forma histórica del nombre;
7. resolver manualmente ambigüedades reales cuando dos clubes compartan nombres parecidos.

OpenFootball puede consultarse como **referencia auxiliar de naming/aliases**:

https://github.com/openfootball/clubs/blob/master/south-america/argentina/ar.clubs.txt

pero ese archivo **no es la base del dataset** y no decide participantes, temporadas ni hechos históricos.

La Primera División se reconstruye íntegramente desde RSSSF.

---

## 8. Formatos históricos

No asumir “un torneo por año”.

El índice RSSSF muestra períodos con múltiples campeonatos de Primera, por ejemplo:

```text
1912-1914     asociaciones simultáneas
1919-1926     Asociación + Amateurs
1931-1934     amateurismo + liga profesional
1967-1979     Metropolitano + Nacional
1980-1985     Campeonato + Nacional
1991/92...    Apertura + Clausura
2012/13       Inicial + Final + Campeonato
2025          Apertura + Anual LPF + Clausura
```

Cada caso debe modelarse usando la sintaxis actual de Football.TXT.

No crear tablas especiales para formatos argentinos.

---

## 9. Workflow por temporada

Para cada año/temporada:

### 1. Identificar torneos

Abrir:

https://www.rsssf.org/tablesa/argchamp.html

y determinar qué competiciones de Primera existen en ese período.

### 2. Obtener RSSSF

Preferencia:

```text
rsssf/tables
→ página original RSSSF
```

### 3. Analizar la estructura

Identificar lo que RSSSF realmente contiene:

```text
torneos
stages
groups
rounds
fechas
partidos
scores
desempates/finales
estados especiales
datos opcionales
```

### 4. Normalizar clubes

Construir/aplicar el mapa local de aliases derivado de los nombres encontrados en RSSSF.

OpenFootball puede ayudar a resolver naming, pero no aporta la lista histórica de participantes.

### 5. Escribir Football.TXT 2026 Level 2-compatible

RSSSF aporta los hechos.

Football.TXT define la representación.

### 6. Validar

```bash
fbtok data/primera/2025/2025.txt
fbtree data/primera/2025/2025.txt
```

No dar por terminado un archivo que el parser moderno no interprete correctamente.

### 7. Generar DB

```bash
# Ejecutar pipeline completo automatizado
ruby scripts/build.rb
```

Opcional:

```bash
fbtxt2json data/primera/2025/2025.txt -o build/2025.json
fbtxt2csv  data/primera/2025/2025.txt -o build/2025.csv
```

---

## 10. Referencias OpenFootball útiles

### Ejemplos argentinos existentes en OpenFootball

https://github.com/openfootball/south-america/tree/master/argentina

Ejemplo 2025:

https://github.com/openfootball/south-america/blob/master/argentina/2025_ar1.txt

Estos archivos sirven únicamente para observar **estilo y compatibilidad Football.TXT**.

No se usan como punto de partida del dataset, no se copian temporadas, no determinan participantes y no reemplazan RSSSF.

La Primera División se reconstruye desde cero.

### RSSSF → Football.TXT

https://github.com/openfootball/league-starter

Contiene ejemplos de:

```text
rounds
dates
abandoned
awarded
replay
promotion/relegation
```

Validar siempre contra la spec actual.

### Schema y docs históricos

https://openfootball.github.io/schema/

https://openfootball.github.io/docs/

Sirven para comprender conceptos, pero **no para construir manualmente la DB moderna**.

---

## 11. Reglas para el agente

- RSSSF es la única fuente factual.
- Incluir toda la Primera División desde 1891 según el índice de RSSSF.
- Trabajar desde 2025 hacia atrás.
- Construir la Primera División desde cero usando RSSSF.
- No inventar ni completar datos ausentes.
- Normalizar nombres mediante un mapa local de aliases antes de importar.
- Usar Football.TXT 2026 Level 2-compatible.
- Priorizar siempre la automatización oficial existente antes de usar IA o crear lógica propia.
- Usar agentes de IA sólo cuando las herramientas oficiales no alcancen para resolver un caso.
- No editar, modificar ni parchear ninguna línea de código de los scripts o herramientas oficiales.
- Validar toda salida con `fbtok` y `fbtree`.
- Generar SQLite con `fbtxt2sqlite` mediante `compat/fbtxt2sqlite_compat.rb`.
- No modificar OpenFootball, sport.db ni rsssf/scripts.
- No diseñar schema, parser ni ORM propios.
- Si algo no está claro, revisar primero la documentación y las herramientas actuales.

Objetivo final:

```text
RSSSF histórico
→ Primera División reconstruida desde cero
→ Football.TXT 2026 Level 2-compatible
→ tooling oficial
→ SQLite local reproducible
```

---

## Fuentes

*(Ver documentación completa y detallada de repositorios en [`docs/REPOSITORIOS.md`](docs/REPOSITORIOS.md))*

### RSSSF

https://www.rsssf.org/tablesa/argchamp.html  
https://github.com/rsssf/tables  
https://github.com/rsssf/scripts  
https://www.rsssf.org/

### OpenFootball

https://openfootball.github.io/  
https://openfootball.github.io/spec/  
https://openfootball.github.io/schema/  
https://openfootball.github.io/docs/  
https://github.com/openfootball/spec  
https://github.com/openfootball/south-america/tree/master/argentina  
https://github.com/openfootball/clubs/blob/master/south-america/argentina/ar.clubs.txt  
https://github.com/openfootball/league-starter

### sport.db

https://github.com/sportdb/sport.db.v2  
https://github.com/sportdb/sport.db.v2/tree/master/fbtok  
https://github.com/sportdb/footty  
https://github.com/sportdb/footty/tree/master/fbtxt2sqlite  
https://github.com/sportdb/sport.db/tree/master/sportdb-models_v2
