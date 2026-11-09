/* RAKÜN Studio · tema (corre antes de pintar para que no parpadee)
   oscuro (por defecto) · claro · sistema (sigue al teléfono). ?tema= gana sobre lo guardado. */
(function () {
  var t = new URLSearchParams(location.search).get('tema');
  try { if (!t) t = localStorage.getItem('rk-tema'); } catch (e) { /* sin almacenamiento: se usa el defecto */ }
  if (t === 'sistema') t = window.matchMedia('(prefers-color-scheme: light)').matches ? 'claro' : 'oscuro';
  document.documentElement.dataset.theme = t === 'claro' ? 'claro' : 'oscuro';
})();
