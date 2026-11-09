# Auditoría funcional del gestor web · RAKÜN Studio

> Fase 2 · 2026-11-08 · fuente: `Wilmer19png/rakun-web` en el commit `cd85fe1` (rama `main`).
> Solo lectura: no se cambió nada en la web ni en la base de datos.

Se leyeron completos `admin.html`, `app/admin.js`, todos los `app/admin-*.js`, `perms.js`, `pagos.js`, `comisiones.js`,
`quote-calc.js`, `quote-plan.js`, `quote-sources.js`, `metas.js`, `content.js`, `util.js`, `supa.js`, `planes/piezas.js`,
`planes/data.js` (partes usadas), `supabase/schema.sql`, `fase2.sql`…`fase17.sql` y las tres Edge Functions.
Los editores muy largos (`admin-trabajo.js`, `admin-planes.js`, `admin-campanas.js`, `admin-meta.js`) se leyeron en su
estructura, consultas y permisos; su detalle fino se vuelve a leer en la Fase 6, al montar cada uno.

**Cómo leer este documento**
- **Matriz de paridad:** cada función del gestor web y qué se hace con ella en el celular.
  - **Igual:** lo mismo que en la web.
  - **Adaptada:** lo mismo, con otra forma pensada para el dedo y la pantalla pequeña.
  - **Simplificada:** solo una parte en el celular; el resto queda en la web.
  - **Solo web:** no va en la app, con su motivo.
- **RLS** (Row Level Security): reglas dentro de la base de datos que deciden qué filas ve o cambia cada cuenta.
- **RPC:** una función de la base de datos que la app llama por su nombre.
- **P1 / P2 / P3:** prioridad propuesta de montaje (ver sección 6).

---

## 1. Resumen en 10 líneas

1. El gestor tiene 13 secciones (`00`–`12`) y la matriz recoge **107 funciones** (incluidas 4 nuevas que trae la app); todas tienen su decisión (sección 2).
2. **Todo se puede hacer en el celular** salvo tres editores pesados que propongo dejar **solo en la web** (sección 2.4). Tú decides.
3. Las reglas de acceso viven en la base de datos (`public.can`, `public.sees_money`) **y** en la interfaz (`can`, `seesMoney`). La app las copiará igual.
4. La lógica de dinero está en JavaScript del navegador, repartida en **9 archivos**; hay que portarla a Dart con pruebas de paridad (sección 4).
5. Hallé **10 puntos** en la web que conviene que revises (sección 5). **No corregí ninguno.** Dos los comprobé ejecutando el código original.
6. Lo más serio: **quien hace una tarea con pago puede marcarla "aprobada" él mismo** saltándose la web, y los **comprobantes de pago** los puede abrir todo el equipo.
7. Las fechas de pago se guardan en **hora universal**: después de las 7 p. m. en Colombia, un pago queda con fecha del día siguiente.
8. "Imprimir a PDF" no hay que portarlo: la app abre la cotización en la web (`cotizacion.html?…&pdf=1`).
9. Arrastrar para reasignar pasa a una hoja **"Reasignar"**. WebP y PDF a imágenes solo se usan en *Nuestro trabajo*.
10. Navegación: **barra inferior de máximo 5 destinos, armada según los permisos** de cada persona (sección 3.3).

---

## 2. Matriz de paridad

Columnas: **Función** · **Tablas / RPC / almacenamiento** · **Permiso** (interfaz → base de datos) · **Decisión** · **Prio**.
`can(x)` = ver la sección x; `can(x, editar)` = editarla; `$` = ve plata (`seesMoney`); `admin` = solo el administrador.

### 2.1 Entrada y cuenta

| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Iniciar sesión con correo y contraseña | Auth, `profiles` | cualquiera | **Adaptada**: sesión que se mantiene abierta | P1 |
| Solo entra el equipo; un cliente va al portal | `profiles.role` | rol `admin`/`equipo` | **Adaptada**: rol `cliente` → mensaje claro de acceso negado (en v1) | P1 |
| "Olvidé mi contraseña" | Auth → enlace a `cuenta.html` | — | **Igual**: el enlace sigue yendo a `cuenta.html` en la web pública | P1 |
| Cambiar contraseña | Auth (`password.js`) | sesión | **Igual** | P1 |
| Salir | Auth | sesión | **Igual** | P1 |
| Avatar, nombre y área en el menú | `profiles` | sesión | **Adaptada**: en el menú *Más* | P1 |
| Avisos (badges): pendientes, solicitudes nuevas, reuniones pedidas | `deliverables`, `leads`, `meetings`, `followups` | según sección | **Adaptada**: en la barra inferior; se actualizan en vivo (Fase 5) | P1 |
| Abrir una sección por enlace (`#solicitudes`) | — | según sección | **Adaptada**: rutas internas de la app | P1 |

### 2.2 Secciones

