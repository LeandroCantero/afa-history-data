# Protocolo de Auditoría y Revisión Final por Agente

## Objetivo

Este documento define la regla estricta y el procedimiento que **debe seguir cualquier agente de IA** al realizar la revisión final (review) de un torneo o temporada procesada en el repositorio.

---

## 🛑 REGLA DE ORO: Modo Solo Lectura e Informe Obligatorio

> [!IMPORTANT]
> durante la revisión final de una temporada, **el agente NO debe editar código ni modificar automáticamente ningún archivo de datos (`data/` o `scripts/`)**.
> 
> Su única tarea es **comparar la fuente factual cruda contra el dataset procesado y reportar detalladamente los hallazgos al usuario** para que este decida qué acciones tomar.

---

## 🔍 Pasos del Proceso de Auditoría

El agente debe ejecutar los siguientes 3 chequeos sistemáticos:

### 1️⃣ Chequeo 1: Factualidad vs RSSSF Original
- Comparar la fuente inmutable original (`sources/rsssf/<año>/...`) contra los archivos de datos formateados (`data/primera/<año>/...`).
- Verificar que **no falte ningún partido** de la temporada.
- Confirmar que todos los resultados de tiempo completo (FT), entretiempo (HT) y penaltis coincidan **al 100% con los hechos registrados en RSSSF**.
- Verificar que el conteo total de equipos (`# Teams`) y partidos (`# Matches`) sea exacto.

### 2️⃣ Chequeo 2: Sintaxis y Estándar Football.TXT Level 2
- Confirmar que el archivo contenga la cabecera canónica `= Argentina | Primera División <Año>`.
- Confirmar la presencia del bloque de metadatos autogenerados `#` (`# Date`, `# Teams`, `# Matches`, `# Stages`).
- Verificar el uso correcto de encabezados de ronda (`▪ Round 1 ▪`), fechas y la notación Level 2 (`@ Venue`, marcadores de penales `, 4-2 pen.`).
- Ejecutar la comprobación con `fbtok data/primera/<año>/*.txt` asegurando 0 errores sintácticos.

### 3️⃣ Chequeo 3: Mapeo de Clubes y Normalización
- Revisar que todos los clubes participantes hayan sido normalizados mediante `config/club_aliases.yml`.
- Reportar si algún club o variante no fue reconocido y quedó en texto crudo.

---

## 📊 Formato del Reporte Final del Agente

Al finalizar la auditoría, el agente debe presentar un informe estructurado al usuario con el siguiente esquema:

```markdown
### 📋 Reporte de Auditoría: Temporada <Año> - <Torneo>

- **Estado**: ✅ APROBADO / ⚠️ REVISIÓN REQUERIDA
- **Validación Sintáctica (fbtok)**: 0 Errores
- **Compilación SQLite**: Exitosa (X partidos procesados)

#### 🔍 Detalle de Hallazgos:
1. **Factualidad vs RSSSF**: [Coincide 100% / Se detectaron diferencias en X partidos]
2. **Sintaxis Level 2**: [Conforme / Observaciones de formato]
3. **Mapeo de Clubes**: [Todos normalizados / Faltan aliases para: Team X]

#### 💡 Recomendación / Próximos Pasos:
[Sugerencia de corrección para el usuario si hubo observaciones]
```
