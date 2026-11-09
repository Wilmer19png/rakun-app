# Revisión del diseño · Fase 3

> 2026-11-09 · Impeccable 4.8.1. Prototipo en `design/`. Dos revisiones independientes (en paralelo y sin ver la una a la otra)
> más una ronda de correcciones y una ronda de confirmación. Nada de esto es la aprobación: esa es tuya (`DISEÑO APROBADO`).

## 1. Detector automático (`npx impeccable detect`)

| Pasada | Resultado |
|---|---|
| Primera, sobre archivos | 52 avisos: 21 de **rayas decorativas** (los días vacíos del calendario), 31 de **colores fuera de la paleta** (los 3 tonos nuevos), 10 de "relleno apretado", 8 de **texto funcional a 10 px** |
| Correcciones | Días vacíos lisos; tonos nuevos registrados como propuesta en `DESIGN.md`; mínimo de 11 px; ajuste de líneas equilibrado |
| Final, con cada pantalla dibujada (21 pantallas a 360×800 y 4 a 390×844) | **0 hallazgos** |
| Final, sobre archivos | 10 avisos de "relleno apretado" en controles segmentados, botones de contacto y pestañas: los botones ocupan todo el borde **a propósito** (patrón de Material). Con la pantalla dibujada, la regla no salta |

## 2. Medición en el navegador (Playwright, Chrome, 360×800)

- **Contraste:** ningún texto por debajo de AA en Hoy, Solicitud y Proyecto. El botón **+** da 4,69:1, medido a mano.
- **Desbordamiento horizontal:** ninguno.
- **Toques de menos de 48 dp:** 6 casos ("Ver todas", "Agenda", "Mensajes", "Marcar visto", enlaces de perfiles). **Corregidos** a 48 dp.
- **Consola:** solo falta el ícono de pestaña (`favicon.ico`), que no aplica a la app.

## 3. Crítica de diseño (director de diseño, sin ver el detector)

**Especificidad:** el diseño es propio, no genérico. El esqueleto Material 3 de las listas es lo correcto para una herramienta de trabajo.

**Heurísticas de Nielsen (0–4):**

| Heurística | Puntaje | Heurística | Puntaje |
|---|---|---|---|
| Visibilidad del estado | 3 | Reconocer antes que recordar | 3 |
| Lenguaje del estudio | 3 | Flexibilidad | 3 |
| Control y libertad | 3 | Estética y mínimo | 3 |
| Consistencia | 2 → corregido | Recuperarse de errores | 2 → corregido |
| Prevención de errores | 2 → corregido | Ayuda | n/a (herramienta interna) |

**Fortalezas:**
- Los botones nombran la consecuencia y a la persona: "Devolver a Alexander", "Se le suman $18.000", "Guardar y crear 2 proyectos".
- La barra por rol es una regla, no una lista fija.
- Las cifras van en mono, la acción principal queda al alcance del pulgar y el registro de pago avisa qué va a pasar antes de guardar.

**Problemas encontrados y qué se hizo:**

| # | Problema | Corrección |
|---|---|---|
| 1 | **El color decía dos cosas.** El amarillo era "Redes" y también "Contactado", "Lista", "En revisión" y "Sin conexión"; el azul era "Producción" y también "En curso" | Amarillo, azul y rosa quedan **solo para los mundos**. Los estados son etiquetas neutras de borde blanco. Solo lo que exige acción va relleno de rosa (Nueva, Revisar, Confirmar, Cambios). La franja sin conexión pasa a gris claro |
| 2 | **Hoy escondía las revisiones** debajo de las tareas propias | Nuevo orden: Vencido → **Te toca revisar** → Hoy |
| 3 | **Registrar pago sin red de seguridad:** la casilla "dar acceso al portal" venía marcada y el monto no tenía moneda | La casilla viene **desmarcada**; el campo lleva "$" y "Anticipo esperado: $2.645.000"; el aviso final muestra el saldo y permite Deshacer |
| 4 | **La marca gritaba en el trabajo:** títulos de Más en Knuckle Down, días de la Parrilla partidos, títulos de ficha que se cortaban | Más usa Jost y agrupa lo que llega después en una sola línea "Próximamente". Los días de la Parrilla van en mono. Los títulos de ficha son más pequeños y tienen tope de 2 líneas |
| 5 | Inconsistencias de estado: el vacío seguía diciendo "6 pendientes"; "sin permiso" mostraba las pestañas de la sección; las subpantallas no iluminaban "Más" | Corregidas |
| 6 | El mensaje de error era técnico ("Supabase tardó…") | Ahora dice "No hubo respuesta del servidor… lo último guardado es de las 9:12 a. m." |
| 7 | "Aprobar" no decía que libera el pago | El aviso dice "se libera el pago de Alexander" |

**Se dejó a propósito:** la píldora "llegó algo nuevo" flota encima de la lista. Así no mueve lo que estás leyendo, que era la regla del encargo.

## 4. Cambios pedidos por Wilmer (2026-11-09)

- **Tema claro y oscuro a elección** (antes: oscuro siempre). Tema claro revisado con el detector en 10 pantallas: **0 problemas de contraste**. Único aviso: "paleta crema", genérico; no aplica porque es el crema oficial de la marca y lo pidió Wilmer.
- **Solicitudes: dirección A.** Wilmer la prefiere "por organización, no tanta información en una sola parte". La crítica recomendaba B; manda la decisión del dueño.

## 5. Solicitudes: A o B (lo que dijo la crítica)

La crítica **recomienda B (bandeja)**. Sus razones:
- En la calle la pregunta es "¿a quién no he llamado?". B lo responde sin tocar nada: "Sin atender" arriba y "En curso" debajo.
- A esconde estados detrás de pestañas y, en el uso más común, muestra 2 filas y mucho vacío.

Si eliges B, le llevo dos cosas de A: el contador por etapa y el filtro por mundo, dentro del ícono de filtros.
**La decisión es tuya.**