#### 00 · Mis pendientes (`admin-entregables.js` → `viewPending`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Saludo y resumen ("tienes N pendientes, M vencidos") | `deliverables` + `projects` + `clients` | siempre (cada quien lo suyo) | **Igual** | P1 |
| Lista agrupada: Vencido · Hoy · Esta semana · Más adelante · Sin fecha | `deliverables` (`assignee_id` = yo, o `reviewer_id` = yo y en revisión) | RLS: asignado/revisor | **Igual** | P1 |
| Filtros por proyecto y por tipo; Pendientes / Terminados | — | — | **Adaptada**: chips desplazables | P1 |
| Cambiar el estado de mi tarea | `deliverables.status` | RLS "cada quien entrega o revisa lo suyo" | **Igual** (ver hallazgo H1) | P1 |
| Entregar: pegar enlace **o** subir archivo (hasta 50 MB) + nota | Storage `entregas` (`storage:ruta`), `deliverables` | asignado | **Adaptada**: compartir desde otra app, galería o archivos | P1 |
| Regla al entregar: si hay revisor distinto de mí → "En revisión"; si no → "Aprobado" | `deliverables` | — | **Igual** (lógica a portar) | P1 |
| Aprobar / Devolver con nota; ronda extra pagada | `deliverables`, RPC `extra_round` | revisor | **Igual** | P1 |
| Abrir brief o entrega (enlace firmado de 1 h si es archivo) | Storage `entregas` | staff | **Igual** (ver H8 sobre la duración) | P1 |
| Mensajes sin ver (3 últimos) y "Marcar visto" | `team_messages`, `message_reads` | staff | **Igual** | P1 |
| "Por cobrar" y "En curso" (pago de tareas + comisiones) | `deliverables.pay_amount`, `commissions` | lo propio | **Igual** | P1 |
| Seguimientos de campañas asignados a mí | `followups`, `leads`, `meta_insights` | asignado | **Igual** | P1 |

#### 01 · Solicitudes (`admin.js` → `viewLeads`, `openLead`) · ✅ en la app (Fase 6, 2026-11-09) salvo «Cotizar» (P2)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Tablero por estado (Nueva → Perdido); en celular, un estado a la vez | `leads` (500 más recientes) | `can(solicitudes)` | **Adaptada**: pestañas de estado con contador | P1 |
| Buscar (nombre, ciudad, plan, enlaces); filtro por mundo; mostrar perdidas | — | — | **Igual** | P1 |
| Tarjeta: plan, si vino de un anuncio, ciudad, nº de enlaces, responsable | `leads`, `profiles` | — | **Igual** | P1 |
| Ficha: datos, perfiles (enlaces seguros), "Quiere", cómo contactar | `leads` | `can(solicitudes)` | **Adaptada**: pantalla completa | P1 |
| **Llamar** a un toque | `leads.phone` | — | **Nueva en la app** (la web no lo tiene) | P1 |
| WhatsApp a un toque con mensaje listo; correo | `leads` | — | **Igual** | P1 |
| Cambiar estado y responsable; notas internas con guardado automático | `leads` | `can(solicitudes, editar)` | **Igual** | P1 |
| Convertir en cliente (crea el cliente si no existe → "ganado" → crear acceso) | `clients`, `leads`, función `invitar` | `can(clientes, editar)` | **Igual** | P1 |
| Cotizar desde la solicitud (crea cliente, pasa a "propuesta", abre cotización) | `clients`, `leads`, `quotes` | `$` + `can(proyectos, editar)` | **Igual** (llega con Cotizaciones) | P2 |
| Eliminar solicitud | `leads` (delete) | `admin` | **Igual**, con confirmación | P1 |

#### 02 · Clientes (`admin.js` → `viewClients`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Lista con contacto, ciudad y si tiene acceso al portal | `clients` | `can(clientes)` | **Adaptada**: tarjetas + búsqueda | P1 |
| Nuevo cliente (nombre, empresa, correo, WhatsApp, departamento → ciudad) | `clients`, `ubicacion.js` + `colombia.js` | `can(clientes, editar)` | **Igual**, teclados correctos por campo | P1 |
| Crear acceso / nuevo enlace (enlace para WhatsApp o correo de invitación) | función `invitar`, `cuenta.html?activar=…` | staff (ver H9) | **Igual**; compartir con la hoja nativa de Android | P1 |
| Eliminar cliente: muestra qué se borra y pide **escribir el nombre** | Storage `documentos`, RPC `delete_client` | `admin` | **Igual**, misma confirmación fuerte | P3 |

