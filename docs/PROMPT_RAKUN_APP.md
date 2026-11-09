# PROYECTO: RAKÜN GESTOR, APP MÓVIL EN FLUTTER

Responsable y aprobador único: **Wilmer Alejandro Buriticá**, director y productor de RAKÜN Visual Design.
Háblame siempre en español, en lenguaje claro. Cuando uses un término técnico, explícalo en una frase.

## 1. Qué vas a construir

Convierte el gestor interno de mi página (`admin.html` y `app/admin*.js`) en una aplicación móvil en Flutter para mí y mi equipo.

- La app y la página deben usar **la misma base de datos Supabase**. Si entra un cliente o una solicitud por la página, aparece en la app. Si algo cambia en la app, aparece en la página.
- Debe respetar la identidad de RAKÜN, adaptada de verdad a móvil. No es la página metida en un teléfono.
- **Primero va el diseño. No se monta ninguna pantalla en Flutter hasta que yo lo apruebe.**
- Todo queda en Git y documentado paso a paso en el README.
- Fuera de alcance por ahora: el portal de clientes (`portal.html`) y las páginas públicas. Deja la arquitectura lista para sumar el portal después, pero no lo construyas.

## 2. Lo que ya se sabe del proyecto actual

Se revisó el repositorio `Wilmer19png/rakun-web` (privado, último commit `cd85fe1`). Compruébalo tú también; si algo no coincide, avísame.

**Tecnología de la web**
- HTML, CSS y JavaScript sin framework ni proceso de compilación. Se publica en Netlify (no hay `netlify.toml`; existe `_headers` en la raíz).
- Backend en Supabase: Auth, Postgres con RLS (reglas de acceso), Storage y Edge Functions.
- Conexión en `app/config.js` y `app/supa.js`. La llave ahí es la publicable: puede ir en la app. **La `service_role` jamás va en la app ni en Git.**
- Migraciones numeradas y manuales: `supabase/schema.sql` y `supabase/fase2.sql` a `fase17.sql`, documentadas en `supabase/LEEME.md`.

**Secciones del gestor** (`app/perms.js`)
00 Mis pendientes · 01 Solicitudes · 02 Clientes · 03 Proyectos (incluye Cotizaciones y Dinero del proyecto) · 04 Parrillas · 05 Grabaciones · 06 Reuniones · 07 Documentos · 08 Nuestro trabajo · 09 Planes y precios (incluye Recibo y Tarifas y pagos) · 10 Equipo (permisos, mensajes, carga de trabajo, pagos y comisiones) · 11 Métricas (incluye Meta, campañas y seguimiento) · 12 Tarifario.

**Datos**
- Tablas que usa el gestor: `profiles, leads, clients, projects, posts, plan_catalog, documents, shoots, meetings, works, quotes, quote_payments, deliverables, app_settings, team_messages, message_reads, commissions, followups, meta_accounts, meta_insights, meta_tokens`. La tabla `page_events` guarda el contador de la página.
- RPC: `team_members, review_post, respond_shoot, quote_public, quote_accept, metrics_summary, metrics_ads, metrics_whatsapp, meta_client_summary, extra_round, delete_client`.
- Edge Functions: `invitar`, `meta-sync`, `aviso-lead` (esta última corre por webhook al insertar en `leads`).
- Storage: `documentos` (privado, enlaces temporales de 5 minutos), `entregas` (privado), `trabajo` (público).

**Trampas que debes resolver**
1. **La sincronización en vivo no existe todavía.** La web no usa Realtime y ninguna migración activa `supabase_realtime`. Los datos son los mismos, pero hoy hay que recargar para ver los cambios.
2. **Hay reglas de dinero en JavaScript del navegador**, no en la base de datos: `app/quote-calc.js`, `app/comisiones.js`, `app/pagos.js`, `app/metas.js` y el flujo de `app/admin-cotizaciones.js` (con el primer pago se crean proyectos y entregables). Si la app las calcula distinto, web y app darán cifras diferentes. Hay que portarlas con pruebas de paridad.
3. **Los permisos se aplican en dos niveles**: RLS (`public.can`) y la interfaz (`can` y `seesMoney` en `app/perms.js`). `perms = null` significa acceso total. La navegación de la app debe construirse según los permisos: un Editor solo ve Pendientes y Equipo.
4. **Los enlaces de invitación y recuperación** apuntan a `cuenta.html` en la web (`accountUrl`). Desde la app deben seguir apuntando a la URL pública de esa página, para no tocar la configuración de Auth.
5. **Funciones que dependen del navegador**: reducción a WebP con canvas, PDF a imágenes con pdf.js (`admin-trabajo.js`), arrastrar para reasignar (`admin-entregables.js`), imprimir a PDF. Necesitan una solución nativa.
6. **`meta_tokens` es de solo escritura** en la práctica. La app nunca debe leer ni mostrar esos tokens.
7. **La base de datos es la de producción, con clientes reales.** No hay entorno de pruebas (ver reglas).

