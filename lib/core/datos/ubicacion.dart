/// Ubicación con dos listas: departamento → ciudad (port de app/ubicacion.js).
/// Nadie escribe la ciudad a mano. "Fuera de Colombia" cambia la segunda lista por países.
/// El valor guardado es "Pereira, Risaralda" o "Ecuador", igual que en la web.
library;

import 'colombia.dart';

export 'colombia.dart' show fueraDeColombia;

/// Departamentos en el orden de la web, y al final "Fuera de Colombia".
List<String> get departamentos => [...colombia.keys, fueraDeColombia];

/// Ciudades del departamento (o países si es "Fuera de Colombia").
List<String> opcionesDe(String? dep) => dep == null ? const [] : (dep == fueraDeColombia ? paises : colombia[dep] ?? const []);

/// `parse` de ubicacion.js: "Pereira, Risaralda" → (Risaralda, Pereira); "Ecuador" → (Fuera de Colombia, Ecuador).
/// Si es texto libre viejo, devuelve null (se conserva tal cual hasta que lo cambien).
({String dep, String ciudad})? leerUbicacion(String? valor) {
  final v = (valor ?? '').trim();
  if (v.isEmpty) return null;
  final i = v.lastIndexOf(', ');
  if (i > 0 && (colombia[v.substring(i + 2)]?.contains(v.substring(0, i)) ?? false)) {
    return (dep: v.substring(i + 2), ciudad: v.substring(0, i));
  }
  if (v == 'Bogotá' || v == 'Bogotá D.C.') return (dep: 'Bogotá D.C.', ciudad: 'Bogotá');
  if (paises.contains(v)) return (dep: fueraDeColombia, ciudad: v);
  return null;
}

/// `sync` de ubicacion.js: el texto que se guarda en `city`.
String escribirUbicacion(String? dep, String? ciudad) {
  if (dep == null || dep.isEmpty || ciudad == null || ciudad.isEmpty) return '';
  return dep == fueraDeColombia ? ciudad : '$ciudad, $dep';
}

/// Bogotá D.C. solo tiene una ciudad: queda elegida sola (como en la web).
String? ciudadUnica(String? dep) {
  final o = opcionesDe(dep);
  return dep != fueraDeColombia && o.length == 1 ? o.first : null;
}
