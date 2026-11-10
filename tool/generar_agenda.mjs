// Genera lib/core/datos/agenda_web.dart desde app/content.js de la web:
// tipos y estados de reunión (MEET_KIND, MEET_STATUS) y estados de grabación (SHOOT_STATUS).
// Uso: node tool/generar_agenda.mjs
import { writeFileSync, mkdirSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const WEB = 'C:/Users/wburi/PÁGINA WEB RAKÜN/app';
globalThis.document ??= { addEventListener() {}, querySelector() { return null; } };
const { MEET_KIND, MEET_STATUS, SHOOT_STATUS } = await import(pathToFileURL(`${WEB}/content.js`).href);

const s = (v) => `'${String(v).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;
const pares = (o) => Object.entries(o).map(([k, v]) => `  (${s(k)}, ${s(Array.isArray(v) ? v[0] : v)}),`).join('\n');
const out = `// GENERADO por tool/generar_agenda.mjs desde app/content.js de la web. No editar a mano.

/// Tipos de reunión: (clave, nombre). MEET_KIND de la web (en el mismo orden).
const tiposReunionWeb = <(String, String)>[
${pares(MEET_KIND)}
];

/// Estados de reunión: (clave, nombre). MEET_STATUS de la web.
const estadosReunionWeb = <(String, String)>[
${pares(MEET_STATUS)}
];

/// Estados de grabación: (clave, nombre). SHOOT_STATUS de la web.
const estadosGrabacionWeb = <(String, String)>[
${pares(SHOOT_STATUS)}
];
`;
mkdirSync('lib/core/datos', { recursive: true });
writeFileSync('lib/core/datos/agenda_web.dart', out);
console.log(`tipos de reunión ${Object.keys(MEET_KIND).length} · estados de reunión ${Object.keys(MEET_STATUS).length} · estados de grabación ${Object.keys(SHOOT_STATUS).length}`);
