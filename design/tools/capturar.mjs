// RAKÜN Studio · capturas del prototipo a tamaño real (360×800 y 390×844)
// Uso: cd design/tools && npm install && npm run capturas
// Guarda en design/capturas/<tamaño>/<nombre>.png. Usa el Chrome instalado (channel: 'chrome').
import { chromium } from 'playwright';
import { spawn } from 'node:child_process';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const DESIGN = fileURLToPath(new URL('..', import.meta.url));
const PORT = 5191;
const BASE = `http://127.0.0.1:${PORT}/pantallas/`;
const SIZES = [[360, 800], [390, 844]];
const SHOTS = [
  ['01-splash', 'splash.html?auto=0', 1600],
  ['02-login', 'login.html'],
  ['03-recuperar', 'recuperar.html'],
  ['04-sin-acceso', 'sin-acceso.html'],
  ['10-hoy', 'hoy.html'],
  ['11-hoy-entregar', 'hoy.html?hoja=entregar'],
  ['12-tarea', 'tarea.html'],
  ['13-revisar', 'revisar.html'],
  ['14-revisar-devolver', 'revisar.html?hoja=devolver'],
  ['20-solicitudes-A', 'solicitudes-a.html'],
  ['21-solicitudes-B', 'solicitudes-b.html'],
  ['22-solicitud', 'solicitud.html'],
  ['23-solicitud-estado', 'solicitud.html?hoja=estado'],
  ['24-clientes', 'clientes.html'],
  ['25-clientes-nuevo', 'clientes.html?hoja=nuevo'],
  ['26-clientes-acceso', 'clientes.html?hoja=acceso'],
  ['30-proyectos', 'proyectos.html'],
  ['31-proyecto', 'proyecto.html'],
  ['32-proyecto-editar', 'proyecto.html?hoja=editar'],
  ['33-proyecto-etapa', 'proyecto.html?hoja=etapa'],
  ['40-agenda', 'agenda.html'],
  ['41-agenda-confirmar', 'agenda.html?hoja=confirmar'],
  ['42-agenda-programar', 'agenda.html?hoja=nueva'],
  ['43-grabacion', 'grabacion.html'],
  ['50-parrilla', 'parrilla.html'],
  ['51-parrilla-pieza', 'parrilla.html?hoja=pieza'],
  ['60-mensajes', 'mensajes.html'],
  ['61-mas', 'mas.html'],
  ['70-documentos', 'documentos.html'],
  ['71-cotizacion', 'cotizacion.html'],
  ['72-cotizacion-pago', 'cotizacion.html?hoja=pago'],
  ['73-metricas', 'metricas.html'],
  ['80-estado-cargando', 'hoy.html?estado=cargando'],
  ['81-estado-vacio', 'hoy.html?estado=vacio'],
  ['82-estado-error', 'solicitudes-a.html?estado=error'],
  ['83-estado-sin-conexion', 'hoy.html?estado=offline'],
  ['84-estado-sin-permiso', 'solicitudes-a.html?estado=sinpermiso'],
  ['85-estado-en-vivo', 'agenda.html?estado=vivo'],
  ['90-barra-admin', 'hoy.html?rol=admin'],
  ['91-barra-manager', 'hoy.html?rol=manager'],
  ['92-barra-directora', 'hoy.html?rol=directora'],
  ['93-barra-editor', 'hoy.html?rol=editor'],
  ['94-barra-camara', 'hoy.html?rol=camara'],
];

const server = spawn(process.execPath, [`${DESIGN}servir.mjs`], { env: { ...process.env, PORT: String(PORT) }, stdio: 'ignore' });
await new Promise((r) => setTimeout(r, 600));
const browser = await chromium.launch({ channel: 'chrome' });
const only = process.argv[2];
try {
  for (const [w, h] of SIZES) {
    const dir = `${DESIGN}capturas/${w}x${h}`;
    await mkdir(dir, { recursive: true });
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: 1, isMobile: true, hasTouch: true, reducedMotion: 'no-preference' });
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', (e) => errors.push(e.message));
    page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
    for (const [name, url, wait = 700] of SHOTS) {
      if (only && !name.includes(only)) continue;
      await page.goto(BASE + url, { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(wait);
      await page.screenshot({ path: `${dir}/${name}.png` });
    }
    if (errors.length) console.log(`Errores en ${w}x${h}:\n - ${[...new Set(errors)].join('\n - ')}`);
    await ctx.close();
    console.log(`✓ ${w}×${h}`);
  }
} finally {
  await browser.close();
  server.kill();
}
