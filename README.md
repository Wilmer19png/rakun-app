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

Instalación desde cero: *se completará en la Fase 4, cuando exista el código de la app.*

## 4. Cómo correr la app (sin Android Studio)

*Se completará en la Fase 4.* Ya está comprobado que el emulador funciona:

```powershell
# arrancar el emulador (celular virtual)
& "$env:LOCALAPPDATA\Android\sdk\emulator\emulator.exe" -avd Pixel_10
# ver que está conectado
adb devices      # debe mostrar: emulator-5554   device
```

## 5. Estructura de carpetas

```
rakun-app/
├── CLAUDE.md         memoria de trabajo para las sesiones de Claude Code (estado y reglas)
├── PRODUCT.md        qué es el producto, para quién y con qué reglas
├── DESIGN.md         identidad visual heredada de la web (base; el diseño móvil se aprueba en la Fase 3)
├── README.md         este documento
├── docs/             encargo completo y documentos de análisis (auditoría del gestor, Fase 2)
├── design/           prototipo en HTML/CSS de las pantallas (Fase 3)
├── herramientas/     scripts de apoyo (preparar Windows)
├── .impeccable/      configuración de la herramienta de diseño Impeccable (design.json copiado de la web)
└── .claude/          skills del proyecto: impeccable y frontend-design
```

## 6. Variables y configuración

*Se completará en la Fase 4.* La app leerá su configuración de un archivo `env.json` que **no se sube a Git**;
en el repositorio solo habrá un `env.example.json` sin valores secretos.
La llave de Supabase que usa la app es la **publicable** (la misma de la web). La llave `service_role` nunca va en la app.

## 7. Generar el APK e instalarlo

*Se completará en la Fase 6 (APK de prueba) y la Fase 8 (versión firmada).*

## 8. Solución de problemas

| Problema | Causa | Solución |
|---|---|---|
| La app de prueba no compilaba en Android | Faltaba el **NDK** (kit nativo de Android) que pide la plantilla de Flutter | Instalar `ndk;28.2.13676358` con `sdkmanager` |
| `sdkmanager.bat "ndk;28.2..."` falla desde PowerShell | PowerShell parte el texto en el `;` | Escribir el paquete en un archivo y usar `sdkmanager --package_file=archivo.txt` |
| El emulador no arrancaba con aceleración | Virtualización apagada en la BIOS (`VirtualizationFirmwareEnabled = False`) | Activar *SVM Mode* en la BIOS y correr `herramientas/preparar_windows.ps1` como administrador; reiniciar |
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

## 10. Estado actual y próximos pasos

- ✅ Fase 0 · ambiente listo y comprobado.
- ✅ Fase 1 · repositorio y organización.
- ✅ Fase 2 · auditoría (`docs/AUDITORIA_GESTOR.md`). Wilmer aprobó el alcance, la prioridad P1/P2/P3 y las funciones "solo web".
- ⏭️ Fase 3 · diseño en HTML/CSS (rama `fase-3/diseno`).