## 3. Decisión sobre los repositorios

Crea **un repositorio nuevo y privado: `Wilmer19png/rakun-app`**, en una carpeta **hermana** de la web, nunca dentro de ella:

    (carpeta madre)/
    ├── rakun-web/     ← repo actual, se publica en Netlify
    └── rakun-app/     ← repo nuevo, Flutter

Motivo: la web no se compila y Netlify probablemente publica su raíz, así que una carpeta Flutter adentro quedaría expuesta en internet y cada cambio de la app dispararía un despliegue. Lo que une a las dos es Supabase, no el repositorio.

Las migraciones siguen viviendo **solo** en `rakun-web/supabase/` (fuente única). `rakun-app` las referencia en su documentación, no las copia.

Las carpetas de trabajo y las rutas no deben tener espacios, tildes ni la Ü, porque eso rompe Gradle y algunas herramientas de Android.

## 4. Reglas que no se negocian

1. **Puntos de aprobación.** Detente y espera mi respuesta donde diga `ALTO`. El diseño solo queda aprobado si escribo exactamente `DISEÑO APROBADO`. Un "me gusta" o "va bien" no cuenta.
2. **Producción.**
   - Nada de `DROP`, `TRUNCATE`, borrados masivos ni cambios de estructura sin mostrarme el SQL y recibir mi aprobación.
   - Solo migraciones aditivas y que se puedan volver a correr, con el formato de las fases existentes.
   - Los datos de prueba llevan el prefijo `PRUEBA APP` y se limpian al terminar, indicándome cuáles fueron.
   - Nunca ejecutes `delete_client` sobre registros reales, ni registres pagos, comisiones o invitaciones reales para probar.
3. **Secretos.** No me pidas contraseñas ni llaves en el chat. Van en archivos locales ignorados por Git o los escribo yo directamente en la app. Nunca subas `.env`, `env.json`, `key.properties`, keystores ni `service_role`. Antes de cada push, revisa que no se vaya ninguno.
4. **`rakun-web` no se daña.** Nunca hagas push directo a `main`, porque eso publica la página. Cualquier cambio va en una rama, me lo explicas y yo decido cuándo se fusiona.
5. **Nada se elimina en silencio.** Toda función del gestor aparece en la matriz de paridad con su decisión. Si algo no se puede hacer en móvil, me lo dices.
6. **No inventes datos** en la app real. Sin testimonios, cifras ni clientes falsos. En los prototipos, usa datos claramente de ejemplo.
7. **Comprueba antes de decir que algo funciona.** Ejecuta, prueba y muestra el resultado. Si algo falla o quedó a medias, dilo tal cual.
8. **Versiones reales.** No pongas versiones de memoria: consulta las estables actuales de Flutter y de cada paquete en pub.dev.
9. **Continuidad.** Mantén `CLAUDE.md` en `rakun-app` con estas reglas y el estado actual, para que cualquier sesión nueva retome sin perder contexto.

## 5. Forma de trabajo con Git

- Rama `main` siempre estable. Una rama por bloque: `fase-3/diseno`, `fase-6/solicitudes`, etc.
- Commits pequeños, en español: `diseno: pantalla de solicitudes`, `feat(clientes): ...`, `fix: ...`.
- **Push al terminar cada bloque**, y fusión a `main` cuando esté verificado.
- Etiquetas: `v0.1-diseno-aprobado`, `v0.2-base`, `v0.3-sync`, `v1.0-gestor`.
- `.gitignore` de Flutter completo, más `env.json`, `.env*`, `*.jks`, `*.keystore`, `key.properties`.

