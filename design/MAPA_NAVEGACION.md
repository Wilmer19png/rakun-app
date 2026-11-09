# Mapa de navegación y flujos · RAKÜN Studio

> Fase 3 · paso 1 (`/impeccable shape`) · 2026-11-08 · **borrador para confirmar antes de dibujar.**
> Base: `PRODUCT.md`, `docs/AUDITORIA_GESTOR.md` (alcance aprobado) y las respuestas de Wilmer:
> **inicio en una pantalla "Hoy"**, **barra inferior por rol tal como se propuso**. Actualizado 2026-11-09: **tema oscuro y claro a elección**
> (antes: oscuro siempre) y **Solicitudes en la dirección A** (por estado).

## 1. Qué es y para quién (modo *Operate*)

- Herramienta de trabajo: el éxito es **terminar la tarea rápido**, no admirar la pantalla.
- Usuario principal: Wilmer (admin), de pie en un rodaje, en la calle entre citas o en una revisión rápida. También para trabajo largo (cotizaciones, proyectos completos).
- **La marca grita en los bordes y se calla en el trabajo:** el ojo, el isotipo y la tipografía gigante van en la entrada, en los encabezados y en las pantallas vacías. Las listas y formularios son sobrios, densos y rápidos.

## 2. Dirección

- **Mundo visual:** el de RAKÜN (heredado, no se reinventa). Fondo noche `#010221` siempre. El rosa `#FF2C68` aparece en toda pantalla: acción principal, aviso, selección. Amarillo, azul y rosa marcan el **mundo** de cada cosa (Marca, Producción, Web).
- **Android de verdad:** estructura de Material 3 (barra de navegación inferior, barra superior, hojas inferiores, *snackbars*, gesto Atrás del sistema). La marca entra por el tema: **esquinas en 0**, **sin sombras difusas** (la profundidad es una placa plana desplazada), líneas de 1 px, Knuckle Down en títulos, Jost para leer, JetBrains Mono para índices, fechas y cifras.
- **Índice mono por sección** (`00`–`12`) en la barra superior: la franja que en la web era el riel de 64 px.
- **Momento fuerte:** la pantalla **Hoy**. Saludo en Knuckle Down, el ojo vivo arriba y, debajo, todo lo urgente en un solo vistazo.

## 3. Mapa

```
Entrada ─┬─ Splash (ojo se abre, < 1,5 s; con "reducir movimiento": fijo)
         ├─ Sin sesión → Iniciar sesión ── Olvidé mi contraseña (enlace a cuenta.html)
         ├─ Rol cliente → "Esta app es para el equipo" (acceso negado, con salir)
         └─ Con sesión → HOY

Barra inferior (máx. 5, según permisos)
 ┌──────────┬──────────────┬───────────┬────────────┬────────┐
 │ HOY (00) │ SOLICITUDES  │ AGENDA    │ PROYECTOS  │  MÁS   │   ← admin y "acceso total"
 └──────────┴──────────────┴───────────┴────────────┴────────┘
 HOY ........... pendientes (vencido · hoy · semana), revisiones, solicitudes nuevas*,
                 agenda de hoy*, reuniones pedidas*, mensajes sin ver, por cobrar
 SOLICITUDES ... lista → ficha → [llamar · WhatsApp · correo · estado · responsable · notas
                 · convertir en cliente → crear acceso]
 AGENDA ........ grabaciones + reuniones en una línea de tiempo; pedidas por clientes arriba
                 → ficha (Maps, llamar, equipo, qué prepara) · programar · confirmar
 PROYECTOS ..... lista (filtro mundo/estado) → ficha → entregables · parrilla (si es Redes)
 MÁS ........... 02 Clientes · 04 Parrillas · Mensajes · (P2/P3 cuando existan) · Cuenta
                 (cambiar contraseña, salir) · estado de conexión · versión
```
\* solo si sus permisos lo dejan ver.

### Barra inferior por rol (regla, no lista fija)
1. **Hoy** siempre va primero; **Más** siempre va último.
2. En medio entran **hasta 3** destinos de esta lista de prioridad, solo los que la persona puede ver:
   Solicitudes → Agenda → Proyectos → Clientes → Parrillas → Mensajes.
3. Se muestran en orden fijo: Solicitudes · Clientes · Agenda · Proyectos · Parrillas · Mensajes.

| Rol | Resultado |
|---|---|
| Admin / acceso total | Hoy · Solicitudes · Agenda · Proyectos · Más |
| Manager comercial | Hoy · Solicitudes · Clientes · Proyectos · Más |
| Directora | Hoy · Agenda · Proyectos · Parrillas · Más |
| Editor/a | Hoy · Mensajes · Más |
| Cámara | Hoy · Agenda (sus grabaciones) · Mensajes · Más |

Así funciona también con permisos personalizados, sin casos especiales.

## 4. Flujos P1

