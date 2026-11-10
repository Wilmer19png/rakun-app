import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/fechas.dart';
import '../domain/pieza.dart';

/// Consultas de admin-parrilla.js.
class ParrillaRepo {
  ParrillaRepo(this._sb);
  final SupabaseClient _sb;

  /// Proyectos de Redes (mundo marca), el más reciente primero.
  Future<List<Map<String, dynamic>>> proyectos() async => List<Map<String, dynamic>>.from(
      await _sb.from('projects').select('id, name, client_id, world, clients(name)').eq('world', 'marca').order('created_at', ascending: false));

  /// Piezas de un proyecto en un mes.
  Future<List<Map<String, dynamic>>> piezas(String proyecto, DateTime mes) async => List<Map<String, dynamic>>.from(await _sb
      .from('posts')
      .select()
      .eq('project_id', proyecto)
      .gte('publish_at', mes.toUtc().toIso8601String())
      .lt('publish_at', sumarMeses(mes, 1).toUtc().toIso8601String())
      .order('publish_at', ascending: true));

  Future<void> guardar(String? id, Map<String, Object?> fila) => id == null ? _sb.from('posts').insert(fila) : _sb.from('posts').update(fila).eq('id', id);
  Future<void> eliminar(String id) => _sb.from('posts').delete().eq('id', id);

  /// sendToClient: lo "listo" pasa a "por aprobar".
  Future<void> enviarAlCliente(List<String> ids) => _sb.from('posts').update({'status': 'por_aprobar'}).inFilter('id', ids);

  Future<void> duplicar(List<Map<String, Object?>> filas) => _sb.from('posts').insert(filas);
}

final parrillaRepoProvider = Provider<ParrillaRepo>((ref) => ParrillaRepo(ref.watch(supabaseProvider)));

typedef ProyectoRedes = ({String id, String nombre, String clienteId, String cliente});

final proyectosRedesProvider = FutureProvider<Datos<List<ProyectoRedes>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => (r['projects'] ?? 0) + (r['clients'] ?? 0)));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'parrillas')) throw const SinPermiso();
  return conCache<List<ProyectoRedes>>(ref, 'parrilla-proyectos', ref.read(parrillaRepoProvider).proyectos, (crudo) => [
        for (final f in (crudo as List? ?? const []))
          (
            id: f['id'] as String,
            nombre: (f['name'] as String?) ?? '—',
            clienteId: f['client_id'] as String,
            cliente: ((f['clients'] as Map?)?['name'] as String?) ?? '—',
          ),
      ]);
});

/// Proyecto y mes elegidos (proyecto null = el primero de la lista).
class SeleccionParrilla {
  const SeleccionParrilla({this.proyecto, required this.mes});
  final String? proyecto;
  final DateTime mes;
}

final seleccionParrillaProvider = NotifierProvider<_Seleccion, SeleccionParrilla>(_Seleccion.new);

class _Seleccion extends Notifier<SeleccionParrilla> {
  @override
  SeleccionParrilla build() => SeleccionParrilla(mes: inicioDeMes(reloj()));
  void proyecto(String id) => state = SeleccionParrilla(proyecto: id, mes: state.mes);
  void mes(DateTime m) => state = SeleccionParrilla(proyecto: state.proyecto, mes: inicioDeMes(m));
}

final piezasProvider = FutureProvider.family<Datos<List<Pieza>>, (String, DateTime)>((ref, clave) async {
  ref.watch(revisionesProvider.select((r) => r['posts'] ?? 0));
  final (proyecto, mes) = clave;
  return conCache<List<Pieza>>(
    ref,
    'posts:$proyecto:${mes.year}-${mes.month}',
    () => ref.read(parrillaRepoProvider).piezas(proyecto, mes),
    (crudo) => [for (final f in (crudo as List? ?? const [])) Pieza.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
});