## 6. README obligatorio, paso a paso

`rakun-app/README.md` se actualiza **en el mismo commit** de cada bloque y debe servirle a alguien que no sea programador. Contiene:

- Portada: **RAKÜN Gestor**, app móvil de RAKÜN Visual Design. Dirección y producción: Wilmer Alejandro Buriticá.
- Qué es, cómo se relaciona con `rakun-web` y un diagrama simple de la conexión con Supabase.
- Requisitos e instalación desde cero.
- Cómo correr la app en celular físico y en emulador, sin Android Studio.
- Estructura de carpetas explicada.
- Variables y configuración, sin valores secretos.
- Cómo generar el APK y cómo instalarlo.
- Solución de problemas: cada error real que aparezca y cómo se arregló.
- **Bitácora**: una entrada por paso con fecha, qué se hizo, por qué, comandos usados, resultado y cómo comprobarlo.
- Estado actual y próximos pasos.

## 7. FASES

Lleva una lista de tareas visible. Al cerrar cada fase dame: qué se hizo, cómo lo comprobaste, qué falta y qué necesitas de mí.

### FASE 0 · Reconocimiento y ambiente de desarrollo

Solo diagnóstico y arreglos del ambiente. No crees código de la app todavía.

**Ubicación.** Detecta el sistema operativo y dónde está mi clon de `rakun-web`. Si no está, clónalo. Revisa que esté actualizado sin tocar mis cambios locales.

**Revisa cada punto y entrégame una tabla** (herramienta · versión · estado · acción):
- Git con mi identidad configurada; GitHub CLI (`gh auth status`) con acceso a `Wilmer19png`.
- Node, npm y npx.
- Flutter en canal stable y Dart, en el PATH, en una ruta sin espacios; `flutter doctor -v` completo.
- JDK compatible con la versión de Gradle que use Flutter.
- Android SDK: `platform-tools`, `platforms`, `build-tools`, `cmdline-tools`, licencias aceptadas.
- `adb devices`; emulador y aceleración por hardware; RAM y disco disponibles.
- En Windows: modo desarrollador (lo requieren los plugins de Flutter) y compatibilidad de la ruta de usuario.
- Chrome, VS Code y sus extensiones de Flutter y Dart.
- Supabase CLI (opcional). Conexión al proyecto con una consulta de solo lectura.
- Skills de Claude Code: **Impeccable** y **frontend-design**.

**Android Studio no funcionó en mi equipo.** No hace falta para compilar. Primero mira si la falla es rápida de resolver; si no, sigue sin él:
1. Instala las Android Command-line Tools y con `sdkmanager` los componentes necesarios.
2. Conecta el SDK con `flutter config --android-sdk`, y el JDK con `flutter config --jdk-dir` si hace falta.
3. Acepta las licencias con `flutter doctor --android-licenses`.
4. Crea un emulador con `avdmanager`, o usa mi celular por depuración USB si el equipo es justo de recursos.

Un aviso de `flutter doctor` que diga solo "Android Studio no instalado" es aceptable si todo lo demás está en verde. Corrobóralo compilando y corriendo una app de prueba temporal fuera de los repositorios, y luego bórrala.

**Arregla lo que falte.** Antes de instalar, dime qué vas a instalar y por qué. Usa el gestor del sistema (winget, brew, apt). Si algo requiere permisos que no tienes, dame el comando exacto. iOS solo se compila en Mac y con cuenta de Apple: si no estoy en Mac, el objetivo es Android y lo dejas anotado.

**Skills.**
- Impeccable: `npx impeccable install --providers=claude --scope=project` dentro de `rakun-app` cuando exista.
- frontend-design: si no aparece, añádelo desde `github.com/anthropics/skills/tree/main/skills/frontend-design` a las skills del proyecto.
- Si hay que reiniciar la sesión, guarda el estado en `CLAUDE.md` y dime exactamente qué escribir para continuar.

**Revisión adicional, solo reportar:** si Netlify publica la raíz, carpetas como `supabase/` y archivos como `DESIGN.md` podrían verse en internet. Compruébalo con una petición normal a la URL pública y dime qué encontraste. No lo cambies.

