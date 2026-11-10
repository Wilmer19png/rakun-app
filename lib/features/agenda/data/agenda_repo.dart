import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/fechas.dart';
import '../domain/agenda.dart';

/// Consultas de admin-agenda.js.
class AgendaRepo {
  AgendaRepo(this._sb);
  final SupabaseClient _sb;

  /// Próximas (desde ahora, la más cercana primero) o anteriores (la más reciente primero), 200.
  Future<List<Map<String, dynamic>>> grabaciones({required bool anteriores}) async {
    final ahora = reloj().toUtc().toIso8601String();
    final q = _sb.from('shoots').select();
    final f = anteriores ? q.lt('starts_at', ahora) : q.gte('starts_at', ahora);
    return List<Map<String, dynamic>>.from(await f.order('starts_at', ascending: !anteriores).limit(200));
  }

  /// Las de un día (para «Agenda de hoy»), aunque ya hayan empezado.
  Future<List<Map<String, dynamic>>> grabacionesDelDia(DateTime dia) async {
    final desde = DateTime(dia.year, dia.month, dia.day);
    final hasta = desde.add(const Duration(days: 1));
    return List<Map<String, dynamic>>.from(await _sb
        .from('shoots')
        .select()
        .gte('starts_at', desde.toUtc().toIso8601String())
        .lt('starts_at', hasta.toUtc().toIso8601String())
        .neq('status', 'cancelada')
        .order('starts_at', ascending: true));
  }

  Future<Map<String, dynamic>> grabacion(String id) async => Map<String, dynamic>.from(await _sb.from('shoots').select().eq('id', id).single());

  Future<List<Map<String, dynamic>>> reuniones() async =>
      List<Map<String, dynamic>>.from(await _sb.from('meetings').select().order('starts_at', ascending: true, nullsFirst: true).limit(300));

  /// Clientes (id, nombre, teléfono) y proyectos no terminados, para nombres y formularios.
  Future<Map<String, Object?>> referencias() async {
    final r = await Future.wait([
      _sb.from('clients').select('id, name, phone').order('name', ascending: true),
      _sb.from('projects').select('id, name, client_id').neq('status', 'terminado').order('created_at', ascending: false),
    ]);
    return {'clientes': r[0], 'proyectos': r[1]};
  }

  Future<List<Map<String, dynamic>>> lugaresUsados() async => List<Map<String, dynamic>>.from(
      await _sb.from('shoots').select('location, address').not('location', 'is', null).order('starts_at', ascending: false).limit(60));

  Future<void> guardarGrabacion(String? id, Map<String, Object?> fila) =>
      id == null ? _sb.from('shoots').insert(fila) : _sb.from('shoots').update(fila).eq('id', id);
  Future<void> eliminarGrabacion(String id) => _sb.from('shoots').delete().eq('id', id);

  Future<void> guardarReunion(String? id, Map<String, Object?> fila) =>
      id == null ? _sb.from('meetings').insert(fila) : _sb.from('meetings').update(fila).eq('id', id);
  Future<void> eliminarReunion(String id) => _sb.from('meetings').delete().eq('id', id);
}

final agendaRepoProvider = Provider<AgendaRepo>((ref) => AgendaRepo(ref.watch(supabaseProvider)));

typedef ClienteRef = ({String id, String nombre, String? telefono});
typedef ProyectoRef = ({String id, String nombre, String clienteId});

class Referencias {
  const Referencias({this.clientes = const [], this.proyectos = const []});
  final List<ClienteRef> clientes;
  final List<ProyectoRef> proyectos;
  ClienteRef? cliente(String? id) => clientes.where((c) => c.id == id).firstOrNull;
  ProyectoRef? proyecto(String? id) => proyectos.where((p) => p.id == id).firstOrNull;
}

