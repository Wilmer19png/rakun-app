// Genera lib/core/datos/colombia.dart desde los archivos ORIGINALES de la web
// (app/colombia.js y la lista de países de app/ubicacion.js), para que las dos listas sean idénticas.
// Uso: node tool/generar_colombia.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const WEB = 'C:/Users/wburi/PÁGINA WEB RAKÜN/app';
const { COLOMBIA } = await import(pathToFileURL(`${WEB}/colombia.js`).href);
const ubic = readFileSync(`${WEB}/ubicacion.js`, 'utf8');
const m = ubic.match(/const COUNTRIES = (\[[\s\S]*?\]);/);
if (!m) throw new Error('No encontré COUNTRIES en ubicacion.js');
const COUNTRIES = JSON.parse(m[1].replace(/'/g, '"'));
const ABROAD = ubic.match(/const ABROAD = '([^']+)'/)[1];

const s = (v) => `'${v.replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;
const out = `// GENERADO por tool/generar_colombia.mjs desde app/colombia.js y app/ubicacion.js de la web. No editar a mano.
// Departamentos y municipios de Colombia (DIVIPOLA, DANE) y países para "Fuera de Colombia".

const fueraDeColombia = ${s(ABROAD)};

const paises = <String>[${COUNTRIES.map(s).join(', ')}];

const colombia = <String, List<String>>{
${COLOMBIA.map(([d, cs]) => `  ${s(d)}: [${cs.map(s).join(', ')}],`).join('\n')}
};
`;
mkdirSync('lib/core/datos', { recursive: true });
writeFileSync('lib/core/datos/colombia.dart', out);
console.log(`${COLOMBIA.length} departamentos, ${COLOMBIA.reduce((n, [, c]) => n + c.length, 0)} municipios, ${COUNTRIES.length} países`);
