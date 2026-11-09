import { chromium } from 'playwright';
import { readdir, readFile } from 'node:fs/promises';
import { pathToFileURL, fileURLToPath } from 'node:url';
const size = process.argv[2] || 'oscuro/360x800';
const out = process.argv[3];
const dir = fileURLToPath(new URL(`../capturas/${size}/`, import.meta.url));
const files = (await readdir(dir)).filter((f) => f.endsWith('.png')).sort();
const imgs = Object.fromEntries(await Promise.all(files.map(async (f) => [f, (await readFile(dir + f)).toString('base64')])));
const per = 8; const [w, h] = size.split('/').pop().split('x').map(Number); const s = 0.6;
const b = await chromium.launch({ channel: 'chrome' });
for (let i = 0; i < files.length; i += per) {
  const p = await b.newPage({ viewport: { width: Math.ceil(per / 2) * (w * s + 12) + 12, height: 2 * (h * s + 30) + 12 } });
  await p.setContent(`<body style="margin:0;padding:6px;background:#333;display:flex;flex-wrap:wrap;gap:12px;font:12px monospace;color:#fff">${files.slice(i, i + per).map((f) => `<div><img src="data:image/png;base64,${imgs[f]}" style="width:${w * s}px;height:${h * s}px;display:block"><div>${f}</div></div>`).join('')}</body>`);
  await p.waitForTimeout(300);
  await p.screenshot({ path: `${out}/hoja-${String(i / per + 1).padStart(2, '0')}.png` });
}
await b.close();