#### 03 · Proyectos (`admin-proyectos.js`, `admin-entregables.js`, `admin-dinero.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Lista: mundo, cliente, plan, **etapa (la ve el cliente)**, estado, a cargo | `projects`, `clients`, `profiles` | `can(proyectos)` | **Adaptada**: tarjeta; cambios en una hoja inferior | P1 |
| Nuevo proyecto (cliente, tipo, nombre, plan, fechas, responsable) | `projects` | `can(proyectos, editar)` | **Igual** | P1 |
| Ficha del proyecto: datos y enlace a su cotización | `projects`, `quotes` | `can(proyectos)` | **Igual** | P1 |
| Entregables del proyecto: editar título, tipo, quién hace, quién revisa, fecha, estado, brief | `deliverables` | `can(proyectos, editar)` | **Adaptada**: la tabla de 9 columnas pasa a tarjetas que se editan en una hoja | P1 |
| Cargar la plantilla de entregables del mundo / agregar / quitar | `deliverables`, `TEMPLATES` | `can(proyectos, editar)` | **Igual** | P1 |
| Ir a la parrilla del proyecto (Redes) | — | `can(parrillas)` | **Igual** | P1 |
| **Dinero del proyecto**: cobra el cliente, pagos al equipo, comisión, queda RAKÜN | `deliverables`, `quotes`, `quote_payments`, `commissions`, `app_settings` | `$` | **Igual** (consulta) | P2 |
| Pago por tarea editable; "llenar los pagos vacíos con lo sugerido" | `deliverables.pay_amount/pay_note/round_pay` | `$` + `can(proyectos, editar)` | **Igual** | P2 |
| Registrar el pago del mes de Redes (+ comisión mensual) | `quote_payments`, `commissions` | `$` | **Igual** (ver H4 y H5) | P2 |

#### 03 · Proyectos → Cotizaciones (`admin-cotizaciones.js`, `quote-*.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Tablero: Borrador · Enviada · Aceptada · Anticipo; archivo (pagadas y rechazadas) | `quotes`, `quote_payments` | `$` + `can(proyectos, editar)` (RLS) | **Adaptada**: pestañas | P2 |
| Si el cliente la abrió, barra de lo pagado, aviso de vencida | `quotes.viewed_at` | — | **Igual** | P2 |
| Editor: cliente, nombre, validez, "te atiende" | `quotes`, `clients`, `profiles` | ídem | **Adaptada** | P2 |
| Bloques (Redes, Web, Producción), cada uno será un proyecto; subir/bajar/quitar | `quotes.blocks` (JSON) | ídem | **Adaptada**: pasos en lugar de dos columnas | P2 |
| Agregar líneas desde: planes, cambios al plan, carta del club, librería, tarifas, sugeridos, línea libre (con buscador) | `plan_catalog`, `app_settings.piezas`, `planes/data.js` | ídem | **Adaptada**: buscador a pantalla completa | P2 |
| **Cambiar partes de un plan de Redes** (cambiar pieza, cantidad, quitar, agregar extra de la carta) | `quote-plan.js`, `planes/piezas.js` | ídem | **Adaptada** (lógica idéntica, con pruebas) | P2 |
| Datos de producción: tipo, días, duración, ciudad | `quotes.blocks[].meta` | ídem | **Igual** | P2 |
| Resumen que se calcula solo: descuento, IVA 19 %, total, cuotas (50/50, 40/30/30, 100, otra), mensualidad de Redes | `quote-calc.js` | ídem | **Igual** (lógica con pruebas de paridad) | P2 |
| Guardado automático (0,7 s) | `quotes` | ídem | **Igual** | P2 |
| Enviar al cliente: enlace + WhatsApp/correo; pasa a "Enviada" | `quotes`, `cotizacion.html?c=…` | ídem | **Igual** | P2 |
| Ver el recibo / Descargar PDF | `cotizacion.html` (web) | — | **Adaptada**: abre la página web; no se porta la impresión | P2 |
| **Registrar pago**: monto sugerido de la cuota, medio, fecha, comprobante (archivo o enlace) | `quote_payments`, Storage `entregas/pagos/…` | ídem | **Adaptada**: comprobante con cámara o galería | P2 |
| Con el pago: comisiones, estado "anticipo"/"pagada"; con el **primero**, crea un proyecto por bloque con sus entregables y ofrece crear acceso | `commissions`, `quotes`, `projects`, `deliverables`, `invitar` | ídem | **Igual** (ver H5: no es atómico) | P2 |
| Marcar como rechazada · Eliminar (borrador o rechazada) | `quotes` | ídem · eliminar: `admin` | **Igual** | P2 |

#### 04 · Parrillas (`admin-parrilla.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Elegir proyecto de Redes y mes; anterior/siguiente | `projects` (mundo marca), `posts` | `can(parrillas)` | **Adaptada** | P1 |
| Calendario del mes con piezas por día; contadores por estado; filtro por red | `posts` | `can(parrillas)` | **Adaptada**: vista de lista por día + vista de mes compacta | P1 |
| Ficha de pieza: título, formato, estado, fecha y hora, redes, copy, copy alterno, enlaces, a cargo, pauta, enlace publicado | `posts` | `can(parrillas, editar)` | **Igual** | P1 |
| Ver el cambio que pidió el cliente | `posts.client_note` | — | **Igual** | P1 |
| **Enviar al cliente para aprobar** ("Lista" → "Por aprobar") | `posts` | `can(parrillas, editar)` | **Igual** (el cliente aprueba en el portal con `review_post`) | P1 |
| Duplicar el mes al siguiente como borrador | `posts` | `can(parrillas, editar)` | **Igual**, con confirmación | P1 |
| Eliminar pieza | `posts` | `can(parrillas, editar)` | **Igual** | P1 |

