/// Configuración que llega al compilar con `--dart-define-from-file=env.json`.
/// `env.json` NO se sube a Git; el modelo está en `env.example.json`.
/// La llave es la **publicable** (la misma de la web). Nunca la service_role.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Página pública de la web donde terminan los enlaces de invitación y de
  /// "olvidé mi contraseña" (igual que `accountUrl()` en rakun-web/app/supa.js).
  static const cuentaUrl = String.fromEnvironment(
    'CUENTA_URL',
    defaultValue: 'https://rakundesigns.netlify.app/cuenta.html',
  );
  static const webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://rakundesigns.netlify.app',
  );

  /// Lo que falta para poder conectar (vacío = todo bien).
  static List<String> faltantes() => [
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabaseKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      ];

  /// Defensa extra: si alguien pone una llave secreta, la app no arranca.
  static bool get llaveSegura =>
      !supabaseKey.startsWith('sb_secret_') && !supabaseKey.contains('service_role');
}
