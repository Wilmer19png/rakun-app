import 'package:app/core/datos/proyectos_web.dart';
import 'package:app/design_system/tokens.dart';
import 'package:app/features/proyectos/domain/proyecto.dart';
import 'package:flutter_test/flutter_test.dart';

Entregable _e(DateTime? vence, {String estado = 'por_hacer'}) => Entregable.desdeFila({
      'id': 'd',
      'project_id': 'p',
      'title': 'x',
      'status': estado,
      'due_at': vence?.toUtc().toIso8601String(),
    });

void main() {
  final ahora = DateTime(2026, 11, 9, 10); // lunes 9 nov, 10 a. m.

  test('lee una fila de projects (fechas "date" como día local)', () {
    final p = Proyecto.desdeFila({
      'id': 'p1',
      'client_id': 'c1',
      'world': 'produccion',
      'name': 'Videoclip',
      'status': 'pausado',
      'stage': 'Rodaje',
      'start_date': '2026-11-01',
      'clients': {'name': 'Colectivo Ejemplo'},
      'quotes': {'number': 'COT-2026-004', 'token': 't'},
    });
    expect(p.mundo, Mundo.produccion);
    expect(p.estado, EstadoProyecto.pausado);
    expect(p.inicio, DateTime(2026, 11, 1));
    expect(p.clienteNombre, 'Colectivo Ejemplo');
    expect(p.cotizacionNumero, 'COT-2026-004');
    expect(p.etapas, ['Preproducción', 'Rodaje', 'Postproducción']);
    expect(p.coincide('colectivo'), isTrue);
    expect(Proyecto.desdeFila({'id': 'x', 'client_id': 'c', 'name': 'y', 'quotes': null}).cotizacionToken, isNull);
  });

  test('plazos como bucket() de la web', () {
    expect(plazoDe(_e(null), ahora: ahora), Plazo.sin);
    expect(plazoDe(_e(DateTime(2026, 11, 9, 8)), ahora: ahora), Plazo.vencido);
    expect(plazoDe(_e(DateTime(2026, 11, 9, 8), estado: 'aprobado'), ahora: ahora), Plazo.hoy); // aprobado no vence
    expect(plazoDe(_e(DateTime(2026, 11, 9, 18)), ahora: ahora), Plazo.hoy);
    expect(plazoDe(_e(DateTime(2026, 11, 15, 18)), ahora: ahora), Plazo.semana);
    expect(plazoDe(_e(DateTime(2026, 11, 16, 18)), ahora: ahora), Plazo.luego);
  });

  test('etiqueta de la fecha límite (mismos cortes que dueLabel)', () {
    expect(etiquetaVence(_e(null), ahora: ahora), 'Sin fecha');
    expect(etiquetaVence(_e(DateTime(2026, 11, 9, 8)), ahora: ahora), 'Venció hoy');
    expect(etiquetaVence(_e(DateTime(2026, 11, 8, 18)), ahora: ahora), 'Venció ayer');
    expect(etiquetaVence(_e(DateTime(2026, 11, 5, 18)), ahora: ahora), 'Venció hace 4 d');
    expect(etiquetaVence(_e(DateTime(2026, 11, 9, 18)), ahora: ahora), 'Faltan 8 h');
    expect(etiquetaVence(_e(DateTime(2026, 11, 13, 18)), ahora: ahora), 'vie 13');
    expect(etiquetaVence(_e(DateTime(2026, 11, 22, 18)), ahora: ahora), '22 nov');
    expect(etiquetaVence(_e(DateTime(2026, 11, 1, 18), estado: 'aprobado'), ahora: ahora), '1 nov');
  });

  test('la plantilla cuenta desde hoy a las 6 p. m. y sigue el orden', () {
    final p = Proyecto.desdeFila({'id': 'p1', 'client_id': 'c1', 'world': 'marca', 'name': 'Redes', 'owner_id': 'u1'});
    final filas = filasPlantilla(p, desde: 2, hoy: ahora);
    expect(filas.length, plantillasWeb['marca']!.length);
    expect(filas.first['title'], 'Estrategia y parrilla del mes');
    expect(filas.first['assignee_id'], 'u1');
    expect(filas.first['sort'], 2);
    expect(DateTime.parse(filas.first['due_at']! as String).toLocal(), DateTime(2026, 11, 14, 18)); // +5 días
    expect(filas.last['sort'], 2 + filas.length - 1);
  });

  test('las listas generadas de la web son coherentes', () {
    for (final m in Mundo.values) {
      expect(etapasPara(m), isNotEmpty, reason: m.name);
      for (final t in plantillasWeb[claveMundo(m)]!) {
        expect(tiposWeb.containsKey(t.$2), isTrue, reason: t.$1);
      }
    }
    expect(EstadoEntregable.values.map((e) => e.nombre), ['Por hacer', 'En curso', 'En revisión', 'Aprobado']);
    expect(nombreTipo('raro'), 'Otro');
  });
}
