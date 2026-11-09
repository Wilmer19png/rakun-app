import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/datos/proyectos_web.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/texto.dart';
import '../domain/proyecto.dart';

/// Mismas consultas que admin-proyectos.js y admin-entregables.js. RLS decide lo demás.
class ProyectosRepo {
  ProyectosRepo(this._sb);
  final SupabaseClient _sb;

  Future<List<Map<String, dynamic>>> listar() async =>
      List<Map<String, dynamic>>.from(await _sb.from('projects').select('*, clients(name)').order('created_at', ascending: false));

  /// Para la lista: cuántos entregables vencidos tiene cada proyecto (solo lo que falta aprobar).
  Future<List<Map<String, dynamic>>> pendientes() async =>
      List<Map<String, dynamic>>.from(await _sb.from('deliverables').select('project_id, due_at, status').neq('status', 'aprobado'));

  /// Un proyecto con su cotización. Como la web: si la relación con `quotes` falla, se pide sin ella.
  Future<Map<String, dynamic>> uno(String id) async {
    try {
      return await _sb.from('projects').select('*, clients(name), quotes(number, token)').eq('id', id).single();
    } on PostgrestException {
      return _sb.from('projects').select('*, clients(name)').eq('id', id).single();
    }
  }

  Future<void> cambiar(String id, Map<String, Object?> campos) => _sb.from('projects').update(campos).eq('id', id);

  /// newProject de la web: arranca en la primera etapa de su mundo.
  Future<String> crear({
    required String clienteId,
    required String mundo,
    required String nombre,
    String? plan,
    DateTime? inicio,
    DateTime? fin,
    String? aCargo,
  }) async {
    String? dia(DateTime? d) => d == null ? null : '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';
    final fila = await _sb
        .from('projects')
        .insert({
          'client_id': clienteId,
          'world': mundo,
          'name': nombre.trim(),
          'plan': (plan ?? '').trim().isEmpty ? null : plan!.trim(),
          'start_date': dia(inicio),
          'end_date': dia(fin),
          'owner_id': aCargo,
          'stage': etapasWeb[mundo]?.firstOrNull, // STAGES[world][0] de la web
        })
        .select('id')
        .single();
    return fila['id'] as String;
  }

  Future<List<Map<String, dynamic>>> entregables(String proyectoId) async => List<Map<String, dynamic>>.from(
        await _sb.from('deliverables').select().eq('project_id', proyectoId).order('due_at', ascending: true, nullsFirst: false).order('sort'),
      );

  Future<void> cambiarEntregable(String id, Map<String, Object?> campos) => _sb.from('deliverables').update(campos).eq('id', id);

  Future<void> crearEntregable(Map<String, Object?> fila) => _sb.from('deliverables').insert(fila);

  Future<void> quitarEntregable(String id) => _sb.from('deliverables').delete().eq('id', id);

  Future<void> cargarPlantilla(List<Map<String, Object?>> filas) => _sb.from('deliverables').insert(filas);

  /// `openDelivery` de la web: enlace normal, o archivo de la carpeta privada «entregas» (enlace firmado de 1 h).
  Future<String?> enlaceDeEntrega(String url) async {
    if (url.startsWith('storage:')) return _sb.storage.from('entregas').createSignedUrl(url.substring(8), 3600);
    final s = enlaceSeguro(url);
    return s.isEmpty ? null : s;
  }
}

final proyectosRepoProvider = Provider<ProyectosRepo>((ref) => ProyectosRepo(ref.watch(supabaseProvider)));

/// Todos los proyectos. Se vuelve a pedir cuando `projects` cambia en vivo.
final proyectosProvider = FutureProvider<Datos<List<Proyecto>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['projects'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'proyectos')) throw const SinPermiso();
  return conCache<List<Proyecto>>(
    ref,
    'projects',
    ref.watch(proyectosRepoProvider).listar,
    (crudo) => [for (final f in (crudo as List? ?? const [])) Proyecto.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
});

/// proyecto → entregables sin aprobar (para "N vencidos" en la lista).
final pendientesPorProyectoProvider = FutureProvider<Map<String, List<Entregable>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['deliverables'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'proyectos')) return const {};
  final d = await conCache<Map<String, List<Entregable>>>(ref, 'deliverables-pendientes', ref.watch(proyectosRepoProvider).pendientes, (crudo) {
    final r = <String, List<Entregable>>{};
    for (final f in (crudo as List? ?? const [])) {
      final m = Map<String, dynamic>.from(f as Map);
      final e = Entregable.desdeFila({'id': '', 'title': '', ...m});
      (r[e.proyectoId] ??= []).add(e);
    }
    return r;
  });
  return d.valor;
});

final proyectoProvider = FutureProvider.family<Datos<Proyecto>, String>((ref, id) async {
  ref.watch(revisionesProvider.select((r) => r['projects'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'proyectos')) throw const SinPermiso();
  return conCache<Proyecto>(ref, 'project:$id', () => ref.read(proyectosRepoProvider).uno(id), (crudo) => Proyecto.desdeFila(Map<String, dynamic>.from(crudo! as Map)));
});

final entregablesProvider = FutureProvider.family<Datos<List<Entregable>>, String>((ref, proyectoId) async {
  ref.watch(revisionesProvider.select((r) => r['deliverables'] ?? 0));
  return conCache<List<Entregable>>(
    ref,
    'deliverables:$proyectoId',
    () => ref.read(proyectosRepoProvider).entregables(proyectoId),
    (crudo) => [for (final f in (crudo as List? ?? const [])) Entregable.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
});

/// Clientes para elegir al crear un proyecto (como la web: id y nombre, por nombre).
final clientesParaProyectoProvider = FutureProvider<List<(String, String)>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['clients'] ?? 0));
  final sb = ref.watch(supabaseProvider);
  final filas = await sb.from('clients').select('id, name').order('name');
  return [for (final f in filas) (f['id'] as String, (f['name'] as String?) ?? '—')];
});
