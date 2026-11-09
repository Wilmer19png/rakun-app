// RAKÜN Studio · servidor local del prototipo (sin dependencias)
// Uso: doble clic en design/ABRIR-PROTOTIPO.cmd  ·  o  node design/servir.mjs  → http://localhost:5173
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, join, normalize, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('.', import.meta.url));
const PORT = Number(process.env.PORT) || 5173;
const URL_LOCAL = `http://localhost:${PORT}`;
const TYPES = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.mjs': 'text/javascript; charset=utf-8', '.svg': 'image/svg+xml', '.otf': 'font/otf', '.png': 'image/png', '.md': 'text/plain; charset=utf-8', '.ico': 'image/x-icon' };

const server = createServer(async (req, res) => {
  let path;
  try { path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^[/\\]+/, ''); } catch { res.writeHead(400).end(); return; }
  if (path === 'favicon.ico') { res.writeHead(204).end(); return; }          // la galería no tiene ícono de pestaña
  const file = join(ROOT, path || 'index.html');
  if (!(file + sep).startsWith(ROOT) && file !== ROOT.slice(0, -1)) { res.writeHead(403).end(); return; }
  try {
    const body = await readFile(file);
    res.writeHead(200, { 'Content-Type': TYPES[extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' }).end(body);
  } catch { res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }).end(`No existe: /${path}`); }
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.log(`El prototipo ya está abierto en ${URL_LOCAL} (no hace falta abrirlo dos veces).`);
    process.exit(0);
  }
  console.error(`No se pudo abrir el servidor: ${err.message}`);
  process.exit(1);
});

server.listen(PORT, '127.0.0.1', () => console.log(`Prototipo en ${URL_LOCAL}  ·  deja esta ventana abierta; ciérrala (o Ctrl+C) para apagarlo.`));
