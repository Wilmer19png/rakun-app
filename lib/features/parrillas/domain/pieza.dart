/// 04 · Parrillas (admin-parrilla.js): piezas de contenido por proyecto de Redes y mes.
library;

import '../../../core/datos/parrilla_web.dart';

String nombreFormato(String? k) => formatosWeb.where((f) => f.$1 == k).firstOrNull?.$2 ?? 'Post';
String nombreEstadoPieza(String? k) => estadosPiezaWeb.where((e) => e.$1 == k).firstOrNull?.$2 ?? 'Borrador';

/// Nombre corto del estado (para etiquetas): "Lista · sin enviar" → "Lista", "Cambios pedidos" → "Cambios".
String estadoCorto(String? k) => switch (k) {
      'lista' => 'Lista',
      'cambios' => 'Cambios',
      _ => nombreEstadoPieza(k),
    };

/// El cliente solo ve lo que se le envía ("Por aprobar" en adelante).
bool laVeElCliente(String? k) => estadosPiezaWeb.where((e) => e.$1 == k).firstOrNull?.$3 ?? false;

/// Una fila de `posts` (fase2.sql).
class Pieza {
  const Pieza({
    required this.id,
    required this.proyectoId,
    required this.clienteId,
    required this.publica,
    required this.titulo,
    this.formato = 'reel',
    this.redes = const [],
    this.texto,
    this.variantes = const {},
    this.medio,
    this.guion,
    this.aCargo,
    this.pauta = false,
    this.estado = 'borrador',
    this.notaCliente,
    this.publicada,
  });

  factory Pieza.desdeFila(Map<String, dynamic> f) {
    final variantes = f['copy_variants'] is Map ? Map<String, dynamic>.from(f['copy_variants'] as Map) : const <String, dynamic>{};
    return Pieza(
      id: f['id'] as String,
      proyectoId: f['project_id'] as String,
      clienteId: f['client_id'] as String,
      publica: DateTime.parse(f['publish_at'] as String).toLocal(),
      titulo: (f['title'] as String?) ?? '',
      formato: (f['format'] as String?) ?? 'reel',
      redes: [for (final r in (f['networks'] as List? ?? const [])) r.toString()],
      texto: f['copy'] as String?,
      variantes: variantes,
      medio: f['media_url'] as String?,
      guion: f['script_url'] as String?,
      aCargo: f['assigned_to'] as String?,
      pauta: (f['has_ads'] as bool?) ?? false,
      estado: (f['status'] as String?) ?? 'borrador',
      notaCliente: f['client_note'] as String?,
      publicada: f['published_url'] as String?,
    );
  }

  final String id, proyectoId, clienteId, titulo, formato, estado;
  final DateTime publica;
  final List<String> redes;
  final Map<String, dynamic> variantes; // copy_variants tal cual
  String? get textoAlterno => variantes['alt'] as String?;
  final String? texto, medio, guion, aCargo, notaCliente, publicada;
  final bool pauta;

  bool get pidioCambio => estado == 'cambios';
}

DateTime inicioDeMes(DateTime d) => DateTime(d.year, d.month);
DateTime sumarMeses(DateTime mes, int n) => DateTime(mes.year, mes.month + n);

const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

/// "Noviembre" (o "Noviembre 2027" si no es el año de `hoy`).
String nombreMes(DateTime mes, {required DateTime hoy}) {
  final n = _meses[mes.month - 1];
  return '${n[0].toUpperCase()}${n.substring(1)}${mes.year != hoy.year ? ' ${mes.year}' : ''}';
}

/// Cuántas piezas hay en cada estado (en el orden de la web; solo los que tienen).
List<(String, int)> contarPorEstado(List<Pieza> piezas) => [
      for (final e in estadosPiezaWeb)
        if (piezas.any((p) => p.estado == e.$1)) (e.$1, piezas.where((p) => p.estado == e.$1).length),
    ];

/// Piezas agrupadas por día (en orden).
List<(DateTime, List<Pieza>)> porDiaDelMes(List<Pieza> piezas) {
  final r = <DateTime, List<Pieza>>{};
  for (final p in [...piezas]..sort((a, b) => a.publica.compareTo(b.publica))) {
    (r[DateTime(p.publica.year, p.publica.month, p.publica.day)] ??= []).add(p);
  }
  return [for (final e in r.entries) (e.key, e.value)];
}

/// duplicateMonth: misma estructura en el mes siguiente, todo en borrador (día recortado al último del mes).
List<Map<String, Object?>> filasDuplicadas(List<Pieza> piezas, {required DateTime mes, required String proyectoId, required String clienteId}) {
  final sig = sumarMeses(mes, 1);
  final ultimo = DateTime(sig.year, sig.month + 1, 0).day;
  return [
    for (final p in piezas)
      {
        'project_id': proyectoId,
        'client_id': clienteId,
        'publish_at': DateTime(sig.year, sig.month, p.publica.day > ultimo ? ultimo : p.publica.day, p.publica.hour, p.publica.minute).toUtc().toIso8601String(),
        'format': p.formato,
        'title': p.titulo,
        'networks': p.redes,
        'copy': p.texto,
        'copy_variants': p.variantes,
        'assigned_to': p.aCargo,
        'has_ads': p.pauta,
        'status': 'borrador',
      },
  ];
}
