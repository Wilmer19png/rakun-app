---
name: RAKÜN Studio
description: Identidad heredada de RAKÜN Visual Design, punto de partida para la app móvil. La adaptación móvil se define y aprueba en la Fase 3 (design/DESIGN_MOVIL.md).
source: "rakun-web/DESIGN.md y rakun-web/.impeccable/design.json, commit cd85fe1 (incluye revisiones 2026-10-05)"
status: base heredada, sin adaptación móvil aprobada
colors:
  pink: "#FF2C68"
  ink-0: "#010221"
  navy: "#1B1A35"
  navy-deep: "#14132B"
  cream: "#F3F0EA"
  yellow: "#FFF02B"
  blue: "#2BCDFF"
  mist: "#C3C0DD"
  ink-soft: "#3C3A5C"
  white: "#FFFFFF"
  line-dark: "rgba(255, 255, 255, .17)"
  line-light: "rgba(27, 26, 53, .22)"
  line-pink: "rgba(27, 26, 53, .3)"
  # Propuestos para la app en la Fase 3 (pendientes de DISEÑO APROBADO; ver design/DESIGN_MOVIL.md)
  surface-1: "#0A0A2B"     # campos y filas tocadas sobre la noche
  dim: "#9A97BD"           # texto terciario: 7,3:1 sobre #010221
  ok: "#4FB58C"            # ganado/confirmado: el #3C8C6E de la web no pasa AA sobre navy (4,15:1)
  propuesta: "#8B6CF0"     # estado "Propuesta" de solicitudes (ya existe en la web)
  # Tema claro (crema), propuesto en la Fase 3
  light-surface-2: "#E8E4DB"
  light-surface-3: "#DCD7CC"
  light-dim: "#5C5980"     # terciario sobre crema: 5,8:1
  light-ok: "#17664A"      # verde sobre crema: 6,2:1
typography:
  display: "Knuckle Down (fonts/KnuckleDown.otf), un solo peso, MAYÚSCULAS, interlineado < 1"
  body: "Jost (lectura); peso y tracking a validar en móvil en la Fase 3"
  mono: "JetBrains Mono (índices, metadatos, fechas, cifras)"
rounded:
  none: "0px"
  round: "50% (solo iris del ojo y botón redondo)"
---

# Design System: RAKÜN Studio (base heredada)

> **Estado:** este archivo recoge la identidad de la web tal como está hoy. **No es el diseño aprobado de la app.**
> La adaptación real a móvil (escala tipográfica, grilla, navegación, componentes táctiles, movimiento) se define en la
> Fase 3 en `design/DESIGN_MOVIL.md` y solo vale cuando Wilmer escriba `DISEÑO APROBADO`. Entonces este archivo se actualiza.
> Fuente completa: `rakun-web/DESIGN.md` y la copia de `.impeccable/design.json` en este repositorio.

## North Star heredado: "El ojo que te mira"

RAKÜN vende atención; su marca es un ojo vivo. La web es un pliego editorial-brutalista: campos oscuros y crema,
líneas de 1px, índices mono, tipografía display enorme y color plano saturado.

## Reglas de identidad que la app conserva

- **El rosa manda.** `#FF2C68` aparece en toda pantalla. Ningún tema lo reemplaza.
- **Tinta navy.** Texto navy sobre rosa, amarillo o azul. Blanco solo sobre oscuro.
- **Nada de rosa pequeño sobre crema.** Rosa como texto en crema solo en tamaño display.
- **Superficie oscura** `#010221` (el fondo del isotipo); `#1B1A35` es la tinta navy.
- **Grita y susurra.** Knuckle Down en mayúsculas para títulos, un solo peso, sin negrita ni cursiva sintéticas. Lectura en Jost. Metadatos en JetBrains Mono.
- **Radio 0** en contenedores y botones. **Sin sombras difusas ni degradados**: la profundidad es una placa plana desplazada. Líneas de 1px.
- **Índices mono `00`–`12`** por sección. **Colores por mundo:** Marca amarillo, Producción azul, Web rosa.
- **Firmas:** el ojo vivo (física de resortes de `eye.js`, nunca animación por fotogramas fijos), el isotipo (`assets/rakun-isotipo.svg`), el badge, la onda (`assets/pattern-wave.svg`), los estallidos.

## Lo que la app NO hereda tal cual (a resolver en la Fase 3)

- Cursor personalizado, Lenis y animaciones de scroll: no existen en móvil.
- El riel de 64px: pasa a una franja compacta con el índice mono.
- La intro de la web: en la app la entrada dura menos de 1,5 s y respeta "reducir movimiento".
- Navegación de 13 secciones: barra inferior de máximo 5 destinos según permisos.
- Arrastrar para reasignar: pasa a una hoja "Reasignar".
- Jost 300 en pantalla pequeña: validar peso, tracking y contraste AA.
- Principio del encargo: la marca grita en los bordes (splash, encabezados, vacíos) y se calla en listas y formularios.
