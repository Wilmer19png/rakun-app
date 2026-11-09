# RAKÜN Studio

**App móvil de RAKÜN Visual Design.**
Dirección y producción: **Wilmer Alejandro Buriticá**.

> Nombre interno del proyecto: *RAKÜN Gestor*. Nombre visible en el celular: **RAKÜN Studio**.
> Identificador de la app en Android: `com.rakundesigns.app` (no se puede cambiar después de publicar).

---

## 1. Qué es

RAKÜN Studio es la versión para celular del **gestor interno** de la página web de RAKÜN
(la sección `admin.html` del repositorio `rakun-web`). Sirve para manejar el estudio desde el teléfono:
solicitudes, clientes, proyectos, parrillas, grabaciones, reuniones, documentos, cotizaciones y pagos,
equipo y métricas. Cada persona ve solo lo que sus permisos le dejan ver.

Más adelante, esta misma app tendrá también el **portal de clientes**. Por ahora es solo para el equipo.

## 2. Cómo se relaciona con la página web

La web y la app son **dos programas distintos que leen y escriben en la misma base de datos** (Supabase).
Por eso lo que entra por la web aparece en la app, y lo que cambia en la app aparece en la web.

```
   ┌──────────────────────┐            ┌──────────────────────┐
   │  rakun-web (página)  │            │  rakun-app (celular) │
   │  Netlify · admin.html│            │  Flutter · Android   │
   └──────────┬───────────┘            └───────────┬──────────┘
              │      misma llave publicable        │
              └──────────────┐      ┌──────────────┘
                             ▼      ▼
                  ┌────────────────────────────┐
                  │  Supabase (producción)     │
                  │  · Auth (cuentas)          │
                  │  · Base de datos + RLS     │
                  │  · Archivos (Storage)      │
                  │  · Funciones (Edge)        │
                  └────────────────────────────┘
```

- **RLS** (Row Level Security): reglas dentro de la base de datos que deciden qué filas puede ver cada cuenta.
  Protegen los datos aunque alguien intente saltarse la app.
- Los cambios a la estructura de la base de datos (migraciones) viven **solo** en `rakun-web/supabase/`.
  Este repositorio no los copia.

## 3. Requisitos (equipo de desarrollo)

Comprobados el 2026-11-08 en Windows 11 Pro:

| Herramienta | Versión probada | Para qué sirve |
|---|---|---|
| Git | 2.55 | Guardar el historial de cambios |
| GitHub CLI (`gh`) | 2.102 | Crear y subir el repositorio desde la terminal |
| Flutter (canal stable) | 3.47.9 (Dart 3.13) | El kit con el que se construye la app |
| JDK | 25 (el que trae Android Studio) | Java, necesario para compilar en Android |
| Android SDK | platform-tools 37, android-36/37, build-tools 36, cmdline-tools 23, NDK 28.2.13676358 | Las piezas de Android para compilar e instalar |
| Node / npm | 24.22 / 11.19 | Herramientas de diseño (Impeccable) |
| VS Code + extensiones Dart y Flutter | 1.145 | Editor (opcional) |

En Windows además hace falta:
- **Modo desarrollador** activado (lo piden los complementos de Flutter).
- **Virtualización** activada en la BIOS (en este equipo AMD: *SVM Mode*) y la *Plataforma del hipervisor* de Windows, para que el emulador sea rápido.
  El script `herramientas/preparar_windows.ps1` activa ambas cosas de Windows (se corre como administrador y luego se reinicia).

**Instalación desde cero** (con lo de arriba ya instalado):

```powershell
git clone https://github.com/Wilmer19png/rakun-app.git C:\Users\<tu-usuario>\rakun-app
cd C:\Users\<tu-usuario>\rakun-app
copy env.example.json env.json      # luego pon los valores reales (ver sección 6)
flutter pub get                     # descarga los paquetes (versiones fijas en pubspec.lock)
flutter test                        # deben pasar todas las pruebas
```

## 4. Cómo correr la app (sin Android Studio)

**En el emulador** (celular virtual):

