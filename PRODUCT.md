# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Flutter (stable) para Android. iOS fuera de alcance (no hay Mac). Paquetes base previstos en el encargo: `supabase_flutter`, Riverpod, `go_router`; versiones a consultar en pub.dev en la Fase 4. Backend compartido con la web: el mismo proyecto Supabase de producción (Auth, Postgres con RLS, Storage, Edge Functions). Diseño previo en HTML/CSS dentro de `design/` (Fase 3) antes de tocar Flutter.

## Users

- **Primario: Wilmer Alejandro Buriticá (admin, director).** Es quien más la abre. Acceso total, incluido dinero.
- **Equipo RAKÜN** con roles y permisos por persona (`app/perms.js` de la web): directora, manager comercial, editor/a, cámara. Cada uno ve solo sus secciones; un Editor ve Pendientes y Equipo.
- **Futuro: clientes.** El portal de clientes vivirá en esta misma app y con la misma marca, en una fase posterior. En la v1 una cuenta con rol `cliente` recibe un mensaje claro de acceso negado.

Situaciones de uso confirmadas (todas):
- En rodajes y grabaciones: de pie, con prisa; agenda, llamar al cliente, abrir el documento o guion.
- En la calle, entre citas: atender solicitudes nuevas, llamar o escribir por WhatsApp a un toque.
- Revisión rápida durante el día: pendientes, aprobar parrillas, mensajes del equipo.
- Trabajo largo en el celular: crear cotizaciones y editar proyectos completos desde el teléfono.

## Product Purpose

RAKÜN Studio es la versión móvil del gestor interno de RAKÜN Visual Design (`admin.html` en `rakun-web`). Permite manejar el estudio desde el teléfono: solicitudes, clientes, proyectos, parrillas, grabaciones, reuniones, documentos, cotizaciones y pagos, equipo y métricas. Éxito = el equipo deja de necesitar el computador para el trabajo diario y la app y la web muestran siempre los mismos datos y las mismas cifras.

## Positioning

Una herramienta de trabajo diario, no una página para persuadir: rapidez, claridad y densidad bien manejada. Es la misma operación del estudio que la web, con la misma base de datos, pensada para el pulgar y para momentos de prisa, sin dejar de poder hacer trabajo largo.

## Operating Context

- Web y app comparten Supabase de producción con clientes reales; no hay entorno de pruebas.
- Las secciones del gestor (índices `00` a `12`): Mis pendientes, Solicitudes, Clientes, Proyectos (cotizaciones y dinero del proyecto), Parrillas, Grabaciones, Reuniones, Documentos, Nuestro trabajo, Planes y precios, Equipo, Métricas, Tarifario.
- Tres mundos de servicio con código de color: Marca (amarillo), Producción (azul), Web (rosa).
- Los enlaces de invitación y recuperación apuntan a `cuenta.html` en la web pública.
- Contacto con clientes por llamada y WhatsApp.

## Capabilities and Constraints

- Permisos en dos niveles: RLS (`public.can`) y la interfaz (`can`, `seesMoney`); `perms = null` significa acceso total. La navegación se arma según permisos.
- Reglas de dinero hoy en JavaScript del navegador (`quote-calc`, `comisiones`, `pagos`, `metas`, flujo de cotizaciones): deben portarse con pruebas de paridad; mismas cifras y redondeos que la web.
- Sincronización en vivo aún no existe (Fase 5): al llegar un evento se vuelve a consultar, no se confía en su contenido.
- Sin conexión: solo lectura en caché y aviso claro; en v1 no hay escrituras en cola.
- `meta_tokens` nunca se lee ni se muestra. La `service_role` nunca va en la app.
- Funciones del navegador (WebP con canvas, PDF a imágenes, arrastrar para reasignar, imprimir a PDF) necesitan solución nativa.
- Identificador de la app: `com.rakundesigns.app` (permanente). Nombre visible: **RAKÜN Studio** (se puede cambiar).
- Decisión abierta: alcance exacto del portal de clientes (fase posterior).

## Brand Commitments

- Marca: RAKÜN Visual Design (Ü en rosa). Voz: directa, visual, actitud punk pero profesional. Español.
- Identidad heredada de `rakun-web/DESIGN.md` (con sus revisiones del 2026-10-05): rosa `#FF2C68` protagonista, superficie oscura `#010221`, Knuckle Down en títulos, radio 0, sin sombras difusas ni degradados, ojo vivo, isotipo, badge y onda.
- Regla del encargo: la marca grita en los bordes (splash, encabezados, estados vacíos) y se calla en el trabajo (listas y formularios sobrios y rápidos).

## Evidence on Hand

- Datos reales: solo los de Supabase de producción. La app no inventa clientes, cifras ni testimonios. En prototipos se usan datos claramente de ejemplo.
- Activos de marca en `rakun-web`: `fonts/KnuckleDown.otf`, `assets/rakun-isotipo.svg`, `assets/pattern-wave.svg`, `eye.js` (física del ojo).
- Equipo actual: 7 personas (dirección, fotografía/edición, dirección de arte, diseño, desarrollo web, manager, producción).

## Product Principles

1. Rápido primero: lo diario se hace en pocos toques y con una mano.
2. Una sola verdad: mismos datos, mismas cifras y mismos permisos que la web.
3. Cada quien ve lo suyo: la navegación y el dinero respetan los permisos de cada persona.
4. Marca en los bordes, calma en el trabajo.
5. Honestidad: nunca datos inventados; si algo falla o no hay conexión, se dice claro.

## Accessibility & Inclusion

WCAG AA de contraste (nada de rosa pequeño sobre crema), áreas táctiles de mínimo 48dp, texto grande del sistema, lector de pantalla, "reducir movimiento" respetado (incluido el ojo y la entrada de menos de 1,5 s), teclados correctos por campo y zonas seguras.
