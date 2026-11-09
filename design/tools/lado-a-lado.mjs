// Hojas "prototipo aprobado | app Flutter" para comparar (Fase 4).
// Uso: node design/tools/lado-a-lado.mjs  → design/capturas/comparacion/*.png
import { chromium } from 'playwright';
import { readFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const R = fileURLToPath(new URL('../../', import.meta.url));
const PARES = [
  ['entrada', 'oscuro', '01-splash', '01-entrada-oscuro'],
  ['login', 'oscuro', '02-login', '02-login-oscuro'], ['login', 'claro', '02-login', '02-login-claro'],
  ['recuperar', 'oscuro', '03-recuperar', '03-recuperar-oscuro'],
  ['sin-acceso', 'claro', '04-sin-acceso', '04-sin-acceso-claro'],
  ['hoy', 'oscuro', '90-barra-admin', '10-hoy-admin-oscuro'], ['hoy', 'claro', '90-barra-admin', '10-hoy-admin-claro'],
  ['hoy-editor', 'oscuro', '93-barra-editor', '11-hoy-editor-oscuro'],
  ['sin-permiso', 'oscuro', '84-estado-sin-permiso', '21-sin-permiso-oscuro'],
  ['solicitudes', 'oscuro', '20-solicitudes-A', '50-solicitudes-oscuro'], ['solicitudes', 'claro', '20-solicitudes-A', '50-solicitudes-claro'],
  ['solicitud', 'oscuro', '22-solicitud', '51-solicitud-oscuro'], ['solicitud', 'claro', '22-solicitud', '51-solicitud-claro'],
  ['mas', 'oscuro', '61-mas', '30-mas-oscuro'], ['mas', 'claro', '61-mas', '30-mas-claro'],
];
const b64 = async (p) => (await readFile(p)).toString('base64');
await mkdir(`${R}design/capturas/comparacion`, { recursive: true });
const b = await chromium.launch({ channel: 'chrome' });
const page = await b.newPage({ viewport: { width: 2 * 360 + 3 * 16, height: 800 + 48 } });
for (const [n, tema, proto, app] of PARES) {
  const a = await b64(`${R}design/capturas/${tema}/360x800/${proto}.png`);
  const f = await b64(`${R}test/visual/goldens/${app}.png`);
  await page.setContent(`<body style="margin:0;padding:12px 16px;background:#333;color:#fff;font:12px monospace;display:flex;gap:16px">
    <div><div style="height:20px">PROTOTIPO · ${proto} · ${tema}</div><img src="data:image/png;base64,${a}" style="width:360px;height:800px;display:block"></div>
    <div><div style="height:20px">APP FLUTTER · ${app}</div><img src="data:image/png;base64,${f}" style="width:360px;height:800px;display:block"></div></body>`);
  await page.waitForTimeout(150);
  await page.screenshot({ path: `${R}design/capturas/comparacion/${n}-${tema}.png` });
}
await b.close();
console.log(`${PARES.length} comparaciones`);
