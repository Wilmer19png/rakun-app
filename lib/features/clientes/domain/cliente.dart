/// Una fila de `clients` (schema.sql de la web).
class Cliente {
  const Cliente({
    required this.id,
    required this.creado,
    required this.nombre,
    required this.correo,
    this.empresa,
    this.telefono,
    this.ciudad,
    this.usuarioId,
    this.solicitudId,
    this.notas,
  });

  factory Cliente.desdeFila(Map<String, dynamic> f) => Cliente(
        id: f['id'] as String,
        creado: DateTime.parse(f['created_at'] as String).toLocal(),
        nombre: (f['name'] as String?) ?? '',
        correo: (f['email'] as String?) ?? '',
        empresa: _texto(f['company']),
        telefono: _texto(f['phone']),
        ciudad: _texto(f['city']),
        usuarioId: f['user_id'] as String?,
        solicitudId: f['lead_id'] as String?,
        notas: _texto(f['notes']),
      );

  final String id, nombre, correo;
  final DateTime creado;
  final String? empresa, telefono, ciudad, usuarioId, solicitudId, notas;

  /// Tiene cuenta en el portal (la web: "Con acceso" si `user_id` no es null).
  bool get conAcceso => usuarioId != null;

  /// Lo que se lee primero en la lista: la marca si la hay, si no la persona.
  String get titulo => empresa ?? nombre;

  bool coincide(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return true;
    return [nombre, empresa, correo, ciudad, telefono].any((v) => (v ?? '').toLowerCase().contains(t));
  }

  static String? _texto(Object? v) {
    final s = (v as String?)?.trim();
    return s == null || s.isEmpty ? null : s;
  }
}

/// Validación del formulario "Nuevo cliente" (la base exige nombre de 2 a 160 letras y correo único).
String? errorNuevoCliente({required String nombre, required String correo}) {
  final n = nombre.trim();
  final c = correo.trim();
  if (n.isEmpty || c.isEmpty || !correoValido(c)) return 'Falta el nombre o un correo válido.';
  if (n.length < 2) return 'El nombre necesita al menos 2 letras.';
  if (n.length > 160) return 'El nombre es muy largo (máximo 160).';
  return null;
}

/// Parecido a `type="email"` del navegador: algo@dominio, sin espacios.
bool correoValido(String c) => RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$").hasMatch(c.trim());
