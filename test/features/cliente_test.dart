import 'package:app/design_system/tokens.dart';
import 'package:app/features/clientes/data/clientes_repo.dart';
import 'package:app/features/clientes/domain/cliente.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fila = {
    'id': 'c1',
    'created_at': '2026-10-02T15:00:00Z',
    'name': 'Ana Ejemplo',
    'company': 'Marca Ejemplo',
    'email': 'ana@ejemplo.com',
    'phone': '3000000000',
    'city': 'Manizales, Caldas',
    'user_id': null,
    'notes': '  ',
  };

  test('lee una fila de clients', () {
    final x = Cliente.desdeFila(fila);
    expect(x.titulo, 'Marca Ejemplo');
    expect(x.conAcceso, isFalse);
    expect(x.notas, isNull); // vacío = sin notas
    expect(Cliente.desdeFila({...fila, 'company': null}).titulo, 'Ana Ejemplo');
    expect(Cliente.desdeFila({...fila, 'user_id': 'u1'}).conAcceso, isTrue);
  });

  test('el buscador mira nombre, marca, correo, ciudad y teléfono', () {
    final x = Cliente.desdeFila(fila);
    for (final q in ['ana', 'MARCA', 'ejemplo.com', 'caldas', '3000', '']) {
      expect(x.coincide(q), isTrue, reason: q);
    }
    expect(x.coincide('bogotá'), isFalse);
  });

  test('nuevo cliente: mismas reglas que la web y la base', () {
    expect(errorNuevoCliente(nombre: 'Ana', correo: 'ana@ejemplo.com'), isNull);
    expect(errorNuevoCliente(nombre: '', correo: 'ana@ejemplo.com'), 'Falta el nombre o un correo válido.');
    expect(errorNuevoCliente(nombre: 'Ana', correo: 'ana@'), 'Falta el nombre o un correo válido.');
    expect(errorNuevoCliente(nombre: 'Ana', correo: 'ana ejemplo@x.co'), isNotNull);
    expect(errorNuevoCliente(nombre: 'A', correo: 'a@x.co'), isNotNull); // la base pide 2 a 160
    expect(errorNuevoCliente(nombre: 'A' * 161, correo: 'a@x.co'), isNotNull);
    expect(errorNuevoCliente(nombre: ' Ana ', correo: ' ANA@Ejemplo.com '), isNull);
  });

  test('mundos por cliente salen de sus proyectos', () {
    final r = mundosDe([
      {'client_id': 'c1', 'world': 'marca'},
      {'client_id': 'c1', 'world': 'produccion'},
      {'client_id': 'c1', 'world': 'marca'},
      {'client_id': 'c2', 'world': 'web'},
      {'client_id': 'c3', 'world': 'raro'},
    ]);
    expect(r['c1'], {Mundo.marca, Mundo.produccion});
    expect(r['c2'], {Mundo.web});
    expect(r.containsKey('c3'), isFalse);
  });
}
