import 'package:flutter/widgets.dart';

import '../../design_system/componentes.dart';
import '../permisos/permisos.dart';
import '../utils/texto.dart';

/// Avatar de una persona del equipo (iniciales sobre su color de perfil).
Widget avatarDe(Perfil p, {bool chico = false}) => RkAvatar(iniciales: iniciales(p.nombre.isEmpty ? p.email : p.nombre), colorHex: p.color, chico: chico);

/// "Wilmer Alejandro…" o su correo si no tiene nombre.
String nombreDe(Perfil p) => p.nombre.isEmpty ? (p.email ?? '') : p.nombre;
