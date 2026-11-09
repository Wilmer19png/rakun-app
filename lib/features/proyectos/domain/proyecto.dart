
import '../../../core/datos/proyectos_web.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/tokens.dart';

/// Estado de un proyecto (check de fase2.sql).
enum EstadoProyecto {
  activo('Activo'),
  pausado('Pausado'),
  terminado('Terminado');

  const EstadoProyecto(this.nombre);
  final String nombre;
  static EstadoProyecto desde(String? k) => values.firstWhere((e) => e.name == k, orElse: () => activo);
}

/// Una fila de `projects` (con el nombre del cliente y, si existe, su cotización).
class Proyecto {
  const Proyecto({
    required this.id,
    required this.clienteId,
    required this.mundo,
    required this.nombre,
    required this.estado,
    this.clienteNombre,
    this.plan,
    this.etapa,
    this.inicio,
    this.fin,
    this.aCargo,
    this.cotizacionNumero,
    this.cotizacionToken,
  });

  factory Proyecto.desdeFila(Map<String, dynamic> f) {
    final q = f['quotes'];
    return Proyecto(
      id: f['id'] as String,
      clienteId: f['client_id'] as String,
      mundo: Mundo.desde(f['world'] as String?) ?? Mundo.marca,
      nombre: (f['name'] as String?) ?? '',
      estado: EstadoProyecto.desde(f['status'] as String?),
      clienteNombre: (f['clients'] as Map?)?['name'] as String?,
      plan: _texto(f['plan']),
      etapa: _texto(f['stage']),
      inicio: _fecha(f['start_date']),
      fin: _fecha(f['end_date']),
      aCargo: f['owner_id'] as String?,
      cotizacionNumero: q is Map ? q['number'] as String? : null,
      cotizacionToken: q is Map ? q['token'] as String? : null,
    );
  }

  final String id, clienteId, nombre;
  final Mundo mundo;
  final EstadoProyecto estado;
  final String? clienteNombre, plan, etapa, aCargo, cotizacionNumero, cotizacionToken;
  final DateTime? inicio, fin;

  /// Las etapas de su mundo (las mismas de la web).
  List<String> get etapas => etapasPara(mundo);

  bool coincide(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return true;
    return [nombre, clienteNombre, plan, etapa].any((v) => (v ?? '').toLowerCase().contains(t));
  }

  static String? _texto(Object? v) {
    final s = (v as String?)?.trim();
    return s == null || s.isEmpty ? null : s;
  }

  /// Las columnas `date` llegan como "2026-11-09": se leen como día local (sin hora ni zona).
  static DateTime? _fecha(Object? v) {
    if (v is! String || v.length < 10) return null;
    final p = v.substring(0, 10).split('-').map(int.tryParse).toList();
    if (p.any((x) => x == null)) return null;
    return DateTime(p[0]!, p[1]!, p[2]!);
  }
}

/// Clave de la base para cada mundo (marca | produccion | web).
String claveMundo(Mundo m) => switch (m) {
      Mundo.marca => 'marca',
      Mundo.produccion => 'produccion',
      Mundo.web => 'web',
    };

List<String> etapasPara(Mundo m) => etapasWeb[claveMundo(m)] ?? const [];

/// Estado de un entregable (DSTATUS de la web, mismo orden).
enum EstadoEntregable {
  porHacer('por_hacer'),
  enCurso('en_curso'),
  enRevision('en_revision'),
  aprobado('aprobado');

  const EstadoEntregable(this.clave);
  final String clave;
  String get nombre => estadosEntregableWeb.firstWhere((e) => e.$1 == clave).$2;
  static EstadoEntregable desde(String? k) => values.firstWhere((e) => e.clave == k, orElse: () => porHacer);
}

String nombreTipo(String? k) => tiposWeb[k] ?? tiposWeb['otro']!;

