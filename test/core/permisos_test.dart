import 'dart:convert';
import 'dart:io';

import 'package:app/core/permisos/permisos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paridad con la web: test/paridad/permisos.json sale de ejecutar el perms.js original
/// (node test/paridad/generar_permisos.mjs). Cada caso debe dar lo mismo en Dart.
void main() {
  final datos = jsonDecode(File('test/paridad/permisos.json').readAsStringSync()) as Map<String, dynamic>;
  final casos = (datos['casos'] as List).cast<Map<String, dynamic>>();

  Perfil? perfilDe(Map<String, dynamic> c) {
    if (c['sinSesion'] == true) return null;
    final perms = (c['perms'] as Map?)?.map((k, v) => MapEntry('$k', '$v'));
    return Perfil(id: 'x', rol: (c['role'] as String?) ?? '', perms: perms);
  }

  group('paridad con perms.js', () {
    for (final c in casos) {
      test(c['nombre'] as String, () {
        final me = perfilDe(c);
        final can = (c['can'] as Map).cast<String, dynamic>();
        for (final s in secciones) {
          final esperado = can[s.$1] as Map;
          expect(puede(me, s.$1), esperado['ver'], reason: '${c['nombre']} · ver ${s.$1}');
          expect(puede(me, s.$1, editar: true), esperado['editar'], reason: '${c['nombre']} · editar ${s.$1}');
        }
        expect(veDinero(me), c['seesMoney'], reason: '${c['nombre']} · ve dinero');
        if (me != null) expect(rolListoDe(me.perms), c['presetOf'], reason: '${c['nombre']} · rol listo');
      });
    }
  });

  group('barra inferior por rol (MAPA_NAVEGACION §3)', () {
    Perfil eq(String preset) => Perfil(id: 'x', rol: 'equipo', perms: presets[preset]!.perms);
    const h = Destino.hoy, m = Destino.mas;

    test('admin', () => expect(barraPara(const Perfil(id: 'a', rol: 'admin')), [h, Destino.solicitudes, Destino.agenda, Destino.proyectos, m]));
    test('acceso total', () => expect(barraPara(const Perfil(id: 'a', rol: 'equipo')), [h, Destino.solicitudes, Destino.agenda, Destino.proyectos, m]));
    test('manager', () => expect(barraPara(eq('manager')), [h, Destino.solicitudes, Destino.clientes, Destino.proyectos, m]));
    test('directora', () => expect(barraPara(eq('directora')), [h, Destino.agenda, Destino.proyectos, Destino.parrillas, m]));
    test('editor', () => expect(barraPara(eq('editor')), [h, Destino.mensajes, m]));
    test('cámara', () => expect(barraPara(eq('camara')), [h, Destino.agenda, Destino.mensajes, m]));
    test('nunca más de 5', () {
      for (final p in presets.values) {
        expect(barraPara(Perfil(id: 'x', rol: 'equipo', perms: p.perms)).length, lessThanOrEqualTo(5));
      }
    });
  });

  test('cliente no es equipo (se le niega la app en v1)', () {
    expect(const Perfil(id: 'c', rol: 'cliente').esEquipo, isFalse);
  });
}
