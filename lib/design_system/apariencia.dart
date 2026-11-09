import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias del teléfono (se inyectan en main.dart).
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider sin inicializar'));

/// Más → Cuenta → Apariencia. Oscuro es el tema por defecto (decisión de Wilmer).
enum Apariencia {
  oscuro('oscuro', ThemeMode.dark),
  claro('claro', ThemeMode.light),
  telefono('sistema', ThemeMode.system);

  const Apariencia(this.clave, this.modo);
  final String clave; // misma clave que el prototipo (rk-tema)
  final ThemeMode modo;
}

class AparienciaNotifier extends Notifier<Apariencia> {
  static const _clave = 'rk-tema';

  @override
  Apariencia build() {
    final guardada = ref.watch(prefsProvider).getString(_clave);
    return Apariencia.values.firstWhere((a) => a.clave == guardada, orElse: () => Apariencia.oscuro);
  }

  Future<void> elegir(Apariencia a) async {
    state = a;
    await ref.read(prefsProvider).setString(_clave, a.clave);
  }
}

final aparienciaProvider = NotifierProvider<AparienciaNotifier, Apariencia>(AparienciaNotifier.new);
