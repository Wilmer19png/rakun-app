// Genera test/paridad/util.json con el util.js ORIGINAL de rakun-web (waNumber, safeUrl, initials).
// Uso (desde rakun-app):  node test/paridad/generar_util.mjs "C:/Users/wburi/PÁGINA WEB RAKÜN"
import { writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const web = process.argv[2] || 'C:/Users/wburi/PÁGINA WEB RAKÜN';
// util.js registra un listener en `document` al cargarse: se le da uno mínimo y se importa el ORIGINAL completo.
globalThis.document = { addEventListener() {} };
const { waNumber, safeUrl, initials } = await import(pathToFileURL(`${web}/app/util.js`).href);

const telefonos = ['3001234567', '300 123 4567', '+57 300 123 4567', '573001234567', '6012345678', '12345', '', null, '(300) 123-4567', '30012345678'];
const enlaces = ['instagram.com/ana', 'https://tiktok.com/@ana', 'http://web.co', 'javascript:alert(1)', 'ftp://x.com', '  www.ejemplo.com  ', '', 'mailto:a@b.co', 'HTTPS://EJEMPLO.COM/Ruta', 'no es un enlace con espacios'];
const nombres = ['Ana Ejemplo', 'wilmer alejandro buriticá', '  Sofía  ', '', null, 'Dr. Ejemplo Pérez'];

const casos = {
  waNumber: telefonos.map((x) => [x, waNumber(x)]),
  safeUrl: enlaces.map((x) => [x, safeUrl(x)]),
  initials: nombres.map((x) => [x, initials(x)]),
};
writeFileSync(new URL('./util.json', import.meta.url), `${JSON.stringify({ origen: 'rakun-web/app/util.js', casos }, null, 2)}\n`);
console.log('util.json:', Object.entries(casos).map(([k, v]) => `${k} ${v.length}`).join(' · '));
