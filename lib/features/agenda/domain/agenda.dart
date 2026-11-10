/// 05 Grabaciones + 06 Reuniones (admin-agenda.js) unidas en «Agenda».
library;

import '../../../core/datos/agenda_web.dart';
import '../../../core/utils/fechas.dart';

String _nombre(List<(String, String)> lista, String? k) => lista.where((e) => e.$1 == k).firstOrNull?.$2 ?? (k ?? '—');
String nombreEstadoGrabacion(String? k) => _nombre(estadosGrabacionWeb, k);
String nombreEstadoReunion(String? k) => _nombre(estadosReunionWeb, k);
String nombreTipoReunion(String? k) => _nombre(tiposReunionWeb, k);

List<String> _textos(Object? x) => [for (final v in (x as List? ?? const [])) if (v != null) v.toString()];

/// Una fila de `shoots` (fase4.sql).
class Grabacion {
  const Grabacion({
    required this.id,
    required this.clienteId,
    required this.inicio,
    this.proyectoId,
    this.horas = 3,
    this.estado = 'programada',
    this.lugar,
    this.direccion,
    this.equipo = const [],
    this.prepara = const [],
    this.respuesta,
    this.notaCliente,
  });

  factory Grabacion.desdeFila(Map<String, dynamic> f) => Grabacion(
        id: f['id'] as String,
        clienteId: f['client_id'] as String,
        proyectoId: f['project_id'] as String?,
        inicio: DateTime.parse(f['starts_at'] as String).toLocal(),
        horas: (f['duration_hours'] as num?)?.toDouble() ?? 3,
        estado: (f['status'] as String?) ?? 'programada',
        lugar: f['location'] as String?,
        direccion: f['address'] as String?,
        equipo: _textos(f['crew']),
        prepara: _textos(f['prep']),
        respuesta: f['client_response'] as String?,
        notaCliente: f['client_note'] as String?,
      );

  final String id, clienteId, estado;
  final String? proyectoId, lugar, direccion, respuesta, notaCliente;
  final DateTime inicio;
  final double horas;
  final List<String> equipo, prepara;

  bool get pideOtraFecha => respuesta == 'reprogramar';
  bool get confirmo => respuesta == 'confirmada';

  /// "3 h", "1,5 h".
  String get duracion => '${horas == horas.roundToDouble() ? horas.round() : horas.toString().replaceAll('.', ',')} h';

  /// Lo que dice del cliente (solo si está programada, como la web).
  String? get respuestaCliente => estado != 'programada'
      ? null
      : confirmo
          ? 'confirmó'
          : pideOtraFecha
              ? 'pide otra fecha${(notaCliente ?? '').isEmpty ? '' : ': “$notaCliente”'}'
              : 'esperando confirmación';

  /// Para "Cómo llegar": lugar y dirección juntos.
  String get paraMapa => [lugar, direccion].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
}

/// Una fila de `meetings` (fase4.sql).
class Reunion {
  const Reunion({
    required this.id,
    required this.clienteId,
    required this.titulo,
    this.tipo = 'dudas',
    this.inicio,
    this.minutos = 20,
    this.enlace,
    this.estado = 'confirmada',
    this.conQuien,
    this.notaCliente,
    this.acuerdos,
  });

  factory Reunion.desdeFila(Map<String, dynamic> f) => Reunion(
        id: f['id'] as String,
        clienteId: f['client_id'] as String,
        titulo: (f['title'] as String?) ?? '',
        tipo: (f['kind'] as String?) ?? 'dudas',
        inicio: f['starts_at'] == null ? null : DateTime.parse(f['starts_at'] as String).toLocal(),
        minutos: (f['duration_min'] as num?)?.toInt() ?? 20,
        enlace: f['link'] as String?,
        estado: (f['status'] as String?) ?? 'confirmada',
        conQuien: f['owner_id'] as String?,
        notaCliente: f['client_note'] as String?,
        acuerdos: f['summary'] as String?,
      );

  final String id, clienteId, titulo, tipo, estado;
  final DateTime? inicio;
  final int minutos;
  final String? enlace, conQuien, notaCliente, acuerdos;

  bool get pedida => estado == 'solicitada';
}

/// Un evento de la agenda unida: o grabación o reunión.
class Evento {
  const Evento.grabacion(Grabacion this.g) : r = null;
  const Evento.reunion(Reunion this.r) : g = null;
  final Grabacion? g;
  final Reunion? r;
  DateTime? get inicio => g?.inicio ?? r?.inicio;
  String get id => g?.id ?? r!.id;
}

