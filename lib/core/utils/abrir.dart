import 'package:url_launcher/url_launcher.dart';

import 'texto.dart';

/// Abrir fuera de la app: llamar, WhatsApp, correo, Maps, enlaces. Devuelve false si no se pudo.
abstract final class Abrir {
  static Future<bool> llamar(String telefono) {
    final d = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    return d.isEmpty ? Future.value(false) : launchUrl(Uri(scheme: 'tel', path: d));
  }

  /// wa.me con mensaje listo (como admin.js).
  static Future<bool> whatsapp(String telefono, {String? texto}) {
    final n = numeroWhatsApp(telefono);
    if (n.isEmpty) return Future.value(false);
    return launchUrl(
      Uri.https('wa.me', '/$n', texto == null ? null : {'text': texto}),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> correo(String a, {String? asunto, String? cuerpo}) => launchUrl(Uri(
        scheme: 'mailto',
        path: a,
        query: [
          if (asunto != null) 'subject=${Uri.encodeComponent(asunto)}',
          if (cuerpo != null) 'body=${Uri.encodeComponent(cuerpo)}',
        ].join('&'),
      ));

  static Future<bool> enlace(String raw) {
    final s = enlaceSeguro(raw);
    return s.isEmpty ? Future.value(false) : launchUrl(Uri.parse(s), mode: LaunchMode.externalApplication);
  }
}