```powershell
& "$env:LOCALAPPDATA\Android\sdk\emulator\emulator.exe" -avd Pixel_10   # 1) encenderlo
adb devices                                                              # 2) debe decir: emulator-5554   device
flutter run --dart-define-from-file=env.json                            # 3) compila, instala y abre la app
```

**En tu celular:** activa *Opciones de desarrollador → Depuración USB*, conéctalo por cable, acepta el aviso en
el teléfono y usa el mismo `flutter run --dart-define-from-file=env.json` (`flutter devices` lo debe listar).

- Siempre con `--dart-define-from-file=env.json`: sin eso la app muestra "Falta en env.json…".
- La versión de prueba (*debug*) tarda unos 9 s en abrir en el emulador; la final abre en 1–2 s.
- Galería de componentes para comparar con el diseño: entrar como admin → **Más → Galería de componentes**.

## 5. Estructura de carpetas

```
rakun-app/
├── CLAUDE.md         memoria de trabajo para las sesiones de Claude Code (estado y reglas)
├── PRODUCT.md        qué es el producto, para quién y con qué reglas
├── DESIGN.md         identidad visual heredada de la web (base; el diseño móvil se aprueba en la Fase 3)
├── README.md         este documento
├── pubspec.yaml      paquetes de la app (cada uno con su motivo) · pubspec.lock = versiones exactas
├── env.example.json  modelo de la configuración (env.json real: solo en tu equipo, no va a Git)
├── lib/              el código de la app
│   ├── main.dart     arranque: lee env.json, conecta Supabase, abre la app
│   ├── app.dart      tema (oscuro/claro), idioma español y navegación
│   ├── core/         config, conexión y sesión, permisos (copia de perms.js), errores en español, navegación
│   ├── design_system/ colores, letras, tema Material, componentes, el ojo (puerto de eye.js)
│   └── features/     una carpeta por sección (entrada, hoy, más, galería…; en la Fase 6, el resto)
├── assets/           fuentes (Knuckle Down, Jost, JetBrains Mono + licencias) e isotipo/onda
├── android/          proyecto Android (nombre "RAKÜN Studio", id com.rakundesigns.app)
├── test/             pruebas: permisos con paridad contra la web, rutas y capturas visuales
├── tool/             utilidades (svg_sin_estilos.mjs)
├── docs/             encargo completo y documentos de análisis (auditoría del gestor, Fase 2)
├── design/           prototipo en HTML/CSS aprobado (Fase 3) y capturas de comparación
├── herramientas/     scripts de apoyo (preparar Windows)
├── .impeccable/      configuración de la herramienta de diseño Impeccable (design.json copiado de la web)
└── .claude/          skills del proyecto: impeccable y frontend-design
```

## 6. Variables y configuración

La app lee su configuración de **`env.json`**, que **no se sube a Git**. El modelo es `env.example.json`:

| Clave | Qué es | De dónde sale |
|---|---|---|
| `SUPABASE_URL` | Dirección del proyecto Supabase | Supabase → Project Settings → API (o `rakun-web/app/config.js`) |
| `SUPABASE_PUBLISHABLE_KEY` | Llave **publicable** (`sb_publishable_…`), la misma de la web | Igual que arriba |
| `CUENTA_URL` | Página de la web donde terminan invitaciones y "olvidé mi contraseña" | `https://rakundesigns.netlify.app/cuenta.html` |
| `WEB_URL` | Página pública (portal del cliente, gestor web) | `https://rakundesigns.netlify.app` |

La llave `service_role`/secreta **nunca** va en la app: si alguien la pone, la app se niega a arrancar.

## 7. Generar el APK e instalarlo

*Se completará en la Fase 6 (APK de prueba) y la Fase 8 (versión firmada).*

## 8. Solución de problemas