#### 05 · Grabaciones y 06 · Reuniones (`admin-agenda.js`) → en la app: **Agenda**
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Grabaciones próximas / anteriores con equipo y respuesta del cliente | `shoots`, `clients`, `profiles` | `can(grabaciones)` o estar en el equipo (`crew`) | **Adaptada**: Agenda unida (grabaciones + reuniones) con filtro | P1 |
| Programar/editar grabación: cliente, proyecto, fecha, hora, duración, estado, lugar, dirección, **equipo obligatorio**, qué prepara el cliente | `shoots` | `can(grabaciones, editar)` | **Igual** | P1 |
| Buscador de lugares (Photon/OpenStreetMap) + lugares usados antes | API `photon.komoot.io`, `shoots` | — | **Igual** (es un servicio externo gratuito; se revisa su uso en la Fase 4) | P1 |
| "Ya acordamos la nueva fecha" (borra la petición de reprogramar) | `shoots.client_response` | ídem | **Igual** | P1 |
| **Abrir en Maps** y **llamar al cliente** desde la grabación | — | — | **Nueva en la app** | P1 |
| Reuniones: pedidas por clientes (con aviso), agendadas, anteriores | `meetings` | `can(reuniones)` | **Igual** | P1 |
| Confirmar una reunión pedida / agendar / editar: tema, tipo, duración, fecha, Meet, con quién, estado, acuerdos | `meetings` | `can(reuniones, editar)` | **Igual** | P1 |
| Abrir Meet | `meetings.link` | — | **Igual** | P1 |
| Eliminar grabación o reunión | `shoots`, `meetings` | editar | **Igual** | P1 |

#### 07 · Documentos (`admin-documentos.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Lista con filtros: cliente, carpeta, mes; orden; agrupado por mes | `documents` (500), `clients`, `projects` | `can(documentos)` | **Adaptada** | P2 |
| Cambiar estado y "lo ve el cliente" | `documents` | `can(documentos, editar)` | **Igual** | P2 |
| Abrir (enlace firmado de **5 min**) | Storage `documentos` | `can(documentos)` | **Igual** | P2 |
| Subir archivo (hasta 25 MB, privado) **o** guardar un enlace | Storage `documentos/<cliente>/…`, `documents` | `can(documentos, editar)` | **Adaptada**: **cámara**, galería o archivos | P2 |
| Eliminar (borra también el archivo) | Storage, `documents` | editar | **Igual** | P2 |

#### 08 · Nuestro trabajo (`admin-trabajo.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Lista: orden ↑↓, publicar/borrador, ★ en el Inicio (máx. 4), videoteca | `works` | `can(trabajo, editar)` | **Adaptada** | P3 |
| Editor completo: 4 tipos, textos, créditos, portada, fragmentos de video, galerías, reels, paleta, sitio web | `works`, Storage `trabajo` (público) | `can(trabajo, editar)` | **Simplificada** (propuesta): textos, portada y publicar en la app; videos y galerías largas en la web | P3 |
| Imágenes reducidas a **WebP** de máx. 2000 px antes de subir | canvas del navegador | — | **Adaptada**: paquete nativo de compresión (a elegir y justificar en Fase 4) | P3 |
| **PDF del manual → una imagen por página** (pdf.js) | Storage `trabajo` | — | **Solo web** (propuesta): convertir PDFs pesados en el teléfono es lento y frágil | — |
| Eliminar proyecto con todos sus archivos | Storage, `works` | editar | **Igual** | P3 |

#### 09 · Planes y precios (`admin-planes.js`, `admin-pagos.js`, `admin-piezas.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Editar el catálogo de Redes (planes, carta del club, librería), Web y Producción en borrador y **publicar** | `plan_catalog` | `can(planes, editar)` | **Solo web** (propuesta): son tablas densas que cambian los precios públicos; un error en el celular sale en la página | — |
| Recibo: datos legales y **datos de cobro privados** (Nequi, cuenta, llave) | `plan_catalog.recibo`, `app_settings.cobro` | `can(planes, editar)`; cobro: `admin` | **Simplificada**: solo consulta en la app | P3 |
| Inicio: prender/apagar testimonios | `plan_catalog.sitio` | `can(planes, editar)` | **Igual** (un interruptor) | P3 |
| 🔒 Tarifas y pagos: % del manager, pagos por pieza, quién cubre cada rol | `app_settings.pagos` | `admin` | **Adaptada** | P3 |
| 🔒 Piezas de cada plan (precios internos, paquetes) | `app_settings.piezas` | `admin` | **Solo web** (propuesta): misma razón que el catálogo | — |

