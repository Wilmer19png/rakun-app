import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../permisos/permisos.dart';

/// Cliente de Supabase (se inicializa en main.dart con la llave publicable).
final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Sesión actual; se mantiene entre aperturas (supabase_flutter la guarda en el teléfono).
final sesionProvider = StreamProvider<Session?>((ref) async* {
  final auth = ref.watch(supabaseProvider).auth;
  yield auth.currentSession;
  await for (final cambio in auth.onAuthStateChange) {
    yield cambio.session;
  }
});

/// Perfil de quien tiene sesión (tabla profiles). null = sin sesión.
/// Se vuelve a pedir solo cuando cambia la persona, no en cada renovación del token.
final perfilProvider = FutureProvider<Perfil?>((ref) async {
  final usuario = ref.watch(sesionProvider.select((s) => s.value?.user));
  final id = usuario?.id;
  if (id == null) return null;
  final fila = await ref.read(supabaseProvider).from('profiles').select().eq('id', id).single();
  return Perfil.desdeFila(fila, emailSesion: usuario?.email);
});

/// Acciones de cuenta (las mismas que login.js, cuenta.js y password.js de la web).
class Cuenta {
  Cuenta(this._sb);
  final SupabaseClient _sb;

  Future<void> entrar(String correo, String clave) =>
      _sb.auth.signInWithPassword(email: correo.trim().toLowerCase(), password: clave);

  /// El enlace abre cuenta.html en la web pública (no se toca la configuración de Auth).
  Future<void> recuperar(String correo) =>
      _sb.auth.resetPasswordForEmail(correo.trim().toLowerCase(), redirectTo: Env.cuentaUrl);

  Future<void> cambiarClave(String nueva) => _sb.auth.updateUser(UserAttributes(password: nueva));

  Future<void> salir() => _sb.auth.signOut();
}

final cuentaProvider = Provider<Cuenta>((ref) => Cuenta(ref.watch(supabaseProvider)));
