import 'dart:convert';
import 'dart:io';

import 'package:app/core/utils/texto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paridad con util.js de la web (test/paridad/util.json, generado con el original).
void main() {
  final c = (jsonDecode(File('test/paridad/util.json').readAsStringSync()) as Map)['casos'] as Map;

  test('waNumber', () {
    for (final x in c['waNumber'] as List) {
      expect(numeroWhatsApp(x[0] as String?), x[1], reason: 'teléfono «${x[0]}»');
    }
  });
  test('safeUrl', () {
    for (final x in c['safeUrl'] as List) {
      expect(enlaceSeguro(x[0] as String?), x[1], reason: 'enlace «${x[0]}»');
    }
  });
  test('initials', () {
    for (final x in c['initials'] as List) {
      final esperado = x[1] as String;
      // la web devuelve '' para nombre vacío; la app muestra '?' para no dejar el avatar en blanco
      expect(iniciales(x[0] as String?), esperado.isEmpty ? '?' : esperado, reason: 'nombre «${x[0]}»');
    }
  });

  test('teléfono legible', () {
    expect(telefonoLegible('3001234567'), '300 123 4567');
    expect(telefonoLegible('573001234567'), '+57 300 123 4567');
    expect(telefonoLegible('6012345678'), '6012345678');
    expect(telefonoLegible('300-123 4567'), '300 123 4567'); // con guiones y espacios
    expect(telefonoLegible('+57 (300) 123-4567'), '+57 300 123 4567');
    expect(telefonoLegible(null), '');
  });

  test('hace (como ago de util.js)', () {
    final ahora = DateTime(2026, 11, 9, 12);
    expect(hace(ahora.subtract(const Duration(seconds: 30)), ahora: ahora), 'ahora');
    expect(hace(ahora.subtract(const Duration(minutes: 12)), ahora: ahora), 'hace 12 min');
    expect(hace(ahora.subtract(const Duration(hours: 2)), ahora: ahora), 'hace 2 h');
    expect(hace(ahora.subtract(const Duration(hours: 30)), ahora: ahora), 'ayer');
    expect(hace(ahora.subtract(const Duration(days: 3)), ahora: ahora), 'hace 3 d');
    expect(hace(DateTime(2026, 10, 2), ahora: ahora), '2 oct');
  });
}
