/// Permisos del gestor: réplica EXACTA de rakun-web/app/perms.js (`can`, `seesMoney`,
/// `PRESETS`, `presetOf`). La base de datos aplica lo mismo con RLS (`public.can`);
/// esto solo decide qué se muestra. Ver docs/AUDITORIA_GESTOR.md §3 (y el hallazgo H7).
library;

import 'dart:convert';

/// Las 13 secciones con su índice mono (orden de la web).
const secciones = <(String clave, String indice, String nombre)>[
  ('pendientes', '00', 'Mis pendientes'),
  ('solicitudes', '01', 'Solicitudes'),
  ('clientes', '02', 'Clientes'),
  ('proyectos', '03', 'Proyectos'),
  ('parrillas', '04', 'Parrillas'),
  ('grabaciones', '05', 'Grabaciones'),
  ('reuniones', '06', 'Reuniones'),
  ('documentos', '07', 'Documentos'),
  ('trabajo', '08', 'Nuestro trabajo'),
  ('planes', '09', 'Planes y precios'),
  ('equipo', '10', 'Equipo'),
  ('metricas', '11', 'Métricas'),
  ('tarifario', '12', 'Tarifario'),
];

const _e = 'editar';
const _v = 'ver';

/// Roles listos (el admin los ajusta persona por persona). `null` = acceso total.
const presets = <String, ({String nombre, Map<String, String>? perms})>{
  'todo': (nombre: 'Todo (como admin, sin cambiar permisos)', perms: null),
  'directora': (
    nombre: 'Directora',
    perms: {'pendientes': _e, 'proyectos': _e, 'parrillas': _e, 'grabaciones': _e, 'reuniones': _e, 'documentos': _e, 'equipo': _v},
  ),
  'manager': (
    nombre: 'Manager comercial',
    perms: {'pendientes': _e, 'solicitudes': _e, 'clientes': _e, 'proyectos': _e, 'metricas': _v, 'tarifario': _v, 'equipo': _v, 'dinero': _v},
  ),
  'editor': (nombre: 'Editor/a', perms: {'pendientes': _e, 'equipo': _v}),
  'camara': (nombre: 'Cámara', perms: {'pendientes': _e, 'grabaciones': _v, 'equipo': _v}),
};

/// Fila de `public.profiles` (solo lo que usa la app).
class Perfil {
  const Perfil({
    required this.id,
    required this.rol,
    this.perms,
    this.nombre = '',
    this.email,
    this.area,
    this.color,
  });

  final String id;
  final String rol; // admin | equipo | cliente
  final Map<String, String>? perms;
  final String nombre;
  final String? email;
  final String? area;
  final String? color;

  bool get esAdmin => rol == 'admin';
  bool get esEquipo => rol == 'admin' || rol == 'equipo'; // isStaff de supa.js
  bool get esCliente => !esEquipo;

  String get primerNombre => nombre.trim().isEmpty ? (email ?? 'equipo') : nombre.trim().split(RegExp(r'\s+')).first;

  factory Perfil.desdeFila(Map<String, dynamic> f, {String? emailSesion}) {
    final raw = f['perms'];
    Map<String, String>? perms;
    if (raw is Map) {
      perms = raw.map((k, v) => MapEntry('$k', '$v'));
    } else if (raw is String && raw.isNotEmpty) {
      perms = (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', '$v'));
    }
    return Perfil(
      id: f['id'] as String,
      rol: (f['role'] as String?) ?? 'cliente',
      perms: perms,
      nombre: (f['full_name'] as String?) ?? '',
      email: (f['email'] as String?) ?? emailSesion,
      area: f['area'] as String?,
      color: f['color'] as String?,
    );
  }
}

/// `can(me, section, edit)` de perms.js, línea por línea.
bool puede(Perfil? me, String seccion, {bool editar = false}) {
  if (me == null) return false;
  if (me.rol == 'admin') return true;
  if (me.rol != 'equipo') return false;
  if (seccion == 'pendientes') return true; // cada quien siempre ve lo suyo
  final p = me.perms;
  if (p == null) return true;
  final valor = p[seccion];
  return editar ? valor == 'editar' : (valor == 'ver' || valor == 'editar');
}

/// `seesMoney(me)` de perms.js.
bool veDinero(Perfil? me) =>
    me?.rol == 'admin' || (me?.rol == 'equipo' && (me!.perms == null || me.perms!['dinero'] == 'ver'));

/// `presetOf(perms)`: el rol listo que coincide (o 'personalizado').
String rolListoDe(Map<String, String>? perms) {
  String clave(Map<String, String>? p) {
    final e = (p ?? const <String, String>{}).entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return e.map((x) => '${x.key}=${x.value}').join('|');
  }

  for (final entry in presets.entries) {
    final pp = entry.value.perms;
    if (pp == null ? perms == null : clave(pp) == clave(perms)) return entry.key;
  }
  return 'personalizado';
}

/// Destinos de la barra inferior (design/MAPA_NAVEGACION.md §3):
/// Hoy siempre primero y Más último; en medio, hasta 3 de la lista de prioridad
/// que la persona pueda ver, mostrados en orden fijo.
enum Destino { hoy, solicitudes, clientes, agenda, proyectos, parrillas, mensajes, mas }

bool puedeVer(Perfil? me, Destino d) => switch (d) {
      Destino.hoy || Destino.mas => me?.esEquipo ?? false,
      Destino.solicitudes => puede(me, 'solicitudes'),
      Destino.clientes => puede(me, 'clientes'),
      Destino.agenda => puede(me, 'grabaciones') || puede(me, 'reuniones'),
      Destino.proyectos => puede(me, 'proyectos'),
      Destino.parrillas => puede(me, 'parrillas'),
      Destino.mensajes => puede(me, 'equipo'),
    };

const _prioridad = [Destino.solicitudes, Destino.agenda, Destino.proyectos, Destino.clientes, Destino.parrillas, Destino.mensajes];
const _orden = [Destino.solicitudes, Destino.clientes, Destino.agenda, Destino.proyectos, Destino.parrillas, Destino.mensajes];

List<Destino> barraPara(Perfil? me) {
  final medio = _prioridad.where((d) => puedeVer(me, d)).take(3).toSet();
  return [Destino.hoy, ..._orden.where(medio.contains), Destino.mas];
}
