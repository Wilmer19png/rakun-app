import 'package:app/features/parrillas/domain/pieza.dart';
import 'package:flutter_test/flutter_test.dart';

Pieza _p(String id, DateTime cuando, {String estado = 'borrador', List<String> redes = const ['IG']}) => Pieza.desdeFila({
      'id': id,
      'project_id': 'p1',
      'client_id': 'c1',
      'publish_at': cuando.toUtc().toIso8601String(),
      'title': 'Pieza $id',
      'format': 'reel',
      'networks': redes,
      'status': estado,
      'copy_variants': {'alt': 'otro texto', 'TT': 'solo TikTok'},
    });

void main() {
  test('lee posts: redes, variantes, pauta y nota del cliente', () {
    final p = Pieza.desdeFila({
      'id': 'x',
      'project_id': 'p',
      'client_id': 'c',
      'publish_at': '2026-11-10T23:30:00Z',
      'title': 'Reel',
      'networks': ['IG', 'TT'],
      'has_ads': true,
      'status': 'cambios',
      'client_note': 'Que se vea más el producto',
      'copy_variants': {'alt': 'B'},
    });
    expect(p.redes, ['IG', 'TT']);
    expect(p.pauta, isTrue);
    expect(p.pidioCambio, isTrue);
    expect(p.textoAlterno, 'B');
    expect(Pieza.desdeFila({'id': 'y', 'project_id': 'p', 'client_id': 'c', 'publish_at': '2026-11-10T23:30:00Z', 'title': 'x'}).textoAlterno, isNull);
  });

  test('estados como POST_STATUS: el cliente ve desde «Por aprobar»; nombres cortos', () {
    expect(laVeElCliente('lista'), isFalse);
    expect(laVeElCliente('por_aprobar'), isTrue);
    expect(laVeElCliente('publicada'), isTrue);
    expect(estadoCorto('lista'), 'Lista');
    expect(estadoCorto('cambios'), 'Cambios');
    expect(estadoCorto('por_aprobar'), 'Por aprobar');
  });

  test('contadores en el orden de la web y solo los que tienen', () {
    final piezas = [
      _p('a', DateTime(2026, 11, 10), estado: 'aprobada'),
      _p('b', DateTime(2026, 11, 10), estado: 'borrador'),
      _p('c', DateTime(2026, 11, 11), estado: 'borrador'),
      _p('d', DateTime(2026, 11, 12), estado: 'cambios'),
    ];
    expect(contarPorEstado(piezas), [('borrador', 2), ('cambios', 1), ('aprobada', 1)]);
  });

  test('por día, en orden', () {
    final dias = porDiaDelMes([
      _p('b', DateTime(2026, 11, 14, 9)),
      _p('a', DateTime(2026, 11, 10, 18)),
      _p('c', DateTime(2026, 11, 10, 12)),
    ]);
    expect(dias.map((d) => d.$1.day), [10, 14]);
    expect(dias.first.$2.map((p) => p.id), ['c', 'a']);
  });

  test('duplicar el mes: todo en borrador, mismas horas, día recortado al último del mes', () {
    final filas = filasDuplicadas([
      _p('a', DateTime(2026, 10, 31, 18, 30), estado: 'aprobada'),
      _p('b', DateTime(2026, 10, 5, 9), estado: 'publicada', redes: ['IG', 'FB']),
    ], mes: DateTime(2026, 10), proyectoId: 'p1', clienteId: 'c1');
    expect(DateTime.parse(filas[0]['publish_at']! as String).toLocal(), DateTime(2026, 11, 30, 18, 30)); // noviembre tiene 30
    expect(DateTime.parse(filas[1]['publish_at']! as String).toLocal(), DateTime(2026, 11, 5, 9));
    expect(filas.every((f) => f['status'] == 'borrador'), isTrue);
    expect(filas[1]['networks'], ['IG', 'FB']);
    expect(filas[0]['copy_variants'], {'alt': 'otro texto', 'TT': 'solo TikTok'}); // se copian enteras, como la web
    expect(filas[0].containsKey('published_url'), isFalse);
  });

  test('mes: inicio, suma con cambio de año y nombre', () {
    expect(sumarMeses(DateTime(2026, 12), 1), DateTime(2027, 1));
    expect(sumarMeses(DateTime(2026, 1), -1), DateTime(2025, 12));
    expect(nombreMes(DateTime(2026, 11), hoy: DateTime(2026, 11, 9)), 'Noviembre');
    expect(nombreMes(DateTime(2027, 1), hoy: DateTime(2026, 11, 9)), 'Enero 2027');
  });
}
