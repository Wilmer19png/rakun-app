import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../domain/mensaje.dart';

class MensajesRepo {
  MensajesRepo(this._sb);
  final SupabaseClient _sb;

  Future<Map<String, Object?>> todo() async {
    final r = await Future.wait([
      _sb.from('team_messages').select('*, projects(name)').order('pinned', ascending: false).order('created_at', ascending: false).limit(80),
      _sb.from('message_reads').select('message_id, user_id'),
      _sb.from('projects').select('id, name').eq('status', 'activo').order('name', ascending: true),
    ]);
    return {'mensajes': r[0], 'leidos': r[1], 'proyectos': r[2]};
  }

  Future<void> publicar(Map<String, Object?> fila) => _sb.from('team_messages').insert(fila);
  Future<void> marcarVisto(String id, String yo) => _sb.from('message_reads').insert({'message_id': id, 'user_id': yo});
  Future<void> fijar(String id, bool v) => _sb.from('team_messages').update({'pinned': v}).eq('id', id);
  Future<void> borrar(String id) => _sb.from('team_messages').delete().eq('id', id);
}

final mensajesRepoProvider = Provider<MensajesRepo>((ref) => MensajesRepo(ref.watch(supabaseProvider)));

class DatosMensajes {
  const DatosMensajes({this.mensajes = const [], this.leidos = const {}, this.proyectos = const []});
  final List<Mensaje> mensajes;
  final Map<String, List<String>> leidos; // mensaje → quiénes lo vieron
  final List<(String, String)> proyectos; // activos, para escribir al equipo de uno
}

final mensajesProvider = FutureProvider<Datos<DatosMensajes>>((ref) async {
  ref.watch(revisionesProvider.select((r) => (r['team_messages'] ?? 0) + (r['message_reads'] ?? 0)));
  final perfil = await ref.watch(perfilProvider.future);
  if (perfil == null || !perfil.esEquipo) throw const SinPermiso();
  return conCache<DatosMensajes>(ref, 'team_messages', ref.read(mensajesRepoProvider).todo, (crudo) {
    final m = Map<String, dynamic>.from(crudo as Map? ?? const {});
    final leidos = <String, List<String>>{};
    for (final r in (m['leidos'] as List? ?? const [])) {
      (leidos[r['message_id'] as String] ??= []).add(r['user_id'] as String);
    }
    return DatosMensajes(
      mensajes: [for (final f in (m['mensajes'] as List? ?? const [])) Mensaje.desdeFila(Map<String, dynamic>.from(f as Map))],
      leidos: leidos,
      proyectos: [for (final p in (m['proyectos'] as List? ?? const [])) (p['id'] as String, (p['name'] as String?) ?? '—')],
    );
  });
});
