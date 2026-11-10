/// Datos con caché de lectura (Fase 5): se piden a Supabase; si falla (sin conexión),
/// se muestra lo último guardado y se dice desde cuándo. En v1 no hay escrituras en cola.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../supabase/sesion.dart';
import 'cache_lectura.dart';

class Datos<T> {
  const Datos(this.valor, {this.guardadoA});
  final T valor;

  /// Si no es null, el valor viene de la caché (sin conexión) y es de esa hora.
  final DateTime? guardadoA;
  bool get desdeCache => guardadoA != null;
}

/// La sección no está en los permisos de quien mira (lo dice la pantalla, no es un error).
class SinPermiso implements Exception {
  const SinPermiso();
}

Future<Datos<T>> conCache<T>(
  Ref ref,
  String clave,
  Future<Object?> Function() pedir,
  T Function(Object? crudo) leer,
) async {
  final cache = ref.read(cacheLecturaProvider);
  final uid = ref.read(sesionProvider).value?.user.id ?? 'sin-sesion';
  try {
    final crudo = await pedir();
    await cache.guardar(uid, clave, crudo ?? const []);
    return Datos(leer(crudo));
  } on PostgrestException {
    rethrow; // la base respondió (p. ej. el registro ya no existe): no es falta de conexión
  } catch (e) {
    final g = cache.leer(uid, clave);
    if (g == null) rethrow;
    return Datos(leer(g.datos), guardadoA: g.cuando);
  }
}
