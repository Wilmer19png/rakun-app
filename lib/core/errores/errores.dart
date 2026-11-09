/// Mensajes de error de Supabase en español claro.
/// Porta `errorText` de rakun-web/app/supa.js con los mismos textos.
String textoDeError(Object? error) {
  final m = error == null ? '' : _mensaje(error);
  bool has(String patron) => RegExp(patron, caseSensitive: false).hasMatch(m);

  if (has(r'invalid login credentials')) return 'El correo o la contraseña no coinciden.';
  if (has(r'email not confirmed')) return 'Aún no has activado tu cuenta. Revisa el enlace que te enviamos.';
  if (has(r'rate limit|too many')) return 'Demasiados intentos. Espera unos minutos y vuelve a intentar.';
  if (has(r'password should be at least|weak')) return 'La contraseña es muy corta: usa al menos 8 caracteres.';
  if (has(r'same.*password|different from the old')) return 'Usa una contraseña distinta a la anterior.';
  if (has(r'failed host lookup|socketexception|network|failed to fetch|connection')) {
    return 'No hay conexión. Revisa tu internet y vuelve a intentar.';
  }
  if (has(r'configurad')) return 'El acceso aún no está activo. Escríbenos y te ayudamos.';
  return m.isEmpty ? 'Algo salió mal. Vuelve a intentar.' : m;
}

String _mensaje(Object e) {
  try {
    // AuthException, PostgrestException y StorageException tienen `message`.
    final dynamic d = e;
    final msg = d.message;
    if (msg is String) return msg;
  } catch (_) {
    // no tiene `message`
  }
  return e.toString();
}
