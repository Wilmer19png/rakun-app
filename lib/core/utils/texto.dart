/// Utilidades de rakun-web/app/util.js portadas tal cual (con prueba de paridad).
library;

/// `waNumber`: solo dígitos para wa.me. Un celular colombiano de 10 dígitos (3xx…) lleva el 57 delante.
String numeroWhatsApp(String? telefono) {
  final d = (telefono ?? '').replaceAll(RegExp(r'\D'), '');
  return d.length == 10 && d.startsWith('3') ? '57$d' : d;
}

/// Teléfono para leer: un celular colombiano de 10 dígitos se agrupa "300 000 0000"; lo demás queda igual.
String telefonoLegible(String? t) {
  final d = (t ?? '').replaceAll(RegExp(r'\D'), '');
  if (d.length == 10 && d.startsWith('3')) return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
  if (d.length == 12 && d.startsWith('573')) return '+57 ${d.substring(2, 5)} ${d.substring(5, 8)} ${d.substring(8)}';
  return (t ?? '').trim();
}

/// `safeUrl`: convierte lo que escribió la persona en un enlace seguro (solo http/https); si no, ''.
String enlaceSeguro(String? raw) {
  final v = (raw ?? '').trim();
  if (v.isEmpty) return '';
  final conEsquema = RegExp(r'^https?://', caseSensitive: false).hasMatch(v) ? v : 'https://$v';
  var u = Uri.tryParse(conEsquema);
  // como `new URL()` del navegador: un dominio con espacios u otros caracteres prohibidos no es un enlace
  if (u == null || !(u.isScheme('http') || u.isScheme('https')) || u.host.isEmpty || u.host.contains('%')) return '';
  // y un enlace sin ruta termina en "/" (https://web.co → https://web.co/)
  if (u.path.isEmpty) u = u.replace(path: '/');
  return u.toString();
}

/// `initials`: hasta dos iniciales en mayúscula.
String iniciales(String? nombre) {
  final palabras = (nombre ?? '?').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
  final r = palabras.map((w) => w[0]).join().toUpperCase();
  return r.isEmpty ? '?' : r;
}

/// `ago`: "ahora", "hace 5 min", "hace 2 h", "ayer", "hace 3 d", o la fecha ("9 nov").
String hace(DateTime fecha, {DateTime? ahora}) {
  final s = (ahora ?? DateTime.now()).difference(fecha).inSeconds;
  if (s < 60) return 'ahora';
  if (s < 3600) return 'hace ${s ~/ 60} min';
  if (s < 86400) return 'hace ${s ~/ 3600} h';
  if (s < 172800) return 'ayer';
  if (s < 604800) return 'hace ${s ~/ 86400} d';
  const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
  final f = fecha.toLocal();
  return '${f.day} ${meses[f.month - 1]}';
}

/// `cop` de la web: "$486.000" (redondeado, miles con punto como es-CO).
String pesos(num? n) {
  final v = (n ?? 0).round();
  final d = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write('.');
    b.write(d[i]);
  }
  return '${v < 0 ? '-' : ''}\$$b';
}