| # | Flujo | Pasos (toques) | Notas |
|---|---|---|---|
| F1 | **Entrar** | abrir → Hoy | sesión guardada; si no hay internet, Hoy desde la caché con aviso |
| F2 | **Entregar una tarea** | Hoy → tarea → *Entregar* → enlace **o** cámara/galería/archivo → nota → Enviar | si tiene revisor pasa a "En revisión"; si no, "Aprobado". Confirmación con *snackbar* |
| F3 | **Revisar una entrega** | Hoy → "Te toca revisar" → ver entrega → *Aprobar* / *Devolver* (nota; ¿ronda extra?) | la ronda extra pide confirmación con el valor |
| F4 | **Atender una solicitud nueva** | aviso o Solicitudes → ficha → **Llamar** / **WhatsApp** (mensaje listo) | estado y responsable en una hoja inferior; notas se guardan solas |
| F5 | **Convertir en cliente** | ficha → *Convertir en cliente* → *Crear acceso* → **Compartir** (WhatsApp) | el enlace pasa por `cuenta.html` como en la web |
| F6 | **Ir a una grabación** | Agenda → grabación → **Abrir en Maps** / **Llamar al cliente** | se ve qué debe preparar el cliente y si confirmó |
| F7 | **Confirmar una reunión pedida** | Hoy o Agenda → "Pedida" → fecha, hora, Meet → Confirmar | |
| F8 | **Programar una grabación** | Agenda → **+** → cliente, proyecto, fecha, lugar (buscador), equipo, qué prepara | el equipo es obligatorio salvo si se cancela |
| F9 | **Mover un proyecto** | Proyectos → proyecto → etapa (la ve el cliente) / estado / a cargo | cambios en hoja inferior, guardado inmediato |
| F10 | **Entregables de un proyecto** | proyecto → lista → tocar → hoja de edición; **+** agrega; "Cargar plantilla" | la tabla de 9 columnas de la web pasa a tarjetas |
| F11 | **Parrilla del mes** | Más → Parrillas (o desde el proyecto) → mes → lista por día / vista mes → pieza | barra fija "Enviar N listas al cliente" |
| F12 | **Mensaje al equipo** | Mensajes → **+** → para (todos / persona / proyecto) → enviar | fijar, visto por, marcar visto |
| F13 | **Crear un cliente** | Clientes → **+** → nombre, correo, WhatsApp, departamento → ciudad → *Crear acceso* | teclado de correo y numérico donde toca |

Reglas de interacción:
- **Un solo botón flotante (FAB)** por pantalla, solo cuando hay una acción principal clara (**+** en Agenda, Proyectos, Clientes, Parrilla, Mensajes).
- **Editar = hoja inferior.** Se cierra con el gesto Atrás del sistema; si hay cambios sin guardar, avisa.
- **Acciones peligrosas** con confirmación; eliminar cliente (P3) pide escribir el nombre, como en la web.
- **Gestos con alternativa visible:** deslizar una tarea para entregarla se puede, pero siempre hay botón.
- **Acción principal al alcance del pulgar:** botones de acción en la parte baja de fichas y hojas.

## 5. Estados que se dibujan en cada pantalla clave

| Estado | Cómo se ve |
|---|---|
| Cargando | esqueleto plano de líneas (sin brillos animados) con el índice mono arriba |
| Vacío | **momento de marca**: el ojo + frase en Knuckle Down + qué hacer ("Todavía no llegan solicitudes…") |
| Error | qué pasó en palabras claras + *Reintentar* |
| Sin conexión | franja fija "Sin conexión · viendo datos de las 3:42 p. m."; los botones de guardar se desactivan con explicación |
| Sin permiso | "Esta sección no está en tus permisos. Pídele acceso a Wilmer." |
| **Llegó algo nuevo en vivo** | píldora rosa arriba de la lista "2 nuevas ↑" que **no mueve** lo que estás leyendo; si hay un formulario abierto, nunca lo interrumpe |

## 6. Decisión real para el prototipo: dos direcciones de **Solicitudes**

- **A · Por estado (como la web):** pestañas Nueva · Contactado · Reunión · Propuesta · Ganado, una lista por estado con contador.
- **B · Bandeja:** una sola lista por llegada; las nuevas resaltadas arriba; estado como etiqueta y filtro.
Se dibujan las dos y tú eliges.

## 7. Alcance del prototipo (entregable de la Fase 3)

- HTML/CSS en `design/`, a tamaño real **360×800** y **390×844**, capturas con Playwright.
- Pantallas: splash, login, recuperar contraseña, **Hoy**, Solicitudes (lista A y B + ficha), Clientes, Proyecto, Parrilla (lista/mes y pieza), Agenda, Documentos, Cotización y pago, Métricas, Más, Mensajes, barra para Admin, Manager y Editor, acceso negado.
- Estados de la sección 5 en las pantallas clave.
- **Datos claramente de ejemplo** (marcados "Ejemplo"), nunca clientes reales.
- **Anti-objetivos:** que parezca la web metida en un teléfono; marca gritando dentro de listas y formularios; componentes de iPhone; rosa pequeño sobre crema; esquinas redondeadas; sombras difusas; degradados.

## 8. Abierto (no lo invento)
- Fuentes: Knuckle Down es `.otf` local; Jost y JetBrains Mono se descargan para empaquetarlas en la app (Fase 4).
- Peso de Jost en pantalla pequeña (300 se ve débil): se prueba 400 para leer y se valida contraste AA en el prototipo.
- Íconos: conjunto de líneas a definir en el prototipo (sin inventar un estilo ajeno a la marca).
