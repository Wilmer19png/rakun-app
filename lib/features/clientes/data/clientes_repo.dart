import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../design_system/tokens.dart';
import '../domain/cliente.dart';

/// Mismas consultas que admin.js (viewClients, newClientForm). RLS decide lo demás.
class ClientesRepo {
  ClientesRepo(this._sb);
  final SupabaseClient _sb;

  Future<List<Map<String, dynamic>>> listar() async =>
      List<Map<String, dynamic>>.from(await _sb.from('clients').select().order('created_at', ascending: false));

  /// Qué mundos tiene cada cliente según sus proyectos (para las marcas de color de la lista).
  Future<List<Map<String, dynamic>>> mundos() async => List<Map<String, dynamic>>.from(await _sb.from('projects').select('client_id, world'));

  /// Igual que la web: correo en minúsculas y vacíos como null. Si el correo ya existe, avisa.
  Future<Cliente> crear({required String nombre, String? empresa, required String correo, String? telefono, String? ciudad}) async {
    String? o(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    try {
      final fila = await _sb
          .from('clients')
          .insert({'name': nombre.trim(), 'company': o(empresa), 'email': correo.trim().toLowerCase(), 'phone': o(telefono), 'city': o(ciudad)})
          .select()
          .single();
      return Cliente.desdeFila(fila);
    } on PostgrestException catch (e) {
      if (RegExp('duplicate|unique', caseSensitive: false).hasMatch(e.message)) throw const CorreoRepetido();
      rethrow;
    }
  }
}

class CorreoRepetido implements Exception {
  const CorreoRepetido();
  @override
  String toString() => 'Ya hay un cliente con ese correo.';
}

final clientesRepoProvider = Provider<ClientesRepo>((ref) => ClientesRepo(ref.watch(supabaseProvider)));

/// Todos los clientes (la web no pone límite). Se vuelve a pedir cuando `clients` cambia en vivo.
final clientesProvider = FutureProvider<Datos<List<Cliente>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['clients'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'clientes')) throw const SinPermiso();
  final repo = ref.watch(clientesRepoProvider);
  return conCache<List<Cliente>>(
    ref,
    'clients',
    repo.listar,
    (crudo) => [for (final f in (crudo as List? ?? const [])) Cliente.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
});

/// cliente → mundos de sus proyectos. Solo si quien mira ve Proyectos; si no, vacío (no es un error).
final mundosPorClienteProvider = FutureProvider<Map<String, Set<Mundo>>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['projects'] ?? 0));
  final perfil = await ref.watch(perfilProvider.future);
  if (!puede(perfil, 'proyectos')) return const {};
  final datos = await conCache<Map<String, Set<Mundo>>>(ref, 'projects-mundos', ref.watch(clientesRepoProvider).mundos, mundosDe);
  return datos.valor;
});

Map<String, Set<Mundo>> mundosDe(Object? crudo) {
  final r = <String, Set<Mundo>>{};
  for (final f in (crudo as List? ?? const [])) {
    final m = Mundo.desde((f as Map)['world'] as String?);
    final id = f['client_id'] as String?;
    if (m != null && id != null) (r[id] ??= {}).add(m);
  }
  return r;
}
