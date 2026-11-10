import 'dart:convert';
import 'dart:io';

import 'package:app/features/agenda/data/lugares.dart';
import 'package:app/features/agenda/domain/agenda.dart';
import 'package:flutter_test/flutter_test.dart';

final _ahora = DateTime(2026, 11, 9, 14); // lunes 9 nov, 2 p. m.

Reunion _r(String id, {String estado = 'confirmada', Duration? en}) => Reunion.desdeFila({
      'id': id,
      'client_id': 'c',
      'title': 'Reunión $id',
      'status': estado,
      'starts_at': en == null ? null : _ahora.add(en).toUtc().toIso8601String(),
    });

void main() {
  test('lee shoots: horas, equipo, qué prepara y la respuesta del cliente', () {
    final g = Grabacion.desdeFila({
      'id': 'g1',
      'client_id': 'c1',
      'starts_at': '2026-11-09T20:00:00Z',
      'duration_hours': 1.5,
      'crew': ['a', 'b'],
      'prep': ['Ropa lisa', 'Guiones'],
      'status': 'programada',
      'client_response': 'reprogramar',
      'client_note': 'el martes',
      'location': 'Estudio',
      'address': 'Calle 1',
    });
    expect(g.duracion, '1,5 h');
    expect(g.equipo, ['a', 'b']);
    expect(g.prepara.length, 2);
    expect(g.respuestaCliente, 'pide otra fecha: “el martes”');
    expect(g.paraMapa, 'Estudio, Calle 1');
    expect(Grabacion.desdeFila({'id': 'x', 'client_id': 'c', 'starts_at': '2026-11-09T20:00:00Z', 'status': 'realizada'}).respuestaCliente, isNull);
    expect(Grabacion.desdeFila({'id': 'x', 'client_id': 'c', 'starts_at': '2026-11-09T20:00:00Z', 'duration_hours': 3}).duracion, '3 h');
  });

  test('reuniones como viewMeetings: pedidas, próximas desde hace 2 h y anteriores', () {
    final rep = repartirReuniones([
      _r('pedida', estado: 'solicitada'),
      _r('hace1h', en: const Duration(hours: -1)), // todavía "próxima" (margen de 2 h)
      _r('hace3h', en: const Duration(hours: -3)),
      _r('manana', en: const Duration(days: 1)),
      _r('cancelada', estado: 'cancelada', en: const Duration(days: 2)),
      _r('sinfecha'),
    ], ahora: _ahora);
    expect(rep.pedidas.map((m) => m.id), ['pedida']);
    expect(rep.proximas.map((m) => m.id), ['hace1h', 'manana']);
    expect(rep.anteriores.map((m) => m.id), ['cancelada', 'hace3h', 'sinfecha']);
  });

  test('por día: Hoy, Mañana y luego la fecha', () {
    final g = [
      for (final h in [1, 20, 70])
        Evento.grabacion(Grabacion(id: 'g$h', clienteId: 'c', inicio: _ahora.add(Duration(hours: h)))),
    ];
    final dias = porDia(g, ahora: _ahora);
    expect(dias.map((d) => d.$1), ['Hoy · lun 9 nov', 'Mañana · mar 10 nov', 'Jue 12 nov']);
  });

  test('validaciones como la web', () {
    expect(errorGrabacion(dia: null, equipo: const ['a'], estado: 'programada'), 'Elige la fecha.');
    expect(errorGrabacion(dia: _ahora, equipo: const [], estado: 'programada'), 'Elige quién va del equipo a la grabación.');
    expect(errorGrabacion(dia: _ahora, equipo: const [], estado: 'cancelada'), isNull);
    expect(errorReunion(tema: ' ', dia: _ahora, enlace: '', enlaceSeguro: ''), 'Ponle un tema.');
    expect(errorReunion(tema: 'Revisión', dia: _ahora, enlace: 'no es', enlaceSeguro: ''), 'El link de Meet no es válido.');
    expect(errorReunion(tema: 'Revisión', dia: _ahora, enlace: '', enlaceSeguro: ''), isNull);
  });

  test('qué prepara: una por línea; la respuesta del cliente se reinicia al cambiar la fecha', () {
    expect(lineas('Ropa lisa\n\n  Guiones  \n'), ['Ropa lisa', 'Guiones']);
    final g = Grabacion(id: 'g', clienteId: 'c', inicio: _ahora);
    expect(reiniciaRespuesta(antes: g, nuevoInicio: _ahora, yaAcordamos: false), isFalse);
    expect(reiniciaRespuesta(antes: g, nuevoInicio: _ahora.add(const Duration(hours: 1)), yaAcordamos: false), isTrue);
    expect(reiniciaRespuesta(antes: g, nuevoInicio: _ahora, yaAcordamos: true), isTrue);
    expect(reiniciaRespuesta(antes: null, nuevoInicio: _ahora, yaAcordamos: true), isFalse);
  });

  test('lugares anteriores sin repetidos', () {
    final l = lugaresAnteriores([
      {'location': 'Estudio', 'address': 'Calle 1'},
      {'location': 'estudio', 'address': 'calle 1'},
      {'location': 'Estudio', 'address': null},
      {'location': null, 'address': 'x'},
    ]);
    expect(l.map((x) => '${x.nombre}|${x.direccion}'), ['Estudio|Calle 1', 'Estudio|']);
  });

  test('toPlace igual a la web (casos corridos con places.js original)', () {
    final casos = jsonDecode(File('test/paridad/lugares.json').readAsStringSync()) as List;
    for (final c in casos) {
      final l = lugarDePhoton(Map<String, dynamic>.from(c['entrada'] as Map));
      expect((l.nombre, l.direccion), (c['salida']['name'], c['salida']['address']), reason: '${c['entrada']}');
    }
  });

  test('respuesta de Photon: primero Colombia, sin repetidos, máximo 6', () {
    Map<String, dynamic> f(String n, String cc) => {
          'properties': {'name': n, 'city': 'X', 'countrycode': cc, 'country': cc == 'CO' ? 'Colombia' : 'Perú'}
        };
    final r = lugaresDeRespuesta({
      'features': [f('Lima', 'PE'), f('Uno', 'CO'), f('Uno', 'CO'), for (var i = 0; i < 8; i++) f('Otro $i', 'CO')],
    });
    expect(r.first.nombre, 'Uno');
    expect(r.length, 6);
    expect(r.where((x) => x.nombre == 'Uno').length, 1);
  });
}