#### 10 · Equipo (`admin.js` → `viewTeam`, `admin-equipo.js`, `admin-entregables.js` → `teamLoad`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Personas: nombre, área, correo | `profiles` | `can(equipo)` | **Igual** | P1 |
| Editar el área de cada persona | `profiles.area` | `admin` | **Igual** | P3 |
| Invitar al equipo (enlace de un solo uso) | función `invitar` (role `equipo`) | `admin` | **Igual** | P3 |
| **Permisos** por persona: rol listo o personalizado, ver/editar por sección, ve plata | `profiles.perms` | `admin` | **Adaptada** | P3 |
| **Mensajes**: a todos, a una persona o al equipo de un proyecto; fijar; visto por; borrar | `team_messages`, `message_reads` | staff (RLS `message_for_me`) | **Adaptada**: pantalla propia en la app | P1 |
| **Carga de trabajo**: columnas por persona; **arrastrar para reasignar** | `deliverables` | `can(proyectos, editar)` para reasignar | **Adaptada**: lista por persona + hoja **"Reasignar"** | P2 |
| Pagos y comisiones: lo que se le debe a cada quien; marcar pagado | `deliverables.paid_at`, `commissions` | `admin` | **Igual** | P2 |

#### 11 · Métricas (`admin-metricas.js`, `admin-meta.js`, `admin-campanas.js`, `metas.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Resumen 7/30/365 días: visitas, solicitudes, WhatsApp, cotizaciones, vendido, cobrado | RPC `metrics_summary`, `metrics_whatsapp` | `can(metricas)` (ver H3) | **Adaptada**: tarjetas apiladas | P2 |
| Páginas más vistas, "¿Qué buscas?", embudo, de dónde llegan | `metrics_summary` | ídem | **Adaptada** | P2 |
| WhatsApp: desde qué página, botón y anuncio; los últimos | `metrics_whatsapp` | ídem | **Igual** | P2 |
| Planes más pedidos y más vendidos | `metrics_summary` | ídem | **Igual** | P2 |
| Por anuncio y por campaña (conjuntos → anuncios) con semáforo | RPC `metrics_ads`, `leads`, `meta_insights` | ídem | **Adaptada**: niveles que se despliegan | P2 |
| Glosario de métricas con "i"; el admin cambia los rangos | `app_settings.metas` | ver: todos; cambiar: `admin` | **Igual** (en celular ya sale desde abajo) | P2 |
| **Seguimiento** de campañas: tareas, revisiones, reglas (p. ej. responder en 15 min), configuraciones | `followups` | `can(metricas)` o asignado | **Igual** | P2 |
| "Actualizar ahora" desde Meta | función `meta-sync` | `admin` | **Igual** | P2 |
| Conectar cuentas de Meta (RAKÜN y clientes) y **guardar el token** | `meta_accounts`, `meta_tokens` (solo escritura) | `admin` | **Solo web** (propuesta): un token secreto no se escribe desde el celular; la app **nunca** lee `meta_tokens` | — |
| Clientes: resultados de su cuenta de Meta | RPC `meta_client_summary` | `can(metricas)` | **Adaptada** | P2 |

#### 12 · Tarifario (`admin-tarifario.js`, `admin-piezas.js`)
| Función | Datos | Permiso | Decisión | Prio |
|---|---|---|---|---|
| Todo lo que se vende, por pestañas, con buscador | `plan_catalog`, `planes/data.js` | `can(tarifario)` | **Adaptada** | P2 |
| "Tu pago": lo que gana quien mira, según las tarifas | `app_settings.pagos`, `pagos.js` | `can(tarifario)` | **Igual** (lógica con pruebas) | P2 |
| Piezas de cada plan y si la suma da lo publicado | `app_settings.piezas` | `can(tarifario)` | **Igual** (consulta) | P2 |

### 2.3 Lo que la app agrega
- **Llamar** a un toque (Solicitudes, Clientes, Agenda).
- **Abrir en Maps** la dirección de una grabación.
- **Compartir** con la hoja nativa de Android (enlaces de acceso y cotizaciones).
- **Cámara** para documentos, entregas y comprobantes.
- **En vivo** (Fase 5): los cambios aparecen sin recargar. Hoy la web no lo hace.

### 2.4 Propuesta "solo web" (tú decides)
| Función | Motivo |
|---|---|
| Editor del catálogo público (09: Redes, Web, Producción) y Piezas de cada plan | Tablas densas que cambian precios públicos; el riesgo de error en el celular es alto y se usa poco |
| PDF del manual → imágenes (08) | Pesado para el teléfono; se hace una vez por proyecto |
| Conectar cuentas de Meta y escribir el token (11) | Seguridad: el token secreto no debe pasar por el celular |

---

## 3. Permisos y datos por rol