final referenciasAgendaProvider = FutureProvider<Referencias>((ref) async {
  ref.watch(revisionesProvider.select((r) => (r['clients'] ?? 0) + (r['projects'] ?? 0)));
  final d = await conCache<Referencias>(ref, 'agenda-referencias', ref.read(agendaRepoProvider).referencias, (crudo) {
    final m = Map<String, dynamic>.from(crudo as Map? ?? const {});
    return Referencias(
      clientes: [
        for (final f in (m['clientes'] as List? ?? const []))
          (id: f['id'] as String, nombre: (f['name'] as String?) ?? '—', telefono: f['phone'] as String?),
      ],
      proyectos: [
        for (final f in (m['proyectos'] as List? ?? const []))
          (id: f['id'] as String, nombre: (f['name'] as String?) ?? '—', clienteId: f['client_id'] as String),
      ],
    );
  });
  return d.valor;
});

/// Ver anteriores (el reloj de arriba) en lugar de próximas.
final verAnterioresProvider = NotifierProvider<_Anteriores, bool>(_Anteriores.new);

class _Anteriores extends Notifier<bool> {
  @override
  bool build() => false;
  void poner(bool v) => state = v;
}

/// Grabaciones que puedo ver: con permiso, todas; si no, solo donde voy en el equipo.
final grabacionesProvider = FutureProvider<Datos<List<Grabacion>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['shoots'] ?? 0));
  final anteriores = ref.watch(verAnterioresProvider);
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !(puede(perfil, 'grabaciones') || puede(perfil, 'reuniones'))) throw const SinPermiso();
  final d = await conCache<List<Grabacion>>(
    ref,
    anteriores ? 'shoots-anteriores' : 'shoots-proximas',
    () => ref.read(agendaRepoProvider).grabaciones(anteriores: anteriores),
    (crudo) => [for (final f in (crudo as List? ?? const [])) Grabacion.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
  final todas = puede(perfil, 'grabaciones') ? d.valor : d.valor.where((g) => g.equipo.contains(perfil.id)).toList();
  return Datos(todas, guardadoA: d.guardadoA);
});

final reunionesProvider = FutureProvider<Datos<List<Reunion>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['meetings'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !puede(perfil, 'reuniones')) return const Datos(<Reunion>[]);
  return conCache<List<Reunion>>(
    ref,
    'meetings',
    ref.read(agendaRepoProvider).reuniones,
    (crudo) => [for (final f in (crudo as List? ?? const [])) Reunion.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
});

final grabacionProvider = FutureProvider.family<Datos<Grabacion>, String>((ref, id) async {
  ref.watch(revisionesProvider.select((r) => r['shoots'] ?? 0));
  return conCache<Grabacion>(ref, 'shoot:$id', () => ref.read(agendaRepoProvider).grabacion(id),
      (crudo) => Grabacion.desdeFila(Map<String, dynamic>.from(crudo! as Map)));
});

/// «Agenda de hoy» en Hoy: grabaciones y reuniones de hoy (sin canceladas) + reuniones pedidas.
final agendaDeHoyProvider = FutureProvider<({List<Evento> hoy, List<Reunion> pedidas})>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['shoots'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !(puede(perfil, 'grabaciones') || puede(perfil, 'reuniones'))) return (hoy: const <Evento>[], pedidas: const <Reunion>[]);
  final ahora = reloj();
  final d = await conCache<List<Grabacion>>(
    ref,
    'shoots-hoy',
    () => ref.read(agendaRepoProvider).grabacionesDelDia(ahora),
    (crudo) => [for (final f in (crudo as List? ?? const [])) Grabacion.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
  final gs = puede(perfil, 'grabaciones') ? d.valor : d.valor.where((g) => g.equipo.contains(perfil.id)).toList();
  final rs = (await ref.watch(reunionesProvider.future)).valor;
  bool esHoy(DateTime? x) => x != null && x.year == ahora.year && x.month == ahora.month && x.day == ahora.day;
  final hoy = [
    ...gs.map(Evento.grabacion),
    ...rs.where((m) => !m.pedida && m.estado != 'cancelada' && esHoy(m.inicio)).map(Evento.reunion),
  ]..sort((a, b) => a.inicio!.compareTo(b.inicio!));
  return (hoy: hoy, pedidas: rs.where((m) => m.pedida).toList());
});

/// Reuniones pedidas por clientes (el aviso de la barra, setMeetBadge de la web).
final reunionesPedidasProvider = FutureProvider<int>((ref) async {
  final r = await ref.watch(reunionesProvider.future);
  return r.valor.where((m) => m.pedida).length;
});
