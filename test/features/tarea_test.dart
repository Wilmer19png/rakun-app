import 'package:app/core/utils/texto.dart';
import 'package:app/design_system/tokens.dart';
import 'package:app/features/hoy/domain/tarea.dart';
import 'package:app/features/proyectos/domain/proyecto.dart';
import 'package:flutter_test/flutter_test.dart';

final _ahora = DateTime(2026, 11, 9, 14); // lunes 9 nov, 2 p. m.

Map<String, dynamic> _fila(String id, {String estado = 'por_hacer', String? hace = 'yo', String? revisa, Duration? vence, String proyecto = 'p1'}) => {
      'id': id,
      'project_id': proyecto,
      'title': 'Tarea $id',
      'kind': 'guion',
      'status': estado,
      'assignee_id': hace,
      'reviewer_id': revisa,
      'due_at': vence == null ? null : _ahora.add(vence).toUtc().toIso8601String(),
      'projects': {'id': proyecto, 'name': 'Proyecto $proyecto', 'world': 'web', 'clients': {'name': 'Cliente'}},
    };

Tarea _t(String id, {String estado = 'por_hacer', String? hace = 'yo', String? revisa, Duration? vence, String proyecto = 'p1'}) =>
    Tarea.desdeFila(_fila(id, estado: estado, hace: hace, revisa: revisa, vence: vence, proyecto: proyecto), yo: 'yo');

void main() {
  test('lee el proyecto anidado y sabe si me toca revisar (regla `review` de la web)', () {
    final t = _t('a', estado: 'en_revision', hace: 'otro', revisa: 'yo');
    expect(t.revision, isTrue);
    expect(t.mundo, Mundo.web);
    expect(t.proyectoNombre, 'Proyecto p1');
    expect(t.clienteNombre, 'Cliente');
    expect(t.claveTipo, 'revision');
    // si la hice yo misma no es "revisar", aunque yo sea la revisora
    expect(_t('b', estado: 'en_revision', hace: 'yo', revisa: 'yo').revision, isFalse);
    // si no está en revisión, tampoco
    expect(_t('c', estado: 'en_curso', hace: 'otro', revisa: 'yo').revision, isFalse);
  });

  test('grupos: revisar aparte; lo demás por plazo como bucket()', () {
    expect(grupoDe(_t('a', vence: const Duration(hours: -1)), ahora: _ahora), GrupoHoy.vencido);
    expect(grupoDe(_t('b', vence: const Duration(hours: 4)), ahora: _ahora), GrupoHoy.hoy);
    expect(grupoDe(_t('c', vence: const Duration(days: 3)), ahora: _ahora), GrupoHoy.semana);
    expect(grupoDe(_t('d', vence: const Duration(days: 9)), ahora: _ahora), GrupoHoy.luego);
    expect(grupoDe(_t('e'), ahora: _ahora), GrupoHoy.sin);
    expect(grupoDe(_t('f', estado: 'en_revision', hace: 'otro', revisa: 'yo', vence: const Duration(days: -2)), ahora: _ahora), GrupoHoy.revisar);
  });

  test('resumen: pendientes, proyectos, vencidos y para hoy', () {
    final r = resumen([
      _t('a', vence: const Duration(hours: -1)),
      _t('b', vence: const Duration(hours: 3)),
      _t('c', vence: const Duration(hours: 4), proyecto: 'p2'),
      _t('d', proyecto: 'p3'),
    ], ahora: _ahora);
    expect((r.total, r.proyectos, r.vencidos, r.hoy), (4, 3, 1, 2));
  });

  test('al entregar: con revisor distinto de mí → En revisión; si no → Aprobado', () {
    expect(estadoAlEntregar(_t('a', revisa: 'otro').d, yo: 'yo'), EstadoEntregable.enRevision);
    expect(estadoAlEntregar(_t('b').d, yo: 'yo'), EstadoEntregable.aprobado);
    expect(estadoAlEntregar(_t('c', revisa: 'yo').d, yo: 'yo'), EstadoEntregable.aprobado);
  });

  test('estados que puedo elegir: sin "Aprobado" si alguien la revisa (DSTATUS de la web)', () {
    expect(estadosParaMi(_t('a', revisa: 'otro').d), [EstadoEntregable.porHacer, EstadoEntregable.enCurso, EstadoEntregable.enRevision]);
    expect(estadosParaMi(_t('b').d), EstadoEntregable.values);
  });

  test('nota al devolver como la web', () {
    expect(notaDevolucion('  el guion 4 abre con la pregunta '), 'Devuelto: el guion 4 abre con la pregunta');
    expect(notaDevolucion('   '), 'Devuelto para ajustes');
  });

  test('ruta del archivo en «entregas» como uploadDelivery', () {
    final d = _t('d1').d;
    expect(rutaEntrega(d, 'Guiones noviembre (v2).pdf', ms: 1731175200000), 'p1/d1/1731175200000-Guiones_noviembre_v2_.pdf');
    final largo = '${'a' * 100}.mp4';
    final r = rutaEntrega(d, largo, ms: 1);
    expect(r.split('-').last.length, 80); // .slice(-80)
    expect(r.endsWith('.mp4'), isTrue);
    expect(rutaEntrega(d, 'canción ñandú.mov', ms: 2), 'p1/d1/2-canci_n_and_.mov'); // \w de JavaScript no incluye tildes
  });

  test('lo que ganas: aprobadas + comisiones por cobrar; lo demás en curso', () {
    final g = Ganancias.desde(
      [
        {'pay_amount': 300000, 'status': 'aprobado'},
        {'pay_amount': 112000, 'status': 'en_curso'},
        {'pay_amount': 100000, 'status': 'por_hacer'},
      ],
      [
        {'amount': 150000, 'kind': 'mensual'},
        {'amount': 36000, 'kind': 'venta'},
      ],
    );
    expect(g.porCobrar, 486000);
    expect(g.enCurso, 212000);
    expect(g.mensuales, 1);
    expect(const Ganancias().hayAlgo, isFalse);
  });

  test('pesos como cop() de la web', () {
    expect(pesos(486000), r'$486.000');
    expect(pesos(1990000.4), r'$1.990.000');
    expect(pesos(0), r'$0');
    expect(pesos(999), r'$999');
    expect(pesos(null), r'$0');
  });
}
