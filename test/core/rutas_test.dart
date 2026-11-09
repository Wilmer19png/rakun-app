import 'package:app/core/navegacion/rutas.dart';
import 'package:app/core/permisos/permisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A dónde va cada quien (rutas.dart → decidirRuta). Es lo que protege la entrada.
void main() {
  const admin = Perfil(id: 'a', rol: 'admin');
  const cliente = Perfil(id: 'c', rol: 'cliente');
  const conSesion = AsyncData<Object?>('sesion');
  const sinSesion = AsyncData<Object?>(null);

  String? ir(String desde, {bool lista = true, AsyncValue<Object?> sesion = conSesion, bool hay = true, AsyncValue<Perfil?> perfil = const AsyncData(admin)}) =>
      decidirRuta(ubicacion: desde, entradaLista: lista, sesion: sesion, haySesion: hay, perfil: perfil);

  test('sin sesión: va a iniciar sesión', () => expect(ir('/hoy', sesion: sinSesion, hay: false), '/login'));
  test('sin sesión puede abrir recuperar contraseña', () => expect(ir('/recuperar', sesion: sinSesion, hay: false), isNull));
  test('sin sesión y entrada sin terminar: se queda en la entrada', () => expect(ir('/', lista: false, sesion: sinSesion, hay: false), isNull));
  test('sesión cargando: entrada', () => expect(ir('/hoy', sesion: const AsyncLoading<Object?>(), hay: false), '/'));
  test('perfil cargando: entrada', () => expect(ir('/hoy', perfil: const AsyncLoading<Perfil?>()), '/'));
  test('perfil con error: entrada (allí se reintenta)', () => expect(ir('/hoy', perfil: AsyncError<Perfil?>(Exception('x'), StackTrace.empty)), '/'));
  test('perfil inexistente: entrada', () => expect(ir('/hoy', perfil: const AsyncData<Perfil?>(null)), '/'));
  test('cliente: acceso negado', () => expect(ir('/hoy', perfil: const AsyncData(cliente)), '/sin-acceso'));
  test('cliente no puede saltarse el acceso negado', () => expect(ir('/mas', perfil: const AsyncData(cliente)), '/sin-acceso'));
  test('equipo desde el login: va a Hoy', () => expect(ir('/login'), '/hoy'));
  test('equipo desde la entrada: va a Hoy', () => expect(ir('/'), '/hoy'));
  test('equipo en una sección: se queda', () => expect(ir('/proyectos'), isNull));
  test('equipo con sesión espera a que termine la entrada', () => expect(ir('/', lista: false), isNull));
}
