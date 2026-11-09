# Aprobación del diseño · RAKÜN Studio

> Marca cada pantalla con **[x]** si está bien o escribe al lado qué cambiar.
> El diseño solo queda aprobado cuando escribas exactamente: **`DISEÑO APROBADO`**.
> Capturas en `design/capturas/360x800/` y `design/capturas/390x844/` (mismo nombre en las dos carpetas).

## Cómo abrir el prototipo
1. En una terminal: `node design/servir.mjs` (desde la carpeta `rakun-app`).
2. Abre **http://localhost:5173** en Chrome: es la galería con todas las pantallas, el cambio de tamaño y de rol.
3. Para sentirlo como en el teléfono: abre una pantalla sola (↗) y activa el modo dispositivo de Chrome (F12 → ícono de celular).

## Decisión pendiente
- [ ] **Solicitudes: dirección A** (pestañas por estado, como la web) — `20-solicitudes-A`
- [ ] **Solicitudes: dirección B** (bandeja única: sin atender arriba) — `21-solicitudes-B`

## Entrada
- [ ] `01-splash` · el ojo se abre, RAKÜN, onda
- [ ] `02-login` · iniciar sesión
- [ ] `03-recuperar` · olvidé mi contraseña
- [ ] `04-sin-acceso` · cuenta de cliente en v1

## P1 · uso diario
- [ ] `10-hoy` · inicio: saludo, vencidos, hoy, revisar, solicitudes, agenda, mensajes, lo que ganas
- [ ] `11-hoy-entregar` · entregar desde Hoy (hoja)
- [ ] `12-tarea` · ficha de una tarea
- [ ] `13-revisar` / `14-revisar-devolver` · aprobar o devolver (ronda extra)
- [ ] `22-solicitud` / `23-solicitud-estado` · ficha con Llamar · WhatsApp · Correo
- [ ] `24-clientes` / `25-clientes-nuevo` / `26-clientes-acceso` · lista, nuevo, crear acceso
- [ ] `30-proyectos` · lista con etapa y vencidos
- [ ] `31-proyecto` / `32-proyecto-editar` / `33-proyecto-etapa` · etapa (la ve el cliente) y entregables
- [ ] `40-agenda` / `41-agenda-confirmar` / `42-agenda-programar` · grabaciones + reuniones
- [ ] `43-grabacion` · cómo llegar, llamar, qué prepara el cliente
- [ ] `50-parrilla` / `51-parrilla-pieza` · por día (y vista de mes), enviar al cliente
- [ ] `60-mensajes` · mensajes del equipo
- [ ] `61-mas` · el resto de secciones según permisos y la cuenta

## P2 · consulta y dinero
- [ ] `70-documentos` · con escáner de la cámara
- [ ] `71-cotizacion` · bloques, cuotas y total
- [ ] `72-cotizacion-pago` · registrar pago (con el primero se crean los proyectos)
- [ ] `73-metricas` · resumen, por anuncio con semáforo de forma

## Estados
- [ ] `80` cargando · [ ] `81` vacío · [ ] `82` error · [ ] `83` sin conexión · [ ] `84` sin permiso · [ ] `85` llegó algo en vivo

## Barra inferior por rol
- [ ] `90` Admin · [ ] `91` Manager · [ ] `92` Directora · [ ] `93` Editor/a · [ ] `94` Cámara

## Sistema (design/DESIGN_MOVIL.md)
- [ ] Fondo noche siempre, rosa en toda pantalla, colores por mundo
- [ ] Jost 400 para leer (en vez de 300), Knuckle Down solo en títulos
- [ ] Verde nuevo `#4FB58C` y gris terciario `#9A97BD`
- [ ] Botón flotante con placa amarilla desplazada
- [ ] Ojo vivo en entrada, Hoy y pantallas vacías

## Comentarios generales
(escribe aquí)