### 3.1 Cómo funcionan hoy
- `profiles.role`: `admin`, `equipo` o `cliente`. `profiles.perms` (JSON): `{ sección: 'ver' | 'editar', dinero: 'ver' }`.
- **`perms = null` significa acceso total**, igual que el admin (salvo lo marcado como `admin`).
- Interfaz (`perms.js`): `can(me, sección, editar)` y `seesMoney(me)`.
- Base de datos (`fase10.sql`): `public.can(sección, editar)` y `public.sees_money()`. Hacen lo mismo, **con una diferencia** (H7).
- Algunas cosas no dependen de la sección sino de la persona: cada quien ve **sus** entregables, grabaciones donde va, mensajes que le llegan, comisiones propias y seguimientos asignados.

### 3.2 Roles listos (`PRESETS`)
| Sección | Admin | Directora | Manager comercial | Editor/a | Cámara | `perms = null` |
|---|---|---|---|---|---|---|
| 00 Pendientes | ✎ | ✎ | ✎ | ✎ | ✎ | ✎ |
| 01 Solicitudes | ✎ | — | ✎ | — | — | ✎ |
| 02 Clientes | ✎ | 👁 nombres* | ✎ | 👁 nombres* | 👁 nombres* | ✎ |
| 03 Proyectos | ✎ | ✎ | ✎ | sus tareas | — | ✎ |
| 04 Parrillas | ✎ | ✎ | — | — | — | ✎ |
| 05 Grabaciones | ✎ | ✎ | — | — | 👁 (+ donde va) | ✎ |
| 06 Reuniones | ✎ | ✎ | — | — | — | ✎ |
| 07 Documentos | ✎ | ✎ | — | — | — | ✎ |
| 08 Nuestro trabajo | ✎ | — | — | — | — | ✎ |
| 09 Planes y precios | ✎ | — | — | — | — | ✎ |
| 10 Equipo | ✎ (+ permisos, pagos) | 👁 | 👁 | 👁 | 👁 | 👁/✎ (sin permisos ni pagos) |
| 11 Métricas | ✎ | — | 👁 | — | — | ✎ |
| 12 Tarifario | ✎ | — | 👁 | — | — | ✎ |
| **Ve plata** | sí | no | **sí** | no | no | sí |

✎ ve y edita · 👁 solo ve · — no lo ve. \*La base de datos deja leer el nombre del cliente a quien ve Proyectos, Parrillas, Agenda, Documentos o Pendientes, para poder mostrarlo.
Solo admin: eliminar solicitudes, clientes y cotizaciones; permisos; invitar al equipo; pagos y comisiones; tarifas; conectar Meta.

### 3.3 Navegación propuesta para la app (se diseña en la Fase 3)
Barra inferior de máximo 5 destinos, **armada según lo que cada persona puede ver**. El resto va en *Más*.

| Rol | Barra inferior |
|---|---|
| Admin | Pendientes · Solicitudes · Agenda · Proyectos · Más |
| Manager comercial | Pendientes · Solicitudes · Clientes · Proyectos · Más |
| Directora | Pendientes · Agenda · Proyectos · Parrillas · Más |
| Editor/a | Pendientes · Mensajes · Más |
| Cámara | Pendientes · Agenda (solo grabaciones) · Mensajes · Más |

### 3.4 RLS por tabla (resumen)
| Tabla | Leer | Escribir |
|---|---|---|
| `profiles` | uno mismo o cualquier staff | admin |
| `leads` | `can(solicitudes)` (el público solo inserta) | actualizar: `can(solicitudes, editar)`; borrar: admin |
| `clients` | `can(clientes)` u otras secciones que necesitan el nombre | `can(clientes, editar)` |
| `projects` | `can(proyectos/parrillas/grabaciones/reuniones/documentos)` o tener una tarea en él | `can(proyectos, editar)` |
| `deliverables` | `can(proyectos)` o asignado/revisor | `can(proyectos, editar)`; asignado/revisor actualiza (protegido por `deliverables_guard`) |
| `quotes`, `quote_payments` | `can(proyectos, editar)` **y** ve plata | ídem |
| `commissions` | la propia o admin | insertar: `can(proyectos, editar)` + plata; pagar/borrar: admin |
| `posts` | `can(parrillas)` | `can(parrillas, editar)` |
| `shoots` | `can(grabaciones)` o en el equipo | `can(grabaciones, editar)` |
| `meetings` | `can(reuniones)` | `can(reuniones, editar)` |
| `documents` + Storage `documentos` | `can(documentos)` | `can(documentos, editar)` |
| `works` + Storage `trabajo` | público lo publicado; equipo `can(trabajo, editar)` | `can(trabajo, editar)` |
| `plan_catalog` | todos (público) | `can(planes, editar)` |
| `app_settings` | ve plata **o** `can(tarifario)` | admin |
| `team_messages` / `message_reads` | lo que me llega / lo mío | staff, autor o admin |
| `followups` | `can(metricas)` o asignado | ídem; borrar: `can(metricas)` |
| `meta_accounts` / `meta_insights` | equipo de métricas | admin |
| `meta_tokens` | **nadie** (solo escritura del admin) | admin |
| `page_events` | `can(metricas)` | el público inserta |
| Storage `entregas` | **cualquier staff** (ver H2) | cualquier staff |