`ALTO`: muéstrame la tabla y lo pendiente. Continúa cuando te confirme.

### FASE 1 · Repositorio y organización

Propónme el identificador de la app (sugerencia: `com.rakundesign.gestor`), porque no se puede cambiar después de publicar. Tras mi confirmación:

1. Crea `rakun-app` local, inicializa Git, y crea el remoto privado con `gh repo create Wilmer19png/rakun-app --private`.
2. Crea `CLAUDE.md`, `README.md`, `.gitignore`, y las carpetas `docs/` y `design/`.
3. Instala las skills. Crea para este proyecto su propio `PRODUCT.md` y `DESIGN.md` con `/impeccable init` o el comando equivalente de la versión instalada, tomando como base los de `rakun-web` y `.impeccable/design.json`.
4. El `PRODUCT.md` de la web describe visitantes a los que hay que persuadir. El de la app describe **una herramienta de trabajo diario** para el equipo: rapidez, claridad y densidad bien manejada.
5. Primer commit y push.

### FASE 2 · Auditoría funcional del gestor

Lee a fondo `admin.html`, todos los `app/admin*.js`, `perms.js`, `pagos.js`, `comisiones.js`, `quote-*.js`, `metas.js` y todos los SQL. Escribe `docs/AUDITORIA_GESTOR.md` con:

- **Matriz de paridad**: cada sección y subfunción, con tablas y RPC que usa, permisos, y decisión para móvil (igual, adaptada, simplificada o solo web, con motivo).
- Mapa de datos y de reglas RLS por rol: admin, directora, manager, editor, cámara.
- Inventario de lógica de negocio en el cliente que debe portarse.
- Prioridad propuesta:
  - P1 (uso diario): Pendientes, Solicitudes (con llamar y WhatsApp a un toque), Clientes, Proyectos, Agenda de grabaciones y reuniones, aprobación de Parrillas, Mensajes.
  - P2: Documentos (con cámara y subida), Cotizaciones y pagos, Métricas de consulta, Tarifario.
  - P3 (edición pesada): Nuestro trabajo, editor de Planes y precios, Tarifas y pagos, Permisos.

`ALTO`: revisemos juntos el alcance y la prioridad antes de diseñar.

### FASE 3 · DISEÑO (con aprobación obligatoria)

Usa **Impeccable** y **frontend-design** durante toda la fase. Trabaja en HTML/CSS en `rakun-app/design/`, a tamaño real de teléfono (360×800 y 390×844), con Playwright para las capturas. Flutter todavía no se toca.

**La identidad se conserva** (fuente: `rakun-web/DESIGN.md`, incluidas sus revisiones del 2026-10-05):
- Rosa `#FF2C68` protagonista en toda pantalla. Superficie oscura `#010221`. Navy `#1B1A35`, deep `#14132B`, crema `#F3F0EA`, amarillo `#FFF02B`, azul `#2BCDFF`, mist `#C3C0DD`, ink-soft `#3C3A5C`.
- Texto navy sobre rosa, amarillo o azul. Blanco solo sobre oscuro. Nunca rosa pequeño sobre crema.
- Knuckle Down en mayúsculas para títulos, con su único peso y sin negrita ni cursiva sintéticas (`fonts/KnuckleDown.otf`). Jost para lectura, JetBrains Mono para metadatos.
- Radio 0 en contenedores y botones. Sin sombras difusas ni degradados: la profundidad es una placa plana desplazada. Líneas de 1px.
- Índices mono `00` a `12` por sección. Códigos de color por mundo: Marca amarillo, Producción azul, Web rosa.
- Firmas de marca: el ojo vivo, el isotipo (`assets/rakun-isotipo.svg`), el badge, la onda (`assets/pattern-wave.svg`), los estallidos.