/// Reuniones como las separa viewMeetings: pedidas, próximas (desde hace 2 h) y anteriores.
({List<Reunion> pedidas, List<Reunion> proximas, List<Reunion> anteriores}) repartirReuniones(List<Reunion> todas, {DateTime? ahora}) {
  final corte = (ahora ?? reloj()).subtract(const Duration(hours: 2));
  final pedidas = todas.where((m) => m.pedida).toList();
  final proximas = todas.where((m) => !m.pedida && m.inicio != null && !m.inicio!.isBefore(corte) && m.estado != 'cancelada').toList()
    ..sort((a, b) => a.inicio!.compareTo(b.inicio!));
  final anteriores = todas.where((m) => !m.pedida && (m.inicio == null || m.inicio!.isBefore(corte) || m.estado == 'cancelada')).toList()
    ..sort((a, b) => (b.inicio ?? DateTime(0)).compareTo(a.inicio ?? DateTime(0)));
  return (pedidas: pedidas, proximas: proximas, anteriores: anteriores);
}

/// Grupos por día ("Hoy · lun 9 nov", "Mañana · mar 10 nov", "Jue 12 nov"), en el orden de la lista.
List<(String, List<Evento>)> porDia(List<Evento> eventos, {DateTime? ahora}) {
  final n = ahora ?? reloj();
  final base = DateTime(n.year, n.month, n.day);
  final grupos = <String, List<Evento>>{};
  for (final e in eventos) {
    final i = e.inicio;
    if (i == null) continue;
    final dia = DateTime(i.year, i.month, i.day);
    final dif = (dia.difference(base).inHours / 24).round();
    final nombre = dif == 0
        ? 'Hoy · ${diaCorto(i)}'
        : dif == 1
            ? 'Mañana · ${diaCorto(i)}'
            : dif == -1
                ? 'Ayer · ${diaCorto(i)}'
                : '${diaCorto(i)[0].toUpperCase()}${diaCorto(i).substring(1)}${i.year != base.year ? ' ${i.year}' : ''}';
    (grupos[nombre] ??= []).add(e);
  }
  return [for (final e in grupos.entries) (e.key, e.value)];
}

/// `toISO` de la web: fecha + hora local → instante (se guarda en UTC).
DateTime aInstante(DateTime dia, int hora, int minuto) => DateTime(dia.year, dia.month, dia.day, hora, minuto);

/// Errores del formulario de grabación, como la web (equipo obligatorio salvo si se cancela).
String? errorGrabacion({required DateTime? dia, required List<String> equipo, required String estado}) {
  if (dia == null) return 'Elige la fecha.';
  if (equipo.isEmpty && estado != 'cancelada') return 'Elige quién va del equipo a la grabación.';
  return null;
}

/// Errores del formulario de reunión, como la web.
String? errorReunion({required String tema, required DateTime? dia, required String enlace, required String enlaceSeguro}) {
  if (tema.trim().isEmpty) return 'Ponle un tema.';
  if (tema.trim().length < 2) return 'El tema es muy corto.';
  if (dia == null) return 'Elige la fecha.';
  if (enlace.trim().isNotEmpty && enlaceSeguro.isEmpty) return 'El link de Meet no es válido.';
  return null;
}

/// "Qué prepara el cliente": una cosa por línea, sin vacías.
List<String> lineas(String texto) => [for (final l in texto.split('\n')) if (l.trim().isNotEmpty) l.trim()];

/// Si cambia la fecha o se marca "ya acordamos", la respuesta del cliente vuelve a empezar.
bool reiniciaRespuesta({required Grabacion? antes, required DateTime nuevoInicio, required bool yaAcordamos}) =>
    antes != null && (yaAcordamos || !antes.inicio.isAtSameMomentAs(nuevoInicio));

/// Lugares donde ya se grabó (sin repetidos), como el buscador de la web.
List<({String nombre, String direccion})> lugaresAnteriores(List<Map<String, dynamic>> filas) {
  final vistos = <String>{};
  final r = <({String nombre, String direccion})>[];
  for (final f in filas) {
    final n = (f['location'] as String?) ?? '';
    final d = (f['address'] as String?) ?? '';
    if (n.isEmpty) continue;
    if (vistos.add('$n|$d'.toLowerCase())) r.add((nombre: n, direccion: d));
  }
  return r;
}
