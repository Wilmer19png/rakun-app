/// Caché de lectura para ver datos sin conexión (Fase 5). En v1 NO hay escrituras en cola:
/// sin conexión se ve lo último guardado y los botones de escribir se desactivan.
/// Las secciones de la Fase 6 guardan aquí cada lista que traen de Supabase.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design_system/apariencia.dart';

class Guardado<T> {
  const Guardado(this.datos, this.cuando);
  final T datos;
  final DateTime cuando;
}

class CacheLectura {
  CacheLectura(this._prefs);
  final SharedPreferences _prefs;
  static const _prefijo = 'rk-cache:';

  /// [usuario] separa la caché de cada persona (lo que ve una no lo ve otra en el mismo teléfono).
  Future<void> guardar(String usuario, String clave, Object datos) =>
      _prefs.setString('$_prefijo$usuario:$clave', jsonEncode({'t': DateTime.now().toIso8601String(), 'd': datos}));

  Guardado<Object?>? leer(String usuario, String clave) {
    final raw = _prefs.getString('$_prefijo$usuario:$clave');
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return Guardado(m['d'], DateTime.parse(m['t'] as String));
    } catch (_) {
      return null; // caché dañada: se ignora
    }
  }

  /// Al salir se borra todo lo guardado (los datos no se quedan en el teléfono de otra persona).
  Future<void> borrarTodo() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith(_prefijo)).toList()) {
      await _prefs.remove(k);
    }
  }
}

final cacheLecturaProvider = Provider<CacheLectura>((ref) => CacheLectura(ref.watch(prefsProvider)));
