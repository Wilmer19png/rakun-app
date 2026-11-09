import 'dart:convert';
import 'dart:io';

import 'package:app/core/datos/colombia.dart';
import 'package:app/core/datos/ubicacion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paridad con ubicacion.js de la web (test/paridad/ubicacion.json, generado con el original).
void main() {
  test('leer una ciudad guardada da lo mismo que parse() de la web', () {
    final casos = (jsonDecode(File('test/paridad/ubicacion.json').readAsStringSync()) as Map)['casos'] as List;
    for (final x in casos) {
      final r = leerUbicacion(x[0] as String?);
      final e = x[1] as Map?;
      expect(r == null ? null : {'dep': r.dep, 'city': r.ciudad}, e, reason: 'valor «${x[0]}»');
    }
  });

  test('la lista es la misma de la web: 33 departamentos y 1104 municipios', () {
    expect(colombia.length, 33);
    expect(colombia.values.fold<int>(0, (n, l) => n + l.length), 1104);
    expect(departamentos.last, fueraDeColombia);
  });

  test('lo que se guarda tiene la forma de la web', () {
    expect(escribirUbicacion('Risaralda', 'Pereira'), 'Pereira, Risaralda');
    expect(escribirUbicacion(fueraDeColombia, 'Ecuador'), 'Ecuador');
    expect(escribirUbicacion('Caldas', null), '');
    expect(escribirUbicacion(null, null), '');
  });

  test('ida y vuelta: todo lo que se guarda se vuelve a leer igual', () {
    for (final dep in departamentos) {
      for (final ciudad in opcionesDe(dep)) {
        final r = leerUbicacion(escribirUbicacion(dep, ciudad));
        expect((r?.dep, r?.ciudad), (dep, ciudad), reason: '$ciudad, $dep');
      }
    }
  });

  test('Bogotá D.C. queda elegida sola; fuera de Colombia no', () {
    expect(ciudadUnica('Bogotá D.C.'), 'Bogotá');
    expect(ciudadUnica('Caldas'), isNull);
    expect(ciudadUnica(fueraDeColombia), isNull);
  });
}
