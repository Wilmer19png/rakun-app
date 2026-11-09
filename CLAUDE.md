# RAKÜN Gestor (rakun-app) · memoria de trabajo para Claude Code

Responsable y aprobador único: **Wilmer Alejandro Buriticá** (RAKÜN Visual Design).
Hablar siempre en español claro; explicar cada término técnico en una frase.

El encargo completo está en `docs/PROMPT_RAKUN_APP.md`. **Léelo entero al empezar cada sesión.**
Es la fuente de las fases, reglas y puntos `ALTO`.

## Rutas
- Web (repo `Wilmer19png/rakun-web`, se publica en Netlify): `C:\Users\wburi\PÁGINA WEB RAKÜN`
  (la ruta tiene espacio, Á y Ü; no importa porque la web no se compila. No moverla).
- App (este repo, Flutter): `C:\Users\wburi\rakun-app` (ruta sin espacios ni tildes).
- Supabase de PRODUCCIÓN: `https://ajbydapzrtfagmcpglte.supabase.co` (llave publicable en `rakun-web/app/config.js`).
- Sitio público: https://rakundesigns.netlify.app
- Migraciones: SOLO en `rakun-web/supabase/` (no copiarlas aquí).

## Reglas que no se negocian (resumen; detalle en el prompt, sección 4)
1. Detenerse en cada `ALTO`. El diseño solo se aprueba con el texto exacto `DISEÑO APROBADO`.
2. Producción: nada de DROP/TRUNCATE/borrados masivos/cambios de estructura sin mostrar el SQL y recibir aprobación.
   Migraciones aditivas y re-ejecutables. Datos de prueba con prefijo `PRUEBA APP`, y limpiarlos.
   Nunca `delete_client` sobre reales, ni pagos/comisiones/invitaciones reales de prueba.
3. Secretos: no pedirlos por chat. Nunca subir `.env*`, `env.json`, `key.properties`, keystores ni `service_role`. Revisar antes de cada push.
4. `rakun-web`: nunca push a `main` (publica la página). Todo en rama; Wilmer decide cuándo fusionar.
5. Nada se elimina en silencio: matriz de paridad con decisión por función.
6. No inventar datos en la app real.
7. Comprobar antes de decir que algo funciona.
8. Versiones reales consultadas (pub.dev / flutter), no de memoria.
9. Mantener este archivo con el estado actual.

## Decisiones confirmadas
- Identificador Android: **`com.rakundesigns.app`** (permanente). Nombre visible: **RAKÜN Studio**.
  En Fase 4: `flutter create --org com.rakundesigns --project-name app` o ajustar `applicationId`/`namespace` y la etiqueta.
- El portal de clientes irá en esta MISMA app y con la misma marca (fase posterior). En v1, rol `cliente` → acceso negado.
- Usuario principal: Wilmer (admin). Usos: rodajes, calle entre citas, revisión rápida y también trabajo largo (cotizaciones).
- Skills del proyecto: Impeccable 4.8.1 (+hooks en `.claude/settings.local.json`, ignorado por Git) y frontend-design (commit 41bbe19).
- `PRODUCT.md` (plataforma android) y `DESIGN.md` (base heredada, NO aprobada) en la raíz. `.impeccable/design.json` copiado de la web.
- Al diseñar (Fase 3) cargar `.claude/skills/impeccable/reference/android.md`.
- Hay un repo Git vacío accidental en `C:\Users\wburi\.git` (sin commits ni remoto). No tocar sin permiso de Wilmer.

## Estado actual · 2026-11-08
**FASE 2 CERRADA (2026-11-08)**: Wilmer aprobó alcance y prioridad P1/P2/P3 y las 3 funciones "solo web".
Pendiente sin bloquear: decisión sobre hallazgos H1–H10 (no tocar rakun-web), validar barra inferior por rol en Fase 3,
2 preguntas de negocio antes de P2. **Siguiente: FASE 3 (diseño) en la rama `fase-3/diseno`.**
Hallazgos clave (NO corregidos): H1 autoaprobación de entregables vía API; H2 comprobantes en bucket `entregas` legibles por todo staff;
H4 fechas "hoy" en UTC (comprobado); H6 comisión mal calculada si se quita la grabación a un plan "con grabación" (comprobado con Node).
Al portar dinero: copiar el comportamiento actual (incluidos H4/H6) salvo que Wilmer decida otra cosa.

