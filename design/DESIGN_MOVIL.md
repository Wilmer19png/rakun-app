# DESIGN_MOVIL · RAKÜN Studio

> Fase 3 · 2026-11-09 · **propuesta para aprobar**. Vale solo cuando Wilmer escriba `DISEÑO APROBADO`;
> entonces pasa a `DESIGN.md` y Flutter lo copia tal cual (Fase 4).
> Fuente de verdad visual del prototipo: `design/proto/app.css`. Este documento explica el **porqué**.

## 1. Principio

**La marca grita en los bordes y se calla en el trabajo.** El ojo, el isotipo, la onda y Knuckle Down gigante viven en la entrada,
en el saludo de Hoy, en los títulos de sección y en las pantallas vacías. Las listas, fichas y formularios son sobrios, densos y rápidos:
ahí la marca está en los detalles (el rosa de la acción, el índice mono, la línea de 1 px, el color del mundo).

Estructura **Android Material 3**: barra de navegación inferior, barra superior, hojas inferiores para editar, *snackbars* para confirmar,
gesto Atrás del sistema. La marca entra por el tema: **radio 0**, **sin sombras difusas**, **líneas de 1 px**, tipografía propia.

## 2. Color (fondo oscuro siempre)

| Token | Valor | Uso | Contraste sobre `ink-0` |
|---|---|---|---|
| `ink-0` | `#010221` | Fondo de toda la app | — |
| `s1` | `#0A0A2B` | Campos, fila tocada | — |
| `s2` | `#14132B` | Hojas inferiores, barra inferior, barra de acción | — |
| `s3` / navy | `#1B1A35` | Tinta sobre color; plano más alto | — |
| `pink` | `#FF2C68` | **Acción principal**, vencido, aviso, selección, índice | 5,6:1 |
| `yellow` | `#FFF02B` | Mundo **Marca/Redes**, "En revisión", sin conexión, placa del FAB | 17,2:1 |
| `blue` | `#2BCDFF` | Mundo **Producción**, "En curso" | 10,9:1 |
| `white` | `#FFFFFF` | Texto principal | 20,4:1 |
| `mist` | `#C3C0DD` | Texto secundario | 11,5:1 |
| `dim` *(nuevo)* | `#9A97BD` | Texto terciario, etiquetas de campo | 7,3:1 |
| `ok` *(nuevo)* | `#4FB58C` | Ganado, confirmado, "con acceso" | 8,1:1 (6,7:1 sobre navy) |
| `line` | blanco 14 % | Separadores | — |
| `line-2` | blanco 28 % | Bordes de campos y chips | — |

Reglas que se conservan de la web:
- **Tinta navy sobre rosa, amarillo o azul** (rosa con navy: 4,67:1, pasa AA).
- El rosa aparece en **toda** pantalla (acción, índice, barra activa).
- Colores por **mundo**: Marca amarillo · Producción azul · Web rosa. Se muestran como un **cuadro plano de 8 px + nombre en mono**, nunca como borde izquierdo grueso.

Cambio frente a la web: el verde `#3C8C6E` de "ganado" no pasa AA sobre navy (4,15:1); en la app se usa `#4FB58C`.

## 3. Tipografía (en *sp*, crece con el tamaño de letra del sistema)

| Rol | Fuente | Tamaño / interlínea | Uso |
|---|---|---|---|
| Display | Knuckle Down | 48 / 0,86 | Saludo de Hoy, entrada |
| Headline | Knuckle Down | 34–40 / 0,9 | Título de sección (se encoge a 22 al desplazar), nombre en ficha |
| Title | Knuckle Down | 20–24 / 0,95 | Título de hoja inferior, bloques, días de la parrilla |
| Body | Jost **400** | 16 / 1,45 | Lectura, filas |
| Body small | Jost 400 | 14 / 1,35 | Segunda línea de fila |
| Label | Jost 500, MAYÚSCULAS, +0,08em | 14 | Botones |
| Mono | JetBrains Mono 500 | 11–12, +0,04–0,08em | Índices, fechas, cifras (tabulares), etiquetas |

- **Jost 300 → 400.** El 300 de la web se ve débil a 14–16 px sobre fondo oscuro; 400 mantiene el carácter geométrico y lee bien.
- **Knuckle Down** tiene un solo peso: nunca negrita ni cursiva sintética. Solo en MAYÚSCULAS y nunca en textos de lectura.
- **Mínimo 11 sp** para texto funcional (detector de Impeccable en verde).
- Cifras de dinero siempre en mono tabular, para que las columnas no bailen.

## 4. Grilla, espacio y toque

- Margen lateral **16 dp**. Ritmo de 4 dp (4 · 8 · 12 · 16 · 24 · 32 · 48).
- Más espacio arriba de un encabezado de grupo (24) que debajo (8).
- **Toque mínimo 48×48 dp**; los chips de 36 dp tienen área táctil ampliada a 48.
- Filas de lista de **64 dp** mínimo, separadas por **líneas de 1 px**, no por tarjetas.
- Acción principal **abajo, al alcance del pulgar**: barra de acción fija (Entregar, Aprobar, Registrar pago) o FAB.

