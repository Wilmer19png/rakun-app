// Genera test/paridad/permisos.json ejecutando el perms.js ORIGINAL de rakun-web.
// La prueba de Dart (test/core/permisos_test.dart) exige el mismo resultado.
// Uso (desde rakun-app):  node test/paridad/generar_permisos.mjs "C:/Users/wburi/PÁGINA WEB RAKÜN"
import { writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const web = process.argv[2] || 'C:/Users/wburi/PÁGINA WEB RAKÜN';
const { can, seesMoney, presetOf, PRESETS, SECTIONS } = await import(pathToFileURL(`${web}/app/perms.js`).href);

const perfiles = [
  { nombre: 'admin', me: { role: 'admin', perms: null } },
  { nombre: 'admin-con-perms', me: { role: 'admin', perms: { pendientes: 'ver' } } },
  { nombre: 'equipo-total', me: { role: 'equipo', perms: null } },
  ...Object.entries(PRESETS).filter(([, v]) => v.perms).map(([k, v]) => ({ nombre: `preset-${k}`, me: { role: 'equipo', perms: v.perms } })),
  { nombre: 'equipo-vacio', me: { role: 'equipo', perms: {} } },
  { nombre: 'equipo-sin-pendientes', me: { role: 'equipo', perms: { solicitudes: 'ver' } } },
  { nombre: 'equipo-dinero-sin-secciones', me: { role: 'equipo', perms: { dinero: 'ver' } } },
  { nombre: 'equipo-valor-raro', me: { role: 'equipo', perms: { proyectos: 'otro', clientes: 'editar' } } },
  { nombre: 'cliente', me: { role: 'cliente', perms: null } },
  { nombre: 'sin-rol', me: { role: null, perms: null } },
  { nombre: 'sin-sesion', me: null },
];

const casos = perfiles.map(({ nombre, me }) => ({
  nombre,
  role: me?.role ?? null,
  perms: me?.perms ?? null,
  sinSesion: me === null,
  can: Object.fromEntries(SECTIONS.map(([k]) => [k, { ver: can(me, k), editar: can(me, k, true) }])),
  seesMoney: Boolean(seesMoney(me)),
  presetOf: me ? presetOf(me.perms) : null,
}));

writeFileSync(new URL('./permisos.json', import.meta.url), `${JSON.stringify({ origen: 'rakun-web/app/perms.js', casos }, null, 2)}\n`);
console.log(`permisos.json: ${casos.length} perfiles × ${SECTIONS.length} secciones`);