**La adaptación a móvil es real:**
- Sin cursor, Lenis ni animación de scroll. El riel de 64px se convierte en una franja compacta con el índice mono.
- La navegación no cabe en 13 entradas: propón barra inferior de máximo 5 destinos (por ejemplo Pendientes, Solicitudes, Agenda, Proyectos, Más), que **cambie según los permisos** de cada persona.
- Áreas táctiles de mínimo 48dp, acciones principales al alcance del pulgar, gestos con alternativa visible. Arrastrar para reasignar se convierte en una hoja de "Reasignar".
- La marca grita en los bordes y se calla en el trabajo: el ojo y la tipografía gigante van en splash, encabezados y estados vacíos. Las listas y formularios son sobrios y rápidos.
- La intro de la web es de un uso por sesión; aquí la entrada dura menos de 1,5 segundos y respeta "reducir movimiento".
- Jost 300 se ve débil en pantallas pequeñas: valida el peso y el tracking para legibilidad y contraste WCAG AA.
- Teclados correctos por campo, zonas seguras, pantalla pequeña, texto grande del sistema.

**Entregables:**
1. `design/DESIGN_MOVIL.md`: tokens, escala tipográfica móvil, grilla, componentes, movimiento y justificación de cada adaptación.
2. Mapa de navegación y flujos con `/impeccable shape` antes de dibujar.
3. Prototipo navegable `design/index.html` con galería de todas las pantallas. Mínimo: splash, login, recuperar contraseña, Pendientes, Solicitudes (lista y ficha), Clientes, Proyecto, Parrilla (calendario y aprobación), Agenda, Documentos, Cotización y pago, Métricas, menú Más, Mensajes, y las versiones de la navegación para Admin, Manager y Editor.
4. Estados de cada pantalla clave: cargando, vacío, error, sin conexión, sin permiso, y "llegó algo nuevo en vivo".
5. Capturas en `design/capturas/`.
6. Revisión con `/impeccable critique`, `/impeccable audit` y `npx impeccable detect design/`. Corrige lo que salga y déjame el resultado. Si un subcomando cambió en esta versión, consulta su ayuda.
7. Dos direcciones visuales de la pantalla Solicitudes si hay una decisión real que tomar; si no, una sola bien defendida.
8. `design/APROBACION.md`: lista pantalla por pantalla para que yo marque.

Sube todo en la rama `fase-3/diseno`.

`ALTO`: dime cómo abrir el prototipo. Itera con mis comentarios hasta que escriba `DISEÑO APROBADO`. Entonces etiqueta `v0.1-diseno-aprobado` y continúa. El diseño aprobado manda: si durante el montaje necesitas cambiarlo, me lo consultas.

### FASE 4 · Base de la app

- Flutter estable. Plataformas: Android (iOS configurado si aplica).
- `supabase_flutter`, Riverpod para estado, `go_router` para navegación. Justifica cualquier otro paquete; que sean mantenidos y pocos.
- Estructura:

      lib/
      ├── core/           (config, supabase, errores, permisos, utilidades)
      ├── design_system/  (tokens, tema, componentes, ojo)
      ├── features/<seccion>/{data,domain,presentation}
      └── app.dart

- Configuración con `--dart-define-from-file=env.json` (ignorado por Git) y un `env.example.json` en el repositorio.
- Fuentes como archivos locales. El ojo se porta a Flutter con la misma física de resortes de `eye.js` y respeta "reducir movimiento".
- Autenticación con sesión persistente. Si `profiles.role` es `cliente`, la app le niega el acceso con un mensaje claro.
- `permisos.dart` replica exactamente `can` y `seesMoney`, con pruebas de cada rol.
- Galería interna de componentes para comparar contra el prototipo aprobado.
- Corre en dispositivo real o emulador, y entrégame capturas lado a lado con el diseño.

### FASE 5 · Sincronización en vivo

1. Verifica que RLS esté activo en cada tabla a publicar.
2. Prepara en una rama de `rakun-web` el archivo `supabase/fase18.sql`, siguiendo el formato existente y con una sección nueva en `LEEME.md`. Debe poder correrse varias veces:

       do $$
       declare t text;
       begin
         foreach t in array array[
           'leads','clients','projects','posts','shoots','meetings','documents',
           'quotes','quote_payments','deliverables','team_messages','message_reads',
           'followups','commissions','works','plan_catalog','profiles'
         ] loop
           if not exists (
             select 1 from pg_publication_tables
             where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
           ) then
             execute format('alter publication supabase_realtime add table public.%I', t);
           end if;
         end loop;
       end $$;

   No publiques `meta_tokens`, `page_events` ni `app_settings`.

   `ALTO`: muéstrame el SQL y explícame qué hace. Lo corro yo en el SQL Editor, o tú si te lo autorizo.

