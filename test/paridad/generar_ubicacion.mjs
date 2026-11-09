// Genera test/paridad/ubicacion.json con el ubicacion.js ORIGINAL de rakun-web (función `parse`, que no se exporta:
// se copia el archivo tal cual a una carpeta temporal, se le añade `export { parse }` y se importa).
// Uso (desde rakun-app):  node test/paridad/generar_ubicacion.mjs "C:/Users/wburi/PÁGINA WEB RAKÜN"
import { readFileSync, writeFileSync, mkdtempSync, copyFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const web = process.argv[2] || 'C:/Users/wburi/PÁGINA WEB RAKÜN';
const dir = mkdtempSync(join(tmpdir(), 'rk-ubic-'));
copyFileSync(`${web}/app/colombia.js`, join(dir, 'colombia.js'));
writeFileSync(join(dir, 'ubicacion.js'), `${readFileSync(`${web}/app/ubicacion.js`, 'utf8')}\nexport { parse };\n`);
const { parse } = await import(pathToFileURL(join(dir, 'ubicacion.js')).href);

const valores = ['Pereira, Risaralda', 'Manizales, Caldas', 'Bogotá', 'Bogotá D.C.', 'Bogotá, Bogotá D.C.', 'Ecuador', 'Otro país',
  'Medellín', 'medellín, antioquia', 'Pereira,Risaralda', '', null, '  Leticia, Amazonas  ', 'Inventada, Caldas', 'Carmen de Viboral, Antioquia',
  'El Carmen de Viboral, Antioquia', 'Fuera de Colombia'];
const casos = valores.map((v) => [v, parse(v) ?? null]);
writeFileSync(new URL('./ubicacion.json', import.meta.url), `${JSON.stringify({ origen: 'rakun-web/app/ubicacion.js', casos }, null, 2)}\n`);
console.log('ubicacion.json:', casos.length, 'casos');
