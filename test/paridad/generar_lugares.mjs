// Fixture de paridad: corre `toPlace` ORIGINAL de rakun-web/app/places.js sobre resultados de
// ejemplo de Photon y guarda lo que da en test/paridad/lugares.json.
// Uso: node test/paridad/generar_lugares.mjs
import { readFileSync, writeFileSync } from 'node:fs';

const src = readFileSync('C:/Users/wburi/PÁGINA WEB RAKÜN/app/places.js', 'utf8');
const m = src.match(/function toPlace\(f\) \{[\s\S]*?\n\}/);
if (!m) throw new Error('No encontré toPlace en places.js');
const toPlace = new Function(`${m[0]}; return toPlace;`)();

const casos = [
  { name: 'Estudio Ejemplo', street: 'Calle 10', housenumber: '23-45', locality: 'El Cable', city: 'Manizales', state: 'Caldas', country: 'Colombia' },
  { name: 'Clínica Ejemplo', city: 'Bogotá', state: 'Bogotá, Distrito Capital', country: 'Colombia' },
  { street: 'Carrera 43A', housenumber: '1-50', district: 'El Poblado', city: 'Medellín', state: 'Antioquia', country: 'Colombia' },
  { name: 'Parque', city: 'Quito', state: 'Pichincha', country: 'Ecuador' },
  { city: 'Pereira', county: 'Pereira', state: 'Risaralda', country: 'Colombia' },
  { name: 'Café', locality: 'Chapinero', county: 'Bogotá', state: 'Bogotá', country: 'Colombia' },
  { name: 'Sitio', state: 'Caldas', country: 'Colombia' },
];
const salida = casos.map((p) => ({ entrada: p, salida: toPlace({ properties: p }) }));
writeFileSync('test/paridad/lugares.json', JSON.stringify(salida, null, 2));
console.log(`${salida.length} casos de toPlace`);
