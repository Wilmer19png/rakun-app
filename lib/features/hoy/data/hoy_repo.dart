import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../proyectos/domain/proyecto.dart';
import '../domain/tarea.dart';

/// Lecturas y escrituras de 00 · Hoy, con las mismas consultas que admin-entregables.js.
class HoyRepo {
  HoyRepo(this._sb);
  final SupabaseClient _sb;

  static const _conProyecto = '*, projects(id, name, world, clients(name))';
  String _mias(String yo) => 'assignee_id.eq.$yo,and(reviewer_id.eq.$yo,status.eq.en_revision)';

  /// Lo pendiente: lo mío sin aprobar + lo que me toca revisar, por fecha límite.
  Future<List<Map<String, dynamic>>> pendientes(String yo) async => List<Map<String, dynamic>>.from(await _sb
      .from('deliverables')
      .select(_conProyecto)
      .or(_mias(yo))
      .neq('status', 'aprobado')
      .order('due_at', ascending: true, nullsFirst: false));

  /// "Terminados": lo último aprobado (30).
  Future<List<Map<String, dynamic>>> terminados(String yo) async => List<Map<String, dynamic>>.from(await _sb
      .from('deliverables')
      .select(_conProyecto)
      .or(_mias(yo))
      .eq('status', 'aprobado')
      .order('delivered_at', ascending: false)
      .limit(30));

  Future<Map<String, dynamic>> una(String id) async =>
      Map<String, dynamic>.from(await _sb.from('deliverables').select(_conProyecto).eq('id', id).single());

  Future<void> cambiarEstado(String id, EstadoEntregable e) => _sb.from('deliverables').update({'status': e.clave}).eq('id', id);

  /// uploadDelivery: sube a la carpeta privada «entregas» y devuelve "storage:ruta".
  Future<String> subir(Entregable d, File archivo, String nombre) async {
    final ruta = rutaEntrega(d, nombre, ms: DateTime.now().millisecondsSinceEpoch);
    await _sb.storage.from('entregas').upload(ruta, archivo, fileOptions: const FileOptions(upsert: false));
    return 'storage:$ruta';
  }

  Future<void> entregar(Entregable d, {required String yo, required String url, String? nota}) => _sb.from('deliverables').update({
        'delivery_url': url,
        'delivery_note': (nota ?? '').trim().isEmpty ? null : nota!.trim(),
        'delivered_at': DateTime.now().toUtc().toIso8601String(),
        'status': estadoAlEntregar(d, yo: yo).clave,
      }).eq('id', d.id);

  Future<void> aprobar(String id) => _sb.from('deliverables').update({'status': 'aprobado'}).eq('id', id);

  /// RPC de fase15.sql: suma round_pay al pago de quien hizo la tarea.
  Future<void> rondaExtra(String id) => _sb.rpc('extra_round', params: {'d': id});

  Future<void> devolver(String id, String porque) =>
      _sb.from('deliverables').update({'status': 'en_curso', 'delivery_note': notaDevolucion(porque)}).eq('id', id);

  Future<List<Map<String, dynamic>>> mensajesSinVer(String yo) async {
    final r = await Future.wait([
      _sb.from('team_messages').select('id, author_id, body, to_kind, created_at, pinned').neq('author_id', yo).order('created_at', ascending: false).limit(30),
      _sb.from('message_reads').select('message_id').eq('user_id', yo),
    ]);
    final vistos = {for (final x in r[1]) x['message_id']};
    return [for (final m in r[0]) if (!vistos.contains(m['id'])) Map<String, dynamic>.from(m)];
  }

  Future<void> marcarVisto(String mensaje, String yo) => _sb.from('message_reads').insert({'message_id': mensaje, 'user_id': yo});

  Future<Map<String, Object?>> ganancias(String yo) async {
    final r = await Future.wait([
      _sb.from('deliverables').select('pay_amount, status').eq('assignee_id', yo).not('pay_amount', 'is', null).isFilter('paid_at', null),
      _sb.from('commissions').select('amount, kind, period, created_at').eq('manager_id', yo).eq('status', 'por_pagar'),
    ]);
    return {'pagos': r[0], 'comisiones': r[1]};
  }
}

final hoyRepoProvider = Provider<HoyRepo>((ref) => HoyRepo(ref.watch(supabaseProvider)));

/// false = pendientes, true = terminados.
final verTerminadosProvider = NotifierProvider<_Interruptor, bool>(_Interruptor.new);

class _Interruptor extends Notifier<bool> {
  @override
  bool build() => false;
  void poner(bool v) => state = v;
}

final tareasProvider = FutureProvider<Datos<List<Tarea>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['deliverables'] ?? 0));
  final terminados = ref.watch(verTerminadosProvider);
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !puede(perfil, 'pendientes')) throw const SinPermiso();
  final repo = ref.watch(hoyRepoProvider);
  return conCache<List<Tarea>>(
    ref,
    terminados ? 'hoy-terminados' : 'hoy-pendientes',
    () => terminados ? repo.terminados(perfil.id) : repo.pendientes(perfil.id),
    (crudo) => [for (final f in (crudo as List? ?? const [])) Tarea.desdeFila(Map<String, dynamic>.from(f as Map), yo: perfil.id)],
  );
});

/// Cuántos pendientes tengo (el aviso de "Hoy" en la barra), sin depender del interruptor.
final cuantosPendientesProvider = FutureProvider<int>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['deliverables'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !puede(perfil, 'pendientes')) return 0;
  final d = await conCache<int>(ref, 'hoy-pendientes', () => ref.read(hoyRepoProvider).pendientes(perfil.id), (crudo) => (crudo as List? ?? const []).length);
  return d.valor;
});

final tareaProvider = FutureProvider.family<Datos<Tarea>, String>((ref, id) async {
  ref.watch(revisionesProvider.select((r) => r['deliverables'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null) throw const SinPermiso();
  return conCache<Tarea>(ref, 'deliverable:$id', () => ref.read(hoyRepoProvider).una(id),
      (crudo) => Tarea.desdeFila(Map<String, dynamic>.from(crudo! as Map), yo: perfil.id));
});

final mensajesSinVerProvider = FutureProvider<List<MensajeSinVer>>((ref) async {
  ref.watch(revisionesProvider.select((r) => (r['team_messages'] ?? 0) + (r['message_reads'] ?? 0)));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !perfil.esEquipo) return const [];
  try {
    final filas = await ref.read(hoyRepoProvider).mensajesSinVer(perfil.id);
    return [for (final f in filas) MensajeSinVer.desdeFila(f)];
  } catch (_) {
    return const []; // como la web: si falla, no se muestran
  }
});

final gananciasProvider = FutureProvider<Ganancias>((ref) async {
  ref.watch(revisionesProvider.select((r) => (r['deliverables'] ?? 0) + (r['commissions'] ?? 0)));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null) return const Ganancias();
  final d = await conCache<Ganancias>(
    ref,
    'hoy-ganancias',
    () => ref.read(hoyRepoProvider).ganancias(perfil.id),
    (crudo) {
      final m = Map<String, dynamic>.from(crudo as Map? ?? const {});
      List<Map<String, dynamic>> lista(Object? x) => [for (final f in (x as List? ?? const [])) Map<String, dynamic>.from(f as Map)];
      return Ganancias.desde(lista(m['pagos']), lista(m['comisiones']));
    },
  );
  return d.valor;
});