| Problema | Causa | Solución |
|---|---|---|
| La app de prueba no compilaba en Android | Faltaba el **NDK** (kit nativo de Android) que pide la plantilla de Flutter | Instalar `ndk;28.2.13676358` con `sdkmanager` |
| `sdkmanager.bat "ndk;28.2..."` falla desde PowerShell | PowerShell parte el texto en el `;` | Escribir el paquete en un archivo y usar `sdkmanager --package_file=archivo.txt` |
| El emulador no arrancaba con aceleración | Virtualización apagada en la BIOS (`VirtualizationFirmwareEnabled = False`) | Activar *SVM Mode* en la BIOS y correr `herramientas/preparar_windows.ps1` como administrador; reiniciar |
| El prototipo muestra errores al abrir `design/index.html` con doble clic | Chrome bloquea los scripts de una página abierta como archivo (`file://`) | Abrirlo con `design/ABRIR-PROTOTIPO.cmd` (servidor local en http://localhost:5173) |
| La primera compilación de la app instaló **CMake 3.22.1** sola | Uno de los paquetes lo necesita; Gradle lo descarga | Nada que hacer: tarda ~3 min la primera vez, luego ~20 s |
| El isotipo salía **negro** en la app | El SVG oficial pone los colores en `<style>` y `flutter_svg` no lo aplica | Copia para la app con los colores en cada forma: `node tool/svg_sin_estilos.mjs entrada.svg assets/brand/rakun-isotipo.svg` |
| Blanco con logo de Flutter al abrir | Pantalla nativa de la plantilla | Fondo noche en `android/app/src/main/res` (el ícono propio llega en la Fase 8) |
| `adb shell screencap -p /sdcard/c.png` falla en Git Bash | Git Bash convierte `/sdcard/...` en una ruta de Windows | Anteponer `MSYS_NO_PATHCONV=1` o usar PowerShell |
| Las capturas automáticas (golden) cambiaban en cada corrida | El ojo mira al azar | Se toman con "reducir movimiento" activado: el ojo queda quieto |
| La captura de pantalla del emulador salía dañada | En PowerShell, `adb exec-out screencap -p > archivo.png` altera los bytes | `adb shell screencap -p /sdcard/c.png` y luego `adb pull /sdcard/c.png` |

## 9. Bitácora

### 2026-11-08 · Fase 0: ambiente de desarrollo
- **Qué se hizo:** revisión completa del equipo; Flutter actualizado de 3.47.5 a 3.47.9; NDK instalado;
  modo desarrollador e hipervisor activados con `herramientas/preparar_windows.ps1`; SVM activado en la BIOS.
- **Por qué:** sin estas piezas no se puede compilar ni probar la app en un emulador rápido.
- **Comandos:** `flutter upgrade`, `flutter doctor -v`, `sdkmanager --package_file=...`, `emulator -accel-check`, `adb devices`.
- **Resultado:** `flutter doctor` sin problemas; aceleración WHPX lista; el emulador `Pixel_10` (Android 16) arranca en ~30 s.
  Una app de prueba temporal compiló en ~1 min, se instaló y abrió en el emulador; luego se desinstaló y se borró.
  Supabase responde (auth 200, `plan_catalog` 200, `leads` sin sesión devuelve vacío: RLS funciona).
- **Cómo comprobarlo:** `emulator -accel-check` debe decir *WHPX ... is installed and usable*; `adb devices` debe listar el emulador.
- **Hallazgo reportado (sin cambiar nada):** Netlify publica la raíz de `rakun-web`, así que se pueden leer en internet
  `DESIGN.md`, `PRODUCT.md`, `supabase/LEEME.md`, `supabase/*.sql` y `app/config.js`.

### 2026-11-08 · Fase 1: repositorio y organización
- **Qué se hizo:** decidido el identificador `com.rakundesigns.app` y el nombre visible **RAKÜN Studio**
  (neutros, para que la app sirva también al portal de clientes más adelante). Se inició Git, se crearon
  `README.md`, `.gitignore`, `docs/`, `design/`, `PRODUCT.md` y `DESIGN.md`; se instalaron las skills
  Impeccable 4.8.1 (`npx impeccable install --providers=claude --scope=project`) y frontend-design
  (desde `github.com/anthropics/skills`, commit `41bbe19`). Repositorio privado `Wilmer19png/rakun-app`.
- **Por qué:** dejar el proyecto ordenado, versionado y con el contexto de producto y marca antes de auditar y diseñar.
- **Resultado y comprobación:** ver la sección *Estado actual*.

### 2026-11-08 · Fase 2: auditoría funcional del gestor web
- **Qué se hizo:** lectura completa del gestor de `rakun-web` (commit `cd85fe1`): `admin.html`, los `app/admin*.js`,
  permisos, lógica de dinero, `planes/`, los 17 SQL y las 3 Edge Functions. Resultado en `docs/AUDITORIA_GESTOR.md`.
- **Por qué:** antes de diseñar hay que saber todo lo que hace la web, para que nada se pierda en silencio.
- **Comandos:** solo lectura (`cat`, `grep`); dos comprobaciones ejecutando con Node el código original de la web,
  sin modificarlo (cálculo de comisiones y fechas en hora universal).
- **Resultado:** matriz de paridad con 107 funciones y su decisión; mapa de permisos por rol; inventario de la lógica
  a portar; 10 hallazgos para revisar en la web (ninguno corregido); prioridad P1/P2/P3 propuesta.
- **Cómo comprobarlo:** abrir `docs/AUDITORIA_GESTOR.md`.

### 2026-11-08/09 · Fase 3: diseño (prototipo navegable)
- **Qué se hizo:** mapa de navegación y flujos (`design/MAPA_NAVEGACION.md`), sistema móvil (`design/DESIGN_MOVIL.md`),
  prototipo HTML/CSS con 21 pantallas, sus estados y la barra inferior de 5 roles (`design/index.html`), 43 capturas en
  dos tamaños (`design/capturas/`), revisión con el detector y la crítica de Impeccable (`design/REVISION.md`) y la lista
  para aprobar (`design/APROBACION.md`).
- **Por qué:** el encargo exige aprobar el diseño antes de tocar Flutter.
- **Comandos:** doble clic en `design/ABRIR-PROTOTIPO.cmd` o `node design/servir.mjs` (abrir; NO con doble clic en index.html), `cd design/tools && npm install && npm run capturas` (capturas),
  `npx impeccable detect …` (revisión automática).
- **Resultado:** ver `design/REVISION.md`. Cambios pedidos: tema claro a elección y Solicitudes en dirección A.
  **DISEÑO APROBADO** por Wilmer el 2026-11-09 → etiqueta `v0.1-diseno-aprobado`; `DESIGN_MOVIL.md` pasó a `DESIGN.md`.
- **Cómo comprobarlo:** abrir http://localhost:5173 con el servidor encendido.

### 2026-11-09 · Fase 4: base de la app
- **Qué se hizo:** proyecto Flutter (`com.rakundesigns.app`, "RAKÜN Studio"); paquetes con la versión estable
  consultada en pub.dev ese día (supabase_flutter 2.18.3, flutter_riverpod 3.5.0, go_router 18.1.3,
  material_symbols_icons 4.2960.0, shared_preferences 2.5.6, flutter_svg 2.3.2, url_launcher 6.3.3);
  sistema de diseño aprobado en Flutter (dos temas, fuentes locales, radio 0, componentes, el ojo con la física de `eye.js`);
  sesión que se mantiene, cuenta de cliente → acceso negado, barra inferior por permisos, Más con Apariencia,
  cambiar contraseña y salir; galería de componentes.
- **Por qué:** dejar lista la base sobre la que se montan las secciones (Fase 6) y la sincronización (Fase 5).
- **Comandos:** `flutter create`, `flutter pub add`, `flutter analyze`, `flutter test`, `flutter build apk --debug --dart-define-from-file=env.json`.
- **Resultado:** `flutter analyze` sin problemas; **54 pruebas** pasan (permisos idénticos a `perms.js` en 14 perfiles × 13
  secciones, rutas, barra por rol y 19 capturas visuales). La app compila, abre en el emulador y muestra el login.
  Comparación lado a lado con el prototipo en `design/capturas/comparacion/`.
- **Prueba con cuenta real:** Wilmer entró con su cuenta en el emulador y vio todo (saludo, barra, Más). Etiqueta `v0.2-base`.
- **Cómo comprobarlo:** `flutter test` y `flutter run --dart-define-from-file=env.json`.

### 2026-11-09 · Fase 5: sincronización en vivo
- **Qué se hizo:**
  - `rakun-web/supabase/fase18.sql` (rama local `fase-18/tiempo-real` de la web): publica en Supabase Realtime las 17 tablas
    del gestor, solo si cada una tiene RLS. **Wilmer lo corrió en producción: 17 tablas publicadas.** No publica
    `meta_tokens`, `page_events` ni `app_settings`.
  - App (`lib/core/sync/`): un canal escucha las 17 tablas; de cada aviso solo usa **qué tabla cambió** y la vuelve a
    consultar (mandan RLS y el permiso de dinero). Agrupa ráfagas, se reconecta sola (espera creciente), recarga al volver
    a la app, franja "Sin conexión" tras 4 s y caché de lectura por persona (se borra al salir). Diagnóstico en
    Más → En vivo (solo admin).
  - Web (`rakun-web/app/realtime.js`, misma rama local): el gestor también se actualiza solo, **sin interrumpir** fichas,
    ventanas, campos en uso ni editores (muestra "Hay cambios · Actualizar").
- **Prueba medida** (2026-11-09, emulador Pixel_10, cuenta real de Wilmer). Solicitud `PRUEBA APP` creada igual que el
  formulario público (misma llave y regla; sin el píxel de Meta para no ensuciar campañas). Reloj del emulador
  corregido (iba 1,563 s ± 0,025 s atrasado):

  | Prueba | Creada | Llegó a la app | Demora |
  |---|---|---|---|
  | 1 | 16:36:32.130 | ≈16:36:32.6–33.1 (sin milisegundos) | < 1 s |
  | 2 | 16:38:46.812 | 16:38:47.542 | **0,73 s** |
  | 3 | 16:38:56.174 | 16:38:56.711 | **0,54 s** |

  Objetivo < 3 s: **cumplido**. Un cliente **sin sesión** escuchando `leads` recibió **0 avisos** en las 3 pruebas (RLS
  funciona en vivo). Corte de red: a los 4 s sale "Sin conexión" y al volver se reconecta solo a "En vivo".
- **Con Wilmer (2026-11-09):** probó el gestor web local (cambios entre pestañas y en la app). Las 3 solicitudes `PRUEBA APP`
  se borran con un SQL exacto (solo esas 3 filas) que corre Wilmer: la app no tiene permiso de borrar.
- **Web sin publicar:** por decisión de Wilmer la rama `fase-18/tiempo-real` de rakun-web queda local (no Netlify) hasta que él diga.
  "Cambio en la app → se ve en la web" se prueba cuando exista la primera sección que escribe (Fase 6).

### 2026-11-09 · Fase 6 · 01 Solicitudes
- **Qué se hizo:** lista por estado (dirección A) con contador, filtro por mundo, buscador, llamar a un toque, píldora
  "N nuevas" en vivo; ficha con Llamar · WhatsApp (mismo mensaje de la web) · Correo, plan elegido, anuncio, estado y
  responsable en hojas, notas que se guardan solas, "Hacer cliente" + acceso al portal (Edge Function `invitar`, enlace por
  `cuenta.html`), eliminar (solo admin). Sin conexión: se ve lo guardado y no se escribe. "Cotizar" llega con P2.
- **Paridad:** `util.js` (waNumber, safeUrl, initials) probado contra el original; encontró que el navegador normaliza los
  enlaces (barra final, dominios inválidos) y se igualó.
- **Probado:** 72 pruebas; capturas con datos de ejemplo en los dos temas (`design/capturas/comparacion/solicitud*`);
  en el emulador con datos reales: lista y ficha, y **cambio de estado de una solicitud PRUEBA APP desde la app** (pasó a Reunión).
  No se probó crear accesos reales (regla: nada de invitaciones reales de prueba).

### 2026-11-09 · Fase 6 · 02 Clientes
- **Qué se hizo:** lista con buscador y filtro Todos / Con acceso / Sin acceso, mundos de cada cliente (sacados de sus
  proyectos), llamar a un toque, "Crear acceso" en la fila; ficha en hoja con Llamar · WhatsApp · Correo, datos y
  "Crear acceso / Nuevo enlace"; "+" → Nuevo cliente (nombre, marca, correo, WhatsApp, departamento → ciudad con buscador)
  que al guardar abre el acceso, igual que la web. El enlace de acceso ahora también se comparte con la hoja de Android
  (`share_plus` 13.3.1). Eliminar cliente queda en la web (P3).
- **Paridad:** la lista de 33 departamentos / 1104 municipios se **genera** desde `colombia.js` de la web
  (`node tool/generar_colombia.mjs`); `parse` de `ubicacion.js` probado contra el original (`test/paridad/ubicacion.json`).
- **Ajustes de diseño:** botones Llamar · WhatsApp · Correo pasan a un componente común (`RkAcciones`, ícono arriba:
  no parte palabras en 360 dp); las hojas inferiores tapan la barra de abajo; Más dice "Abrir" en lo que ya funciona.
- **Probado:** 87 pruebas; capturas de ejemplo `52-clientes`, `53-nuevo-cliente`, `54-cliente` (dos temas); en el emulador
  con datos reales: lista (2 clientes, mundos correctos) y **crear un cliente PRUEBA APP desde la app** (se guardó como
  "Manizales, Caldas" y abrió el acceso; no se creó el acceso). No se probó en el teléfono el aviso de correo repetido.

### 2026-11-09 · Fase 6 · 03 Proyectos (rama fase-6/proyectos, sin fusionar)
- **Qué se hizo:** lista con filtro Activos / Redes / Producción / Web / Míos / Terminados, buscador, etapa y "N vencidos";
  ficha con etapa (la ve el cliente), estado y a cargo en hojas, fechas y enlace a su cotización; entregables como
  tarjetas que se editan en una hoja (nombre, tipo, fecha límite, lo hace, lo revisa, estado, brief, ver entrega, quitar);
  "+" nuevo entregable; cargar la plantilla del mundo; "+" nuevo proyecto (cliente, tipo, nombre, plan, fechas, a cargo).
  «Dinero del proyecto» y la pestaña Cotizaciones llegan con P2. Parrilla del proyecto llega con 04 Parrillas.
- **Paridad:** etapas, plantillas, tipos y estados se **generan** desde content.js y quote-sources.js
  (`node tool/generar_proyectos.mjs`); fechas límite a las 6 p. m. como la web; plazos (vencido/hoy/semana) como `bucket`.
- **Común:** `RkOpcion`, `elegirEnHoja` (con buscador), `RkCampoElegible`, `RkAvatar`; Solicitudes y Clientes los usan.
- **Probado:** 98 pruebas; capturas `60-proyectos`, `61-proyecto`, `62-entregable` (dos temas, reloj fijo).
  **Falta** la prueba en el emulador con datos reales (se detuvo por poca memoria del computador).

## 10. Estado actual y próximos pasos

- ✅ Fase 0 · ambiente listo y comprobado.
- ✅ Fase 1 · repositorio y organización.
- ✅ Fase 2 · auditoría (`docs/AUDITORIA_GESTOR.md`). Wilmer aprobó el alcance, la prioridad P1/P2/P3 y las funciones "solo web".
- ✅ Fase 3 · diseño **aprobado** el 2026-11-09 (etiqueta `v0.1-diseno-aprobado`). Sistema oficial en `DESIGN.md`.
- ✅ Fase 4 · base de la app (etiqueta `v0.2-base`), probada con la cuenta real de Wilmer.
- ✅ Fase 5 · en vivo (etiqueta `v0.3-sync`, medido < 1 s). La parte web queda en rama local de rakun-web, sin publicar.
- ⏭️ Fase 6 · montaje por secciones (P1): ✅ Solicitudes · ✅ Clientes · 🟡 Proyectos (falta emulador) · siguen Hoy, Agenda, Parrillas, Mensajes.
