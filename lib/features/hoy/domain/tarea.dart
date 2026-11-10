/// 00 · Hoy (viewPending de admin-entregables.js): lo que me toca hacer o revisar.
library;

import '../../../design_system/tokens.dart';
import '../../proyectos/domain/proyecto.dart';

/// Un entregable visto desde "mis pendientes": con su proyecto y si me toca revisarlo.
class Tarea {
  const Tarea({required this.d, required this.revision, this.proyectoNombre, this.mundo, this.clienteNombre});

  /// Fila de `deliverables` con `projects(id, name, world, clients(name))`.
  factory Tarea.desdeFila(Map<String, dynamic> f, {required String yo}) {
    final p = f['projects'] is Map ? Map<String, dynamic>.from(f['projects'] as Map) : const <String, dynamic>{};
    final cl = p['clients'] is Map ? Map<String, dynamic>.from(p['clients'] as Map) : const <String, dynamic>{};
    final d = Entregable.desdeFila(f);
    return Tarea(
      d: d,
      // como la web: me toca revisar si soy el revisor, está en revisión y no la hice yo
      revision: d.revisa == yo && d.estado == EstadoEntregable.enRevision && d.hace != yo,
      proyectoNombre: p['name'] as String?,
      mundo: Mundo.values.where((m) => claveMundo(m) == p['world']).firstOrNull,
      clienteNombre: cl['name'] as String?,
    );
  }

  final Entregable d;
  final bool revision;
  final String? proyectoNombre, clienteNombre;
  final Mundo? mundo;

  String get id => d.id;

  /// "Revisión" o el tipo del entregable (el filtro "Tipo" de la web).
  String get claveTipo => revision ? 'revision' : d.tipo;
}

String nombreClaveTipo(String k) => k == 'revision' ? 'Revisión' : nombreTipo(k);

/// Grupos de la pantalla. "Te toca revisar" va aparte (prototipo aprobado); lo demás por plazo, como la web.
enum GrupoHoy {
  vencido('Vencido'),
  revisar('Te toca revisar'),
  hoy('Hoy'),
  semana('Esta semana'),
  luego('Más adelante'),
  sin('Sin fecha');

  const GrupoHoy(this.nombre);
  final String nombre;
}

GrupoHoy grupoDe(Tarea t, {DateTime? ahora}) {
  if (t.revision) return GrupoHoy.revisar;
  return switch (plazoDe(t.d, ahora: ahora)) {
    Plazo.vencido => GrupoHoy.vencido,
    Plazo.hoy => GrupoHoy.hoy,
    Plazo.semana => GrupoHoy.semana,
    Plazo.luego => GrupoHoy.luego,
    Plazo.sin => GrupoHoy.sin,
  };
}

/// La frase de arriba: "Tienes 6 pendientes en 3 proyectos · 2 vencidos · 3 para hoy."
({int total, int proyectos, int vencidos, int hoy}) resumen(List<Tarea> ts, {DateTime? ahora}) => (
      total: ts.length,
      proyectos: ts.map((t) => t.d.proyectoId).toSet().length,
      vencidos: ts.where((t) => plazoDe(t.d, ahora: ahora) == Plazo.vencido).length,
      hoy: ts.where((t) => plazoDe(t.d, ahora: ahora) == Plazo.hoy).length,
    );

/// Estados que puede elegir quien hace la tarea (DSTATUS sin "Aprobado" si alguien la revisa).
List<EstadoEntregable> estadosParaMi(Entregable d) =>
    [for (final e in EstadoEntregable.values) if (e != EstadoEntregable.aprobado || d.revisa == null) e];

/// Al entregar: si la revisa otra persona → "En revisión"; si no → "Aprobado" (regla de la web).
EstadoEntregable estadoAlEntregar(Entregable d, {required String yo}) =>
    d.revisa != null && d.revisa != yo ? EstadoEntregable.enRevision : EstadoEntregable.aprobado;

/// Nota al devolver (la web: "Devuelto: …" o "Devuelto para ajustes").
String notaDevolucion(String porque) => porque.trim().isEmpty ? 'Devuelto para ajustes' : 'Devuelto: ${porque.trim()}';

/// Ruta en la carpeta «entregas» (uploadDelivery): proyecto/entregable/ms-nombre_limpio (últimos 80).
String rutaEntrega(Entregable d, String nombreArchivo, {required int ms}) {
  final limpio = nombreArchivo.replaceAll(RegExp(r'[^\w.-]+'), '_');
  final corto = limpio.length > 80 ? limpio.substring(limpio.length - 80) : limpio;
  return '${d.proyectoId}/${d.id}/$ms-$corto';
}

const maxEntrega = 50 * 1024 * 1024;

/// "Lo que ganas": tareas con valor sin pagar + comisiones por pagar (pendingExtras).
class Ganancias {
  const Ganancias({this.aprobadas = 0, this.enCurso = 0, this.comisiones = 0, this.mensuales = 0});
  final double aprobadas, enCurso, comisiones;
  final int mensuales;
  double get porCobrar => aprobadas + comisiones;
  bool get hayAlgo => aprobadas > 0 || enCurso > 0 || comisiones > 0;

  factory Ganancias.desde(List<Map<String, dynamic>> pagos, List<Map<String, dynamic>> comisiones) {
    double suma(Iterable<Map<String, dynamic>> xs, String k) => xs.fold(0, (t, x) => t + ((x[k] as num?)?.toDouble() ?? 0));
    return Ganancias(
      aprobadas: suma(pagos.where((d) => d['status'] == 'aprobado'), 'pay_amount'),
      enCurso: suma(pagos.where((d) => d['status'] != 'aprobado'), 'pay_amount'),
      comisiones: suma(comisiones, 'amount'),
      mensuales: comisiones.where((c) => c['kind'] == 'mensual').length,
    );
  }
}

/// Un mensaje del equipo que no he visto (unreadMessages de admin-equipo.js).
class MensajeSinVer {
  const MensajeSinVer({required this.id, required this.autor, required this.texto, required this.paraMi, required this.creado});
  factory MensajeSinVer.desdeFila(Map<String, dynamic> f) => MensajeSinVer(
        id: f['id'] as String,
        autor: f['author_id'] as String?,
        texto: (f['body'] as String?) ?? '',
        paraMi: f['to_kind'] == 'persona',
        creado: DateTime.parse(f['created_at'] as String).toLocal(),
      );
  final String id, texto;
  final String? autor;
  final bool paraMi;
  final DateTime creado;
}
