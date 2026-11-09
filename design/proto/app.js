/* ==========================================================================
   RAKÜN Studio · prototipo · comportamiento compartido
   ?rol=admin|manager|directora|editor|camara   → barra inferior según permisos
   ?estado=cargando|vacio|error|offline|vivo|sinpermiso → estados de la pantalla
   Datos: TODOS de ejemplo. Nada sale de Supabase.
   ========================================================================== */
import { RakunEye } from './eye.js';

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const q = new URLSearchParams(location.search);
const ROL = q.get('rol') || 'admin';
const ESTADO = q.get('estado') || '';

/* ---------- permisos de ejemplo (los roles listos de perms.js) ---------- */
const E = 'editar'; const V = 'ver';
const PERMS = {
  admin: null,
  manager: { pendientes: E, solicitudes: E, clientes: E, proyectos: E, metricas: V, tarifario: V, equipo: V, dinero: V },
  directora: { pendientes: E, proyectos: E, parrillas: E, grabaciones: E, reuniones: E, documentos: E, equipo: V },
  editor: { pendientes: E, equipo: V },
  camara: { pendientes: E, grabaciones: V, equipo: V },
};
const NAME = { admin: 'Wilmer', manager: 'Santiago', directora: 'Mariana', editor: 'Alexander', camara: 'Sofía' };
const can = (s) => { const p = PERMS[ROL]; if (s === 'pendientes') return true; if (p === null || p === undefined) return true; return p[s] === 'ver' || p[s] === 'editar'; };

/* Regla de la barra (design/MAPA_NAVEGACION.md §3) */
const DEST = {
  hoy: ['Hoy', 'today', 'hoy.html'],
  solicitudes: ['Solicitudes', 'inbox', 'solicitudes-a.html', () => can('solicitudes')],
  clientes: ['Clientes', 'groups', 'clientes.html', () => can('clientes')],
  agenda: ['Agenda', 'calendar_month', 'agenda.html', () => can('grabaciones') || can('reuniones')],
  proyectos: ['Proyectos', 'folder_open', 'proyectos.html', () => can('proyectos')],
  parrillas: ['Parrillas', 'grid_view', 'parrilla.html', () => can('parrillas')],
  mensajes: ['Mensajes', 'forum', 'mensajes.html', () => can('equipo')],
  mas: ['Más', 'menu', 'mas.html'],
};
const PRIORITY = ['solicitudes', 'agenda', 'proyectos', 'clientes', 'parrillas', 'mensajes'];
const ORDER = ['solicitudes', 'clientes', 'agenda', 'proyectos', 'parrillas', 'mensajes'];
export function navFor() {
  const mid = PRIORITY.filter((k) => DEST[k][3]()).slice(0, 3);
  return ['hoy', ...ORDER.filter((k) => mid.includes(k)), 'mas'];
}
const BADGE = { hoy: 6, solicitudes: 2, agenda: 1, mensajes: 1 };

