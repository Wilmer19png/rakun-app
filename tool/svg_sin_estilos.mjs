// Convierte un SVG con <style>.cls-N{fill:#xxx}</style> + class="cls-N" en fills directos.
// flutter_svg no aplica <style>: sin esto, el isotipo sale negro.
// Uso: node tool/svg_sin_estilos.mjs entrada.svg salida.svg
import { readFileSync, writeFileSync } from 'node:fs';

const [, , entrada, salida] = process.argv;
let svg = readFileSync(entrada, 'utf8');
const reglas = {};
const estilo = svg.match(/<style>([\s\S]*?)<\/style>/);
if (estilo) {
  for (const [, clases, cuerpo] of estilo[1].matchAll(/([^{}]+)\{([^}]*)\}/g)) {
    const props = Object.fromEntries(cuerpo.split(';').map((d) => d.split(':').map((x) => x.trim())).filter(([k, v]) => k && v));
    for (const c of clases.split(',').map((x) => x.trim().replace(/^\./, ''))) reglas[c] = { ...(reglas[c] || {}), ...props };
  }
  svg = svg.replace(/<defs>\s*<style>[\s\S]*?<\/style>\s*<\/defs>/, '').replace(/<style>[\s\S]*?<\/style>/, '');
}
let n = 0;
svg = svg.replace(/class="([^"]+)"/g, (_, clases) => {
  const props = Object.assign({}, ...clases.split(/\s+/).map((c) => reglas[c] || {}));
  n += 1;
  return Object.entries(props).map(([k, v]) => `${k}="${v}"`).join(' ');
});
writeFileSync(salida, svg);
console.log(`${Object.keys(reglas).length} estilos aplicados en ${n} formas · quedan <style>: ${/<style/.test(svg)}`);
