import 'package:app/design_system/tokens.dart';
import 'package:app/features/solicitudes/domain/solicitud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fila = {
    'id': 'x',
    'created_at': '2026-11-09T16:36:32.130Z',
    'world': 'web',
    'name': 'Ana María Ejemplo',
    'email': 'ana@ejemplo.com',
    'phone': '3000000000',
    'status': 'propuesta',
    'plan': 'Página de citas',
    'city': 'Manizales',
    'links': ['instagram.com/ana'],
    'utm_source': 'meta',
    'utm_content': 'RAK%C3%9CN+%7C+M%C3%A9dicos',
  };

  test('lee una fila de leads', () {
    final s = Solicitud.desdeFila(fila);
    expect(s.mundo, Mundo.web);
    expect(s.estado, EstadoSolicitud.propuesta);
    expect(s.primerNombre, 'Ana');
    expect(s.vinoDeAnuncio, isTrue);
    expect(s.enlaces, ['instagram.com/ana']);
  });

  test('un estado desconocido se trata como nueva', () {
    expect(EstadoSolicitud.desde('raro'), EstadoSolicitud.nueva);
  });

  test('el buscador mira nombre, correo, ciudad, plan y enlaces (como la web)', () {
    final s = Solicitud.desdeFila(fila);
    expect(s.coincide('manizales'), isTrue);
    expect(s.coincide('CITAS'), isTrue);
    expect(s.coincide('instagram'), isTrue);
    expect(s.coincide('bogotá'), isFalse);
    expect(s.coincide('  '), isTrue);
  });

  test('los nombres de anuncio codificados se leen bien (plain de la web)', () {
    expect(textoPlano('RAK%C3%9CN+%7C+M%C3%A9dicos'), 'RAKÜN | Médicos');
    expect(textoPlano('Normal'), 'Normal');
    expect(textoPlano(null), '');
  });
}