/* enlaces internos conservan el rol */
function keepRole(href) {
  if (!href || /^(https?:|tel:|mailto:|#)/.test(href)) return href;
  const [path, qs = ''] = href.split('?');
  const p = new URLSearchParams(qs);
  if (!p.has('rol')) p.set('rol', ROL);
  return `${path}?${p}`;
}

/* ---------- barra de estado + barra inferior + gesto ---------- */
function chrome() {
  const sb = document.createElement('div');
  sb.className = 'sb';
  sb.setAttribute('aria-hidden', 'true');
  sb.innerHTML = '<span>9:41</span><span class="sb__r"><span class="ic">signal_cellular_alt</span><span class="ic">wifi</span><span class="ic">battery_full</span></span>';
  document.body.prepend(sb);

  let cur = document.body.dataset.nav;
  if (cur && !navFor().includes(cur)) cur = 'mas';      // subpantalla: se ilumina su padre
  if (cur) {
    document.body.classList.add('has-nav');
    const nav = document.createElement('nav');
    nav.className = 'nav';
    nav.setAttribute('aria-label', 'Secciones');
    nav.innerHTML = navFor().map((k) => {
      const [label, icon, href] = DEST[k];
      const b = BADGE[k] && !(ESTADO === 'vacio' && k === 'hoy') ? `<span class="nav__b">${BADGE[k]}</span>` : '';
      return `<a class="nav__i" href="${keepRole(href)}"${k === cur ? ' aria-current="page"' : ''}><span class="ic">${icon}</span>${b}<span>${label}</span></a>`;
    }).join('');
    document.body.append(nav);
  }
  const g = document.createElement('div');
  g.className = 'gest';
  g.setAttribute('aria-hidden', 'true');
  document.body.append(g);
}

/* ---------- textos por rol ---------- */
function roleText() {
  $$('[data-name]').forEach((el) => { el.textContent = NAME[ROL] || 'equipo'; });
  $$('[data-can]').forEach((el) => { if (!can(el.dataset.can)) el.remove(); });
  $$('[data-money]').forEach((el) => { const p = PERMS[ROL]; if (!(p === null || p?.dinero === 'ver')) el.remove(); });
  $$('[data-admin]').forEach((el) => { if (ROL !== 'admin') el.remove(); });
}

/* ---------- estados de prueba ---------- */
const GENERIC = {
  cargando: () => '<div class="skel" aria-label="Cargando" role="status"><i></i><i></i><i></i><i></i><i></i><i></i></div>',
  error: () => `<div class="err" role="alert"><b>No pudimos traer esta lista.</b><p>No hubo respuesta del servidor. Revisa tu internet y vuelve a intentar; lo último guardado es de las 9:12 a. m.</p><div><button class="btn btn--line" type="button" data-snack="Actualizado">Reintentar</button></div></div>`,
  sinpermiso: () => `<div class="noperm"><span class="ic">lock</span><p class="empty__t">No está en <em>tus permisos.</em></p><p class="dim">Esta sección no está habilitada para tu cuenta. Si la necesitas, pídele acceso a Wilmer.</p><a class="btn btn--line" href="${keepRole('hoy.html')}">Ir a Hoy</a></div>`,
};
function states() {
  if (!ESTADO) return;
  const region = $('[data-region]');
  if (ESTADO === 'offline') {
    const bar = document.createElement('div');
    bar.className = 'offline';
    bar.setAttribute('role', 'status');
    bar.innerHTML = '<span class="ic">cloud_off</span><span>Sin conexión · ves lo guardado a las 9:12 a. m. Los cambios se activan al volver.</span>';
    $('.top, .hello')?.before(bar) ?? document.body.insertBefore(bar, $('.main'));
    $$('[data-write]').forEach((b) => { b.disabled = true; b.title = 'Sin conexión'; });
    $('.fab')?.setAttribute('hidden', '');
    return;
  }
  if (ESTADO === 'vivo') {
    const pill = document.createElement('div');
    pill.className = 'live';
    pill.innerHTML = `<button type="button" data-snack="Lista al día"><span class="ic ic--sm">arrow_upward</span>${region?.dataset.live || '2 nuevas'}</button>`;
    (region || $('.main')).prepend(pill);
    return;
  }
  if (!region) return;
  if (ESTADO === 'vacio') {
    const sum = $('.hello__sum'); if (sum) sum.textContent = 'No tienes pendientes hoy.';
    const tpl = $('template[data-empty]');
    region.innerHTML = tpl ? tpl.innerHTML : '';
    $('.fab')?.removeAttribute('hidden');
    return;
  }
  if (ESTADO === 'sinpermiso') { $('.main').innerHTML = GENERIC.sinpermiso(); $$('.tabs, .fab, .top__row .ib:not([aria-label="Volver"])').forEach((el) => el.remove()); return; }
  if (GENERIC[ESTADO]) region.innerHTML = GENERIC[ESTADO]();
}

/* ---------- hojas inferiores ---------- */
function sheets() {
  let scrim = $('.scrim');
  if (!scrim && $('.sheet')) { scrim = document.createElement('div'); scrim.className = 'scrim'; document.body.append(scrim); }
  const close = () => { $$('.sheet.is-open').forEach((s) => s.classList.remove('is-open')); document.body.classList.remove('is-sheet'); };
  const open = (id) => { close(); const s = document.getElementById(id); if (!s) return; s.classList.add('is-open'); document.body.classList.add('is-sheet'); s.setAttribute('tabindex', '-1'); s.focus({ preventScroll: true }); };
  document.addEventListener('click', (e) => {
    const o = e.target.closest('[data-open]');
    if (o) { e.preventDefault(); open(o.dataset.open); return; }
    if (e.target.closest('[data-close]') || e.target === scrim) close();
  });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
  if (q.get('hoja')) requestAnimationFrame(() => open(q.get('hoja')));
}

/* ---------- avisos breves ---------- */
function snack() {
  const s = document.createElement('div');
  s.className = 'snack';
  s.setAttribute('role', 'status');
  s.innerHTML = '<span></span><button class="btn btn--text" type="button">Deshacer</button>';
  document.body.append(s);
  let t;
  document.addEventListener('click', (e) => {
    const b = e.target.closest('[data-snack]');
    if (!b) return;
    $('span', s).textContent = b.dataset.snack;
    $('button', s).hidden = !b.hasAttribute('data-undo');
    s.classList.add('is-on');
    clearTimeout(t);
    t = setTimeout(() => s.classList.remove('is-on'), 2600);
    if (b.closest('.sheet')) document.querySelector('[data-close]')?.click();
  });
}

/* ---------- chips, pestañas, segmentos, opciones ---------- */
function toggles() {
  document.addEventListener('click', (e) => {
    const chip = e.target.closest('.chips .chip');
    if (chip && chip.closest('[data-single]')) {
      $$('.chip', chip.parentElement).forEach((c) => c.setAttribute('aria-pressed', String(c === chip)));
    } else if (chip) chip.setAttribute('aria-pressed', String(chip.getAttribute('aria-pressed') !== 'true'));
    const tab = e.target.closest('[role="tab"]');
    if (tab) {
      const list = tab.closest('[role="tablist"]');
      $$('[role="tab"]', list).forEach((t) => t.setAttribute('aria-selected', String(t === tab)));
      if (tab.dataset.panel) $$(`[data-panel-of="${list.id}"]`).forEach((p) => { p.hidden = p.id !== tab.dataset.panel; });
    }
    const seg = e.target.closest('.seg button');
    if (seg) {
      $$('button', seg.parentElement).forEach((b) => b.setAttribute('aria-pressed', String(b === seg)));
      if (seg.dataset.show) $$(`[data-when-of="${seg.parentElement.id}"]`).forEach((el) => { el.hidden = el.dataset.when !== seg.dataset.show; });
    }
    const opt = e.target.closest('.opt[role="menuitemradio"]');
    if (opt) $$('.opt[role="menuitemradio"]', opt.parentElement).forEach((o) => o.setAttribute('aria-checked', String(o === opt)));
    const pass = e.target.closest('[data-pass]');
    if (pass) { const i = pass.previousElementSibling; i.type = i.type === 'password' ? 'text' : 'password'; $('.ic', pass).textContent = i.type === 'password' ? 'visibility' : 'visibility_off'; }
  });
}

/* ---------- barra superior que se encoge ---------- */
function collapse() {
  const top = $('.top--large');
  const main = $('.main');
  if (!top || !main) return;
  main.addEventListener('scroll', () => top.classList.toggle('is-scrolled', main.scrollTop > 24), { passive: true });
}

/* ---------- ojos ---------- */
function eyes() {
  $$('svg[data-eye]').forEach((svg) => {
    const startClosed = svg.hasAttribute('data-eye-open');
    const eye = new RakunEye(svg, { prefix: svg.dataset.eye || undefined, openness: startClosed ? 0 : 1 });
    if (startClosed) setTimeout(() => eye.open().then(() => eye.explore?.()), 180);
    else if (svg.hasAttribute('data-eye-explore')) eye.explore?.();
    svg.closest('[data-eye-box]')?.addEventListener('click', () => eye.blink());
  });
}

/* ---------- arranque ---------- */
$$('a[href]').forEach((a) => { a.setAttribute('href', keepRole(a.getAttribute('href'))); });
roleText();
chrome();
states();
sheets();
snack();
toggles();
collapse();
eyes();

/* splash → Hoy en menos de 1,5 s (en la galería se queda quieto) */
if (document.body.dataset.screen === 'splash' && q.get('auto') !== '0') {
  setTimeout(() => { location.href = keepRole('login.html'); }, 1400);
}
