// Genera lib/core/datos/proyectos_web.dart desde los archivos ORIGINALES de la web:
// etapas (app/content.js → STAGES) y entregables (app/quote-sources.js → TEMPLATES, KINDS, DSTATUS).
// Uso: node tool/generar_proyectos.mjs
import { writeFileSync, mkdirSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const WEB = 'C:/Users/wburi/PÁGINA WEB RAKÜN/app';
globalThis.document ??= { addEventListener() {}, querySelector() { return null; } };
const { STAGES } = await import(pathToFileURL(`${WEB}/content.js`).href);
const { TEMPLATES, KINDS, DSTATUS } = await import(pathToFileURL(`${WEB}/quote-sources.js`).href);

const s = (v) => `'${String(v).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;
const lista = (a) => `[${a.map(s).join(', ')}]`;
const out = `// GENERADO por tool/generar_proyectos.mjs desde app/content.js y app/quote-sources.js de la web. No editar a mano.

/// Etapas de cada tipo de proyecto (el cliente las ve en su portal). STAGES de la web.
const etapasWeb = <String, List<String>>{
${Object.entries(STAGES).map(([k, v]) => `  ${s(k)}: ${lista(v)},`).join('\n')}
};

/// Plantilla de entregables por mundo: (título, tipo, días desde hoy). TEMPLATES de la web.
const plantillasWeb = <String, List<(String, String, int)>>{
${Object.entries(TEMPLATES).map(([k, v]) => `  ${s(k)}: [\n${v.map(([t, kind, d]) => `    (${s(t)}, ${s(kind)}, ${Number(d)}),`).join('\n')}\n  ],`).join('\n')}
};

/// Tipos de entregable. KINDS de la web (en el mismo orden).
const tiposWeb = <String, String>{
${Object.entries(KINDS).map(([k, v]) => `  ${s(k)}: ${s(v)},`).join('\n')}
};

/// Estados de un entregable: (clave, nombre). DSTATUS de la web (en el mismo orden).
const estadosEntregableWeb = <(String, String)>[
${DSTATUS.map(([k, n]) => `  (${s(k)}, ${s(n)}),`).join('\n')}
];
`;
mkdirSync('lib/core/datos', { recursive: true });
writeFileSync('lib/core/datos/proyectos_web.dart', out);
console.log(`etapas ${Object.keys(STAGES).length} mundos · plantillas ${Object.values(TEMPLATES).flat().length} · tipos ${Object.keys(KINDS).length} · estados ${DSTATUS.length}`);