---

## 4. Lógica de negocio que vive en el navegador y hay que portar

Todo esto se porta a Dart **sin cambiar nada** y con **pruebas de paridad**: los mismos casos se ejecutan en Node con el
JS original y en Dart, y deben dar **el mismo resultado al peso, con los mismos redondeos**.

| Archivo | Qué calcula | Riesgo si se calcula distinto |
|---|---|---|
| `quote-calc.js` | total de línea y bloque, descuento (tope = suma), IVA 19 % redondeado, cuotas (la última se lleva el resto), mensualidad de Redes, vencimiento | **Alto**: cifras distintas en web y app |
| `quote-plan.js` + `planes/piezas.js` | cambiar partes de un plan: alternativas, cantidades, quitar, extras de la carta, `changesOf`, `pricedWith` (nunca menor que 0) | **Alto** |
| `quote-sources.js` | de dónde salen las líneas (catálogo publicado sobre los datos base), plantillas de entregables, tipos y estados | Medio |
| `planes/data.js` | datos base de Redes y Web cuando no hay nada publicado; `priceInCarta`, `isRedes` | Medio |
| `pagos.js` | % y pagos (versión 2), `planManager`, `oneTimeManager`, `planTeam`, `partsForPlan`, `planOfLine`, **redondeo a la centena** (`r100`) | **Alto** |
| `comisiones.js` | filas de comisión mensual y única, proporcionales a lo pagado | **Alto** |
| `admin-cotizaciones.js` → `payQuote` | monto sugerido de la siguiente cuota, paso a "anticipo"/"pagada", crear proyectos y entregables (revisor = responsable si lo hace otro) | **Alto** |
| `admin-dinero.js` | cobra el cliente, pagos del periodo, margen, nº de mes, qué pago va a cada tipo de tarea | **Alto** |
| `admin-entregables.js` | grupos por vencimiento, textos "venció hace N d", regla de entregar | Bajo |
| `metas.js` | CPM, gancho, retención, CTR, CPC, conversión, costo por lead, frecuencia y su semáforo | Bajo (solo consulta) |
| `admin-campanas.js` | agrupar campañas, día N, estado de reglas (SLA de leads) | Bajo |
| `perms.js` | `can`, `seesMoney`, `presetOf` | **Alto** (seguridad de la interfaz) |
| `util.js` | número para WhatsApp (agrega 57 a celulares de 10 dígitos), enlace seguro, "hace 2 h" | Bajo |

Detalles a respetar:
- `Math.round` de JavaScript redondea .5 hacia arriba; en Dart `round()` redondea .5 alejándose de cero. En negativos dan distinto: las pruebas lo cubrirán.
- Los números se formatean en `es-CO` (`$1.234.567`).
- Las fechas de los formularios usan la hora local; algunos "hoy" usan la universal (H4). La app copiará el comportamiento actual hasta que decidas.

---

## 5. Hallazgos para revisar en la web (no corregí nada)

