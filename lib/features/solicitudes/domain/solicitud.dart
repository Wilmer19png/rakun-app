import '../../../design_system/componentes.dart';
import '../../../design_system/tokens.dart';

/// Estados de una solicitud, en el orden de la web (admin.js → STATUS).
enum EstadoSolicitud {
  nueva('Nueva', RkTono.accion),
  contactado('Contactado', RkTono.neutra),
  reunion('Reunión', RkTono.neutra),
  propuesta('Propuesta', RkTono.neutra),
  ganado('Ganado', RkTono.ok),
  perdido('Perdido', RkTono.apagada);

  const EstadoSolicitud(this.nombre, this.tono);
  final String nombre;
  final RkTono tono;

  /// En las pestañas de la lista: "Nuevas" (las demás igual que el estado).
  String get pestana => this == EstadoSolicitud.nueva ? 'Nuevas' : nombre;

  static EstadoSolicitud desde(String? v) => values.firstWhere((e) => e.name == v, orElse: () => EstadoSolicitud.nueva);
}

/// Una fila de `public.leads` (solo lectura de sus campos; los cambios van por el repositorio).
class Solicitud {
  const Solicitud({
    required this.id,
    required this.creada,
    required this.mundo,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.estado,
    this.plan,
    this.planDetalle,
    this.precio,
    this.ciudad,
    this.ocupacion,
    this.enlaces = const [],
    this.quiere,
    this.contactarPor,
    this.contactarCuando,
    this.aCargo,
    this.notas,
    this.anuncio,
    this.campana,
    this.fuente,
  });

  final String id;
  final DateTime creada;
  final Mundo? mundo;
  final String nombre, correo, telefono;
  final EstadoSolicitud estado;
  final String? plan, planDetalle, precio, ciudad, ocupacion, quiere, contactarPor, contactarCuando, aCargo, notas;
  final List<String> enlaces;
  final String? anuncio, campana, fuente; // utm_content, utm_campaign, utm_source

  bool get vinoDeAnuncio => (fuente ?? '').isNotEmpty;
  String get primerNombre => nombre.trim().split(RegExp(r'\s+')).first;

  factory Solicitud.desdeFila(Map<String, dynamic> f) => Solicitud(
        id: f['id'] as String,
        creada: DateTime.parse(f['created_at'] as String).toLocal(),
        mundo: Mundo.desde(f['world'] as String?),
        nombre: (f['name'] as String?) ?? '',
        correo: (f['email'] as String?) ?? '',
        telefono: (f['phone'] as String?) ?? '',
        estado: EstadoSolicitud.desde(f['status'] as String?),
        plan: f['plan'] as String?,
        planDetalle: f['plan_detail'] as String?,
        precio: f['price_label'] as String?,
        ciudad: f['city'] as String?,
        ocupacion: f['occupation'] as String?,
        enlaces: [for (final e in (f['links'] as List? ?? const [])) '$e'],
        quiere: f['goal'] as String?,
        contactarPor: f['contact_via'] as String?,
        contactarCuando: f['contact_time'] as String?,
        aCargo: f['assigned_to'] as String?,
        notas: f['notes'] as String?,
        anuncio: f['utm_content'] as String?,
        campana: f['utm_campaign'] as String?,
        fuente: f['utm_source'] as String?,
      );

  /// El buscador de la web: nombre, correo, ciudad, plan, ocupación y enlaces.
  bool coincide(String q) {
    if (q.trim().isEmpty) return true;
    final t = [nombre, correo, ciudad, plan, ocupacion, ...enlaces].whereType<String>().join(' ').toLowerCase();
    return t.contains(q.trim().toLowerCase());
  }
}

/// Los nombres de campaña/anuncio que llegaron antes de la fase 12 vienen codificados (`plain` de admin-meta.js).
String textoPlano(String? v) {
  var t = v ?? '';
  if (RegExp(r'%[0-9a-f]{2}|\+', caseSensitive: false).hasMatch(t)) {
    try {
      t = Uri.decodeComponent(t.replaceAll('+', ' '));
    } catch (_) {
      // se deja igual
    }
  }
  return t.trim();
}