3. **En la app:** al llegar un evento, no confíes en su contenido: invalida y vuelve a consultar, para que RLS y los permisos de dinero sigan mandando. Reconexión automática y recarga al volver a primer plano.
4. **Sin conexión:** caché de lectura y aviso claro. En v1 no hay escrituras en cola, para evitar conflictos con dinero.
5. **En la web:** para que los cambios de la app aparezcan sin recargar, propón en una rama de `rakun-web` un módulo pequeño `app/realtime.js` conectado a `admin.js`, que refresque la vista y los contadores, **sin interrumpir un formulario o panel abierto**. `ALTO` antes de fusionar, porque eso publica la página.
6. Notificaciones push (nueva solicitud, tarea asignada): van en una fase posterior, porque requieren Firebase. Déjalo documentado y consúltame.

**Prueba obligatoria, medida y registrada en el README:**
- Solicitud `PRUEBA APP` enviada por el formulario web → aparece en la app sin recargar (objetivo: menos de 3 segundos).
- Cambio de estado en la app → se ve en el gestor web.
- Cambio en la web → se ve en la app.
- Una cuenta sin permiso **no** recibe ni ve lo que no le corresponde.
- Limpieza de los datos de prueba.

### FASE 6 · Montaje por secciones

Sigue la prioridad aprobada (P1, P2, P3). Para cada sección, en su propia rama:

1. Capa de datos con las mismas tablas, RPC y filtros que la web.
2. Pantallas fieles al diseño aprobado, con todos sus estados.
3. Permisos de ver, editar y dinero.
4. Sincronización en vivo probada.
5. Pruebas, README, commit y push.
6. Actualización de la matriz de paridad.

Puntos específicos:
- **Dinero:** porta `quote-calc`, `comisiones`, `pagos` y `metas` a Dart con **pruebas de paridad**: los mismos casos ejecutados en Node con el JS original y en Dart deben dar resultados idénticos, incluidos redondeos. Si detectas un error en la lógica original, no lo corrijas por tu cuenta: repórtamelo.
- **Archivos:** enlaces firmados de 5 minutos como en la web; subida con los mismos buckets y rutas; cámara y galería; WebP y PDF a imágenes con paquetes nativos que den el mismo resultado.
- **Invitaciones:** usa la Edge Function `invitar` igual que `admin.js`, con la URL pública de `cuenta.html`.
- **Acciones destructivas:** misma confirmación fuerte que la web, incluida la de escribir el nombre del cliente.
- **Al terminar P1**, genera un APK de prueba para que lo use en mi teléfono. `ALTO` para recoger mis comentarios antes de seguir con P2.

### FASE 7 · Calidad

- `flutter analyze` sin errores; pruebas unitarias, de widgets y de integración de los flujos principales.
- Prueba con cuentas de cada rol. Dime qué cuentas de prueba necesitas; las contraseñas no pasan por el chat.
- Revisión con Impeccable (`critique`, `audit`, `polish`) sobre capturas reales de la app. El detector automático es para HTML/CSS, así que en Flutter la revisión es visual y con la lista de `DESIGN_MOVIL.md`.
- Accesibilidad: lector de pantalla, contraste, texto ampliado, reducir movimiento.
- Rendimiento en un Android de gama media: listas largas, imágenes, memoria.
- Comparación final pantalla por pantalla contra el prototipo aprobado.
- Una revisión independiente con un subagente que no haya escrito el código, enfocada en seguridad, permisos y dinero.

### FASE 8 · Entrega

- Ícono y splash nativos con el isotipo oficial.
- Keystore de firma guardado fuera de Git; explícame cómo respaldarlo, porque si se pierde no se puede actualizar la app.
- APK o App Bundle de release firmado, nombrado con la versión.
- Guía de instalación para el equipo en el README.
- Como es una herramienta interna, propón la vía de distribución: APK directo o prueba interna de Google Play, con pros y contras.
- Etiqueta `v1.0-gestor`, README final y lista honesta de pendientes.

`ALTO`: entrega final para mi aprobación.

## 8. Empieza ahora

Inicia la **FASE 0**. Antes de ejecutar, dime en tres líneas qué vas a revisar. No te saltes ningún `ALTO`.