| # | Qué pasa | Gravedad | Cómo lo comprobé | Qué propongo |
|---|---|---|---|---|
| **H1** | Quien **hace** una tarea puede marcarla "Aprobada" él mismo aunque tenga revisor. La web lo esconde, pero la base de datos lo permite (la regla de actualización y `deliverables_guard` no revisan el estado). Si la tarea tiene pago, pasa a "por cobrar". | Alta (dinero) | Lectura de `fase10.sql` y `fase15.sql` | Migración aditiva: en `deliverables_guard`, si hay revisor y no soy el revisor ni editor de proyectos, no dejar pasar a "aprobado" |
| **H2** | La carpeta `entregas` (entregas **y comprobantes de pago** en `pagos/…`) la puede leer **cualquier persona del equipo**, aunque no vea plata. | Alta (privacidad) | `fase7.sql`, política "rakun equipo entregas" | Regla aparte para `pagos/…`: solo quien ve plata |
| **H3** | Métricas muestra **Vendido, Cobrado y planes vendidos** a quien tenga Métricas, aunque no vea plata (`metrics_summary` no revisa `sees_money`). | Media | `fase11.sql` | Que la función devuelva esas cifras en cero o nulas si no ve plata, y la app las oculte |
| **H4** | Los "hoy" de pagos usan la hora universal: **después de las 7 p. m. en Colombia el pago queda con fecha del día siguiente**; el último día del mes, la comisión cae en el mes siguiente. Pasa al registrar el pago (`payQuote`), el pago del mes y "marcar pagado". | Media (dinero) | **Ejecutado**: 31-oct 8:30 p. m. → `2026-11-01`, comisión de noviembre | Usar la fecha local de Bogotá. La app, por ahora, **copiará** lo actual hasta que decidas |
| **H5** | Registrar un pago son **varios pasos sueltos** (subir comprobante → pago → comisiones → estado → proyectos → entregables). Si uno falla a mitad, queda a medias; al reintentar, no vuelve a crear los proyectos que faltaron. Y si guardar la **comisión** falla, **no avisa** (el error se ignora). | Media (dinero) | Lectura de `admin-cotizaciones.js` y `comisiones.js` | Mover el flujo a una RPC en una sola transacción; mientras tanto, al menos avisar si la comisión no se guardó |
| **H6** | **Error de cálculo**: en un plan "con grabación" al que se le **quita** la grabación, el manager gana **$18.000 menos al mes** en Gestión Ritmo (venta $151.200 en vez de $199.200, y cobra $30.000 de una grabación que ya no existe). | Media (dinero, caso raro) | **Ejecutado** con `pagos.js` y `comisiones.js` originales | Corregirlo en `planManager` cuando lo apruebes; la app lo copiará igual hasta entonces y la prueba de paridad lo dejará marcado |
| **H7** | "Mis pendientes": la interfaz siempre deja verlo; la base de datos solo si el permiso `pendientes` está marcado. Hoy todos los roles listos lo traen, así que no se nota. | Baja | `perms.js` vs `fase10.sql` | Igualar la función de la base de datos |
| **H8** | Los enlaces temporales de `entregas` duran **1 hora**; los de `documentos`, **5 minutos** (el encargo pide 5 min). | Baja | `admin-entregables.js` vs `content.js` | Decidir: ¿bajo las de `entregas` a 5 min en la app? |
| **H9** | La función `invitar` deja crear accesos de **cliente** (y un enlace para poner una contraseña nueva a un cliente que ya tiene cuenta) a **cualquier persona del equipo**, aunque no tenga permiso de Clientes. | Media | `functions/invitar/index.ts` | Revisar `can('clientes', true)` dentro de la función |
| **H10** | `app_settings` (que incluye los **datos bancarios** de cobro y los % de comisión) lo puede leer quien tenga Tarifario aunque no vea plata. | Baja | `fase10.sql` | Separar `cobro` y `pagos` del permiso de Tarifario |

**Preguntas de negocio** (no son errores, necesito tu respuesta):
1. El **pago del mes 2 en adelante** de Redes se sugiere sin el descuento de la cotización. ¿Es a propósito?
2. La "ronda extra" solo se ofrece desde la segunda devolución, pero la web no cuenta las devoluciones: lo decide quien revisa. ¿Está bien así?

---

## 6. Prioridad propuesta

**P1 · uso diario (primer APK de prueba)**
Entrada y cuenta · 00 Pendientes (entregar, aprobar, devolver) · 01 Solicitudes (llamar y WhatsApp a un toque, convertir en cliente) ·
02 Clientes (crear acceso) · 03 Proyectos y sus entregables (sin dinero) · Agenda (05 Grabaciones + 06 Reuniones) ·
04 Parrillas (enviar al cliente para aprobar) · Mensajes del equipo.

**P2 · consulta y dinero**
07 Documentos con cámara y subida · Cotizaciones y pagos · Dinero del proyecto · Carga de trabajo con "Reasignar" ·
Pagos y comisiones (admin) · 11 Métricas de consulta y seguimiento · 12 Tarifario · Cotizar desde una solicitud.

**P3 · edición pesada**
08 Nuestro trabajo (simplificada) · 09 Tarifas y pagos, Recibo (consulta), Inicio · 10 Permisos, áreas, invitar al equipo · Eliminar cliente.

**Solo web (propuesta):** editor del catálogo y piezas · PDF a imágenes · conectar Meta y tokens.

---

## 7. Decisiones de Wilmer (2026-11-08)

- ✅ **Alcance y prioridad P1 / P2 / P3: aprobados.**
- ✅ **Las tres funciones "solo web" (sección 2.4): aprobadas.**
- ⏳ Hallazgos H1–H10: sin decisión aún. Quedan anotados; **no se toca `rakun-web`** hasta que Wilmer lo pida.
- ⏳ Barra inferior por rol (3.3): se usa como punto de partida del diseño en la Fase 3; se valida allí.
- ⏳ Preguntas de negocio (descuento desde el mes 2, ronda extra): se resuelven antes de montar P2.

## 8. Preguntas que se le hicieron a Wilmer (ALTO)

1. ¿Apruebas el alcance y la prioridad P1 / P2 / P3?
2. ¿Aceptas las tres funciones **solo web** de la sección 2.4, o quieres alguna en la app?
3. ¿Qué hacemos con los hallazgos H1–H10? Mi sugerencia: **H1, H2 y H4** se preparan como migraciones o arreglos en una rama de `rakun-web` (tú decides cuándo se fusionan), y el resto se anota para después.
4. ¿La barra inferior por rol (sección 3.3) va bien como punto de partida para el diseño?
5. Las dos preguntas de negocio de la sección 5.
