// Genera lib/core/datos/parrilla_web.dart desde app/content.js de la web:
// redes (NETWORKS), formatos (FORMATS) y estados de pieza (POST_STATUS).
// Uso: node tool/generar_parrilla.mjs
import { writeFileSync, mkdirSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const WEB = 'C:/Users/wburi/PÁGINA WEB RAKÜN/app';
globalThis.document ??= { addEventListener() {}, querySelector() { return null; } };
const { NETWORKS, FORMATS, POST_STATUS } = await import(pathToFileURL(`${WEB}/content.js`).href);

const s = (v) => `'${String(v).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;
const out = `// GENERADO por tool/generar_parrilla.mjs desde app/content.js de la web. No editar a mano.

/// Redes: (clave, nombre). NETWORKS de la web (en el mismo orden).
const redesWeb = <(String, String)>[
${NETWORKS.map(([k, n]) => `  (${s(k)}, ${s(n)}),`).join('\n')}
];

/// Formatos de pieza: (clave, nombre). FORMATS de la web.
const formatosWeb = <(String, String)>[
${Object.entries(FORMATS).map(([k, [n]]) => `  (${s(k)}, ${s(n)}),`).join('\n')}
];

/// Estados de pieza: (clave, nombre, ¿el cliente la ve?). POST_STATUS de la web.
const estadosPiezaWeb = <(String, String, bool)>[
${POST_STATUS.map(([k, n, , ve]) => `  (${s(k)}, ${s(n)}, ${ve ? 'true' : 'false'}),`).join('\n')}
];
`;
mkdirSync('lib/core/datos', { recursive: true });
writeFileSync('lib/core/datos/parrilla_web.dart', out);
console.log(`redes ${NETWORKS.length} · formatos ${Object.keys(FORMATS).length} · estados ${POST_STATUS.length}`);
