import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../domain/solicitud.dart';

/// Mismas consultas que admin.js (viewLeads, openLead, convertLead). RLS decide lo demás.
class SolicitudesRepo {
  SolicitudesRepo(this._sb);
  final SupabaseClient _sb;

  Future<List<Map<String, dynamic>>> listar() async =>
      List<Map<String, dynamic>>.from(await _sb.from('leads').select().order('created_at', ascending: false).limit(500));

  Future<void> cambiar(String id, Map<String, Object?> campos) => _sb.from('leads').update(campos).eq('id', id);

  /// Solo admin (RLS "admin borra solicitudes").
  Future<void> eliminar(String id) => _sb.from('leads').delete().eq('id', id);

  /// `ensureClient` de admin.js: el cliente con ese correo, o uno nuevo con los datos de la solicitud.
  Future<Map<String, dynamic>> asegurarCliente(Solicitud s) async {
    final correo = s.correo.toLowerCase();
    final ya = await _sb.from('clients').select().eq('email', correo).maybeSingle();
    if (ya != null) return ya;
    return _sb
        .from('clients')
        .insert({
          'name': s.nombre,
          'email': correo,
          'phone': s.telefono,
          'city': s.ciudad,
          'lead_id': s.id,
          'notes': s.plan != null ? 'Plan: ${s.plan}' : null,
        })
        .select()
        .single();
  }
}

final solicitudesRepoProvider = Provider<SolicitudesRepo>((ref) => SolicitudesRepo(ref.watch(supabaseProvider)));

/// Las 500 solicitudes más recientes. Se vuelve a pedir cuando `leads` cambia en vivo.
final solicitudesProvider = FutureProvider<Datos<List<Solicitud>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['leads'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'solicitudes')) throw const SinPermiso();
  final repo = ref.watch(solicitudesRepoProvider);
  return conCache<List<Solicitud>>(
    ref,
    'leads',
    repo.listar,
    (crudo) => [for (final f in (crudo as List? ?? const [])) Solicitud.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
});