/// Una fila de `deliverables` (fase7.sql). El dinero (pay_amount…) no se lee aquí: es P2.
class Entregable {
  const Entregable({
    required this.id,
    required this.proyectoId,
    required this.titulo,
    required this.tipo,
    required this.estado,
    this.hace,
    this.revisa,
    this.vence,
    this.brief,
    this.entrega,
    this.notaEntrega,
    this.orden = 0,
  });

  factory Entregable.desdeFila(Map<String, dynamic> f) => Entregable(
        id: f['id'] as String,
        proyectoId: f['project_id'] as String,
        titulo: (f['title'] as String?) ?? '',
        tipo: (f['kind'] as String?) ?? 'otro',
        estado: EstadoEntregable.desde(f['status'] as String?),
        hace: f['assignee_id'] as String?,
        revisa: f['reviewer_id'] as String?,
        vence: f['due_at'] == null ? null : DateTime.parse(f['due_at'] as String).toLocal(),
        brief: f['brief_url'] as String?,
        entrega: f['delivery_url'] as String?,
        notaEntrega: f['delivery_note'] as String?,
        orden: (f['sort'] as num?)?.toInt() ?? 0,
      );

  final String id, proyectoId, titulo, tipo;
  final EstadoEntregable estado;
  final String? hace, revisa, brief, entrega, notaEntrega;
  final DateTime? vence;
  final int orden;
}

/// Reloj de las etiquetas de fecha (las pruebas lo fijan para que las capturas no cambien cada día).
DateTime Function() reloj = DateTime.now;

/// `bucket` de admin-entregables.js.
enum Plazo { vencido, hoy, semana, luego, sin }

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

Plazo plazoDe(Entregable d, {DateTime? ahora}) {
  final now = ahora ?? reloj();
  final v = d.vence;
  if (v == null) return Plazo.sin;
  if (v.isBefore(now) && d.estado != EstadoEntregable.aprobado) return Plazo.vencido;
  final hoy = _dia(now);
  if (v.isBefore(hoy.add(const Duration(days: 1)))) return Plazo.hoy;
  if (v.isBefore(hoy.add(const Duration(days: 7)))) return Plazo.semana;
  return Plazo.luego;
}

/// Lo que dice la fila sobre la fecha límite. Mismos cortes que `dueLabel` de la web
/// ("Venció hoy / ayer / hace N d", "Faltan N h"), en formato corto para el celular.
String etiquetaVence(Entregable d, {DateTime? ahora}) {
  final now = ahora ?? reloj();
  final v = d.vence;
  if (v == null) return 'Sin fecha';
  final ms = v.difference(now).inMilliseconds;
  if (ms < 0) {
    if (d.estado == EstadoEntregable.aprobado) return fechaCorta(v);
    final dias = _dia(now).difference(_dia(v)).inHours / 24;
    return dias < 1 ? 'Venció hoy' : dias < 2 ? 'Venció ayer' : 'Venció hace ${dias.round()} d';
  }
  if (ms < Duration.millisecondsPerDay && v.day == now.day) {
    final h = (ms / Duration.millisecondsPerHour).round();
    return 'Faltan ${h < 1 ? 1 : h} h';
  }
  if (_dia(v).difference(_dia(now)).inDays < 7) return diaSemanaYNumero(v);
  return fechaCorta(v);
}

/// Fecha límite que guarda la web al elegir un día: ese día a las 6 p. m. hora local.
DateTime venceElDia(DateTime dia) => DateTime(dia.year, dia.month, dia.day, 18);

/// Filas de la plantilla del mundo, contando desde hoy (como el botón de la web).
List<Map<String, Object?>> filasPlantilla(Proyecto p, {required int desde, DateTime? hoy}) {
  final base = hoy ?? DateTime.now();
  final lista = plantillasWeb[claveMundo(p.mundo)] ?? const [];
  return [
    for (var k = 0; k < lista.length; k++)
      {
        'project_id': p.id,
        'title': lista[k].$1,
        'kind': lista[k].$2,
        'assignee_id': p.aCargo,
        'due_at': venceElDia(DateTime(base.year, base.month, base.day + lista[k].$3)).toUtc().toIso8601String(),
        'sort': desde + k,
      },
  ];
}