**FASE 1 COMPLETA.**

**FASE 0 COMPLETA y verificada (2026-11-08, tras reinicio).**
- Modo desarrollador = 1; VirtualizationFirmwareEnabled = True; HypervisorPresent = True.
- `emulator -accel-check`: WHPX instalado y usable. AVD `Pixel_10` (Android 16, x86_64) arranca en ~30 s; `adb devices` → emulator-5554.
- App de prueba temporal: compiló (~1 min), se instaló y corrió en el emulador (captura OK); luego desinstalada y borrada.
- RAM 15,8 GB (5,3 libres con emulador); disco C: 232 GB libres, W: 330 GB libres.
- Nota: para capturas usar `adb shell screencap` + `adb pull` (redirigir `exec-out` en PowerShell corrompe el PNG).

(Lo de abajo es el registro previo al reinicio; los pendientes ya están resueltos.)

Hecho y comprobado:
- Windows 11 Pro → objetivo Android (iOS fuera: requiere Mac).
- `rakun-web` en `main`, al día con origin, último commit `cd85fe1`, sin cambios locales (salvo `PROMPT_RAKUN_APP.md` sin seguimiento).
- Git 2.55 (identidad Wilmer19png), gh 2.102 con acceso `repo`, Node 24.22 / npm 11.19.
- Flutter actualizado 3.47.5 → **3.47.9 stable**, Dart 3.13.x, en `W:\Programas\dev\flutter`. `flutter doctor` sin problemas.
- JDK 25 (el de Android Studio, `W:\Programas\Android Studio Setup\jbr`); Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 de la plantilla lo aceptan.
- Android SDK en `C:\Users\wburi\AppData\Local\Android\sdk`: platform-tools 37, android-36 y 37, build-tools 36, cmdline-tools 23, licencias OK.
- **NDK 28.2.13676358 instalado** (faltaba; con él compiló). Nota: `sdkmanager.bat` desde PowerShell parte `ndk;x` por el `;` → usar `--package_file=archivo.txt`.
- App de prueba temporal compiló `app-debug.apk` (1,3 min) y se borró.
- Supabase responde: auth health 200, `plan_catalog` 200, `leads` anónimo → `[]` (RLS OK).
- Skill Impeccable instalada a nivel usuario. frontend-design NO está (se añade en Fase 1).
- Netlify publica la raíz del repo: son públicos `DESIGN.md`, `PRODUCT.md`, `supabase/LEEME.md`, `supabase/*.sql`, `app/config.js`
  (`/supabase/` como carpeta, `.gitignore`, `_headers`, `.impeccable/` dan 404). Solo reportado, no se cambió.

Pendiente del usuario (se hace en un reinicio):
- [ ] Correr `herramientas\preparar_windows.ps1` como administrador (modo desarrollador + Plataforma del hipervisor). El intento automático fue cancelado en la ventana UAC.
- [ ] En la BIOS: activar **SVM Mode** (AMD Ryzen 5 5600G; hoy `VirtualizationFirmwareEnabled = False`).
- [ ] Opcional: depuración USB en el celular.

Al retomar, verificar:
1. `(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock').AllowDevelopmentWithoutDevLicense` = 1
2. `(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled` = True y `HypervisorPresent` = True
3. `emulator -accel-check` y arrancar el AVD `Pixel_10` (imagen android-36.1 x86_64); `adb devices`.
4. Si todo OK → cerrar Fase 0 con la tabla final y pasar a **FASE 1** (proponer id `com.rakundesign.gestor` y esperar confirmación).

Desde la Fase 1 existen: repo Git (rama `main`), remoto privado `Wilmer19png/rakun-app`, README, .gitignore.