## 5. Componentes

| Componente | Decisión | Por qué |
|---|---|---|
| **Barra superior grande** | Índice mono rosa + título Knuckle Down; se encoge al desplazar | Es el riel de 64 px de la web convertido en franja |
| **Barra superior de detalle** | Atrás + nombre en Jost 500 + 1–2 acciones | En el trabajo la marca se calla |
| **Barra inferior** | Máx. 5 destinos **según permisos**; activo = ícono rosa relleno + barra rosa de 3 px arriba; aviso = cuadro rosa con número | Material 3; la regla por permisos está en `MAPA_NAVEGACION.md` |
| **Fila de lista** | Título Jost 500 + línea secundaria con el mundo; a la derecha la fecha en mono y **una acción de un toque** (entregar, llamar, Maps) | El dato y la acción, sin abrir nada |
| **Acciones de contacto** | Tres bloques de 72 dp: Llamar (rosa) · WhatsApp · Correo | "A un toque" del encargo |
| **Hoja inferior** | Fondo `s2`, filo rosa de 3 px arriba, título Knuckle Down, botón principal fijo abajo | Editar sin perder el contexto; se cierra con Atrás |
| **FAB** | Cuadrado rosa con **placa amarilla desplazada** 5 px | La única "placa plana desplazada" del sistema (la profundidad de la marca); uno por pantalla |
| **Chips** | Borde de 1 px; activo = relleno blanco con tinta noche | Filtros sin competir con la acción rosa |
| **Pestañas** | Subrayado rosa de 3 px; contador en mono | |
| **Etiqueta de estado** | Bloque plano de color con tinta navy, mono MAYÚSCULAS | Se lee por color **y** por texto |
| **Semáforo de métricas** | Cuadro (bien), rombo (en medio), triángulo (alerta) | No depende solo del color |
| **Snackbar** | Blanco con tinta noche; "Deshacer" cuando aplica | Confirmación breve sin interrumpir |
| **Íconos** | Material Symbols **Sharp**, peso 300 | Esquinas rectas como la marca; un solo estilo |

## 6. Estados

| Estado | Diseño |
|---|---|
| Cargando | Esqueleto plano de líneas, sin brillo animado |
| Vacío | **Momento de marca**: el ojo vivo + frase en Knuckle Down con una palabra rosa + qué hacer |
| Error | Marco rosa de 1 px, qué pasó en palabras simples, *Reintentar* |
| Sin conexión | Franja amarilla fija: "ves lo guardado a las 9:12 a. m."; los botones de escribir se desactivan |
| Sin permiso | Candado rosa + "No está en tus permisos" + ir a Hoy |
| Llegó algo en vivo | Píldora rosa flotante ("1 solicitud nueva ↑"); **no mueve** la lista ni interrumpe una hoja abierta |

## 7. Movimiento

- **Un solo momento de autor: el ojo.** Se abre en la entrada (menos de 1,5 s) con la misma física de resortes de `eye.js`
  (el prototipo usa una copia sin cambios), parpadea y explora en Hoy y en los vacíos. Tocarlo lo hace parpadear.
- Todo lo demás es funcional: hojas que suben (0,35 s, curva exponencial de salida), título que se encoge, *snackbar*.
- **Reducir movimiento**: el ojo no parpadea ni explora y los resortes se endurecen; las transiciones se vuelven instantáneas.

## 8. Entrada

- **Splash**: el ojo grande se abre sobre la noche, "RAKÜN" con la Ü rosa, "STUDIO" en mono y la **onda** de la marca abajo. Menos de 1,5 s.
- **Login**: isotipo oficial + "ENTRA AL ESTUDIO." El enlace de recuperar lleva a `cuenta.html` en la web.
- **Cuenta de cliente**: "Esta app es del equipo" con el ojo y el botón para abrir su portal web.

## 9. Lo que la app NO hereda de la web y por qué

| De la web | En la app | Motivo |
|---|---|---|
| Cursor personalizado, Lenis, animaciones de scroll | Nada | No existen en táctil; gastan batería |
| Riel lateral de 64 px | Índice mono en la barra superior | No cabe a 360 px |
| Intro larga una vez por sesión | Splash de menos de 1,5 s | Se abre muchas veces al día |
| Tablas de 6–9 columnas | Filas + hoja de edición | No caben; la hoja da campos de 48 dp |
| Arrastrar para reasignar | Hoja "Reasignar" (P2) | Arrastrar es impreciso con el pulgar |
| Fondos crema | Noche siempre | Decisión de Wilmer (rodajes, noche, batería) |
| Modal centrado | Hoja inferior | Patrón de Android, alcance del pulgar |

## 10. Pendiente para Flutter (Fase 4)

- Empaquetar Knuckle Down (`.otf`), Jost y JetBrains Mono como archivos locales.
- Íconos: paquete de Material Symbols Sharp (a elegir y justificar con versión real de pub.dev).
- Tema Material 3 con estos tokens como roles de color (`primary` = rosa, `onPrimary` = navy, `surface` = noche…), `shape` en 0.
- Portar `eye.js` a Flutter con la misma física de resortes (k/c iguales) y respeto a "reducir movimiento".
