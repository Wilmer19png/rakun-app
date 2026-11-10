import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../permisos/permisos.dart';
import '../sync/datos.dart';
import '../sync/en_vivo.dart';
import 'sesion.dart';

/// Personas del equipo (admin y equipo), como `staff` en admin.js: para "A cargo", "Lo revisa", etc.
final equipoProvider = FutureProvider<List<Perfil>>((ref) async {
  ref.watch(revisionesProvider.select((r) => r['profiles'] ?? 0));
  final sb = ref.watch(supabaseProvider);
  final d = await conCache<List<Perfil>>(
    ref,
    'equipo',
    () => sb.from('profiles').select('id, full_name, email, role, area, color, perms').inFilter('role', ['admin', 'equipo']).order('full_name', ascending: true),
    (crudo) => [for (final f in (crudo as List? ?? const [])) Perfil.desdeFila(Map<String, dynamic>.from(f as Map))],
  );
  return d.valor;
});
