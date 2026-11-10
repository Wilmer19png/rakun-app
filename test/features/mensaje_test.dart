import 'package:app/features/mensajes/domain/mensaje.dart';
import 'package:flutter_test/flutter_test.dart';

Mensaje _m(String id, {String autor = 'otro', String para = 'todos', bool fijado = false, int horas = 1, String? proyecto}) => Mensaje.desdeFila({
      'id': id,
      'author_id': autor,
      'body': 'Mensaje $id',
      'created_at': DateTime(2026, 11, 9, 14).subtract(Duration(hours: horas)).toUtc().toIso8601String(),
      'to_kind': para,
      'to_user': para == 'persona' ? 'yo' : null,
      'project_id': para == 'proyecto' ? 'p1' : null,
      'projects': proyecto == null ? null : {'name': proyecto},
      'pinned': fijado,
    });

void main() {
  test('destino como target() de la web', () {
    String? nombre(String id) => id == 'yo' ? 'Sofía' : null;
    expect(_m('a').destino(nombre), 'todo el equipo');
    expect(_m('b', para: 'persona').destino(nombre), 'para Sofía');
    expect(_m('c', para: 'proyecto', proyecto: 'Videoclip').destino(nombre), 'equipo de Videoclip');
    expect(_m('d', para: 'proyecto').destino(nombre), 'equipo de un proyecto');
  });

  test('nuevo, visto por y quién puede fijar o borrar', () {
    final e = estadoMensaje(_m('a'), yo: 'yo', admin: false, leidoPor: const ['x', 'z']);
    expect((e.nuevo, e.puedeGestionar, e.vistos), (true, false, 2));
    expect(estadoMensaje(_m('a'), yo: 'yo', admin: false, leidoPor: const ['yo']).nuevo, isFalse);
    expect(estadoMensaje(_m('a', autor: 'yo'), yo: 'yo', admin: false, leidoPor: const []).nuevo, isFalse); // lo mío nunca es nuevo
    expect(estadoMensaje(_m('a'), yo: 'yo', admin: true, leidoPor: const []).puedeGestionar, isTrue);
  });

  test('orden: fijados arriba y luego lo más reciente', () {
    final o = ordenar([_m('viejo', horas: 30), _m('fijo', fijado: true, horas: 72), _m('nuevo', horas: 1)]);
    expect(o.map((m) => m.id), ['fijo', 'nuevo', 'viejo']);
  });

  test('filtros', () {
    final ms = [_m('a'), _m('b', para: 'persona'), _m('c', para: 'proyecto', fijado: true), _m('d', autor: 'yo', para: 'persona')];
    expect(ms.where((m) => pasaFiltro(m, FiltroMensajes.paraMi, yo: 'yo')).map((m) => m.id), ['b', 'c']);
    expect(ms.where((m) => pasaFiltro(m, FiltroMensajes.fijados, yo: 'yo')).map((m) => m.id), ['c']);
  });

  test('fila nueva como la web (solo el destino que corresponde)', () {
    expect(filaNueva(yo: 'yo', para: 'todos', texto: '  Hola  ', fijar: true), {
      'author_id': 'yo',
      'to_kind': 'todos',
      'body': 'Hola',
      'pinned': true,
      'to_user': null,
      'project_id': null,
    });
    expect(filaNueva(yo: 'yo', para: 'persona', persona: 'p', proyecto: 'x', texto: 'a')!['project_id'], isNull);
    expect(filaNueva(yo: 'yo', para: 'todos', texto: '   '), isNull);
    expect(filaNueva(yo: 'yo', para: 'persona', texto: 'a'), isNull);
    expect(filaNueva(yo: 'yo', para: 'todos', texto: 'x' * 2001), isNull);
  });
}
