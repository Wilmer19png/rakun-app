/// Buscador de lugares de las grabaciones (places.js de la web): Photon (photon.komoot.io),
/// gratuito y basado en OpenStreetMap; no necesita clave. Prioriza resultados de Colombia.
library;

import 'dart:convert';
import 'dart:io';

typedef Lugar = ({String nombre, String direccion});

String _plegar(String s) {
  const de = 'áàäâãéèëêíìïîóòöôõúùüûñÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑ';
  const a = 'aaaaaeeeeiiiiooooouuuunAAAAAEEEEIIIIOOOOOUUUUN';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i < 0 ? ch : a[i]);
  }
  return b.toString().toLowerCase();
}

/// `toPlace` de la web: nombre + dirección legible sin repetir partes.
Lugar lugarDePhoton(Map<String, dynamic> p) {
  String? t(String k) => (p[k] as String?)?.trim().isEmpty ?? true ? null : (p[k] as String).trim();
  final calle = [t('street'), t('housenumber')].whereType<String>().join(' ');
  final zona = [t('locality') ?? t('district'), t('city') ?? t('county'), t('state')].whereType<String>();
  final unicos = <String>[];
  for (final s in [calle, ...zona].where((s) => s.isNotEmpty)) {
    if (unicos.any((u) => _plegar(u) == _plegar(s))) continue;
    // "Bogotá" + "Bogotá, Distrito Capital" → solo la segunda
    final i = unicos.indexWhere((u) => _plegar(s).startsWith('${_plegar(u)},'));
    if (i >= 0) {
      unicos[i] = s;
    } else {
      unicos.add(s);
    }
  }
  final pais = t('country');
  return (
    nombre: t('name') ?? (calle.isNotEmpty ? calle : t('city') ?? ''),
    direccion: unicos.join(', ') + (pais != null && pais != 'Colombia' ? ', $pais' : ''),
  );
}

/// Ordena (primero Colombia), convierte y quita repetidos; máximo 6, como `search` de la web.
List<Lugar> lugaresDeRespuesta(Map<String, dynamic> json) {
  final feats = [for (final f in (json['features'] as List? ?? const [])) Map<String, dynamic>.from(f as Map)];
  int co(Map<String, dynamic> f) => (f['properties'] as Map?)?['countrycode'] == 'CO' ? 0 : 1;
  feats.sort((a, b) => co(a) - co(b));
  final vistos = <String>{};
  final r = <Lugar>[];
  for (final f in feats) {
    final l = lugarDePhoton(Map<String, dynamic>.from(f['properties'] as Map? ?? const {}));
    if (l.nombre.isEmpty && l.direccion.isEmpty) continue;
    if (!vistos.add('${l.nombre}|${l.direccion}'.toLowerCase())) continue;
    r.add(l);
  }
  return r.take(6).toList();
}

Future<List<Lugar>> buscarLugares(String q) async {
  if (q.trim().length < 3) return const [];
  final uri = Uri.https('photon.komoot.io', '/api/', {'q': q.trim(), 'limit': '8', 'lang': 'default', 'lat': '5.5', 'lon': '-74.5'});
  final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final pedido = await cliente.getUrl(uri);
    pedido.headers.set(HttpHeaders.userAgentHeader, 'RAKUN-Studio-app');
    final res = await pedido.close();
    if (res.statusCode != 200) return const [];
    final cuerpo = await res.transform(utf8.decoder).join();
    return lugaresDeRespuesta(Map<String, dynamic>.from(jsonDecode(cuerpo) as Map));
  } finally {
    cliente.close();
  }
}

/// Enlace para abrir en Google Maps (mapLink de la web).
Uri enlaceMapa(String q) => Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': q});
