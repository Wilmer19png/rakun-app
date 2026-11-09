import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/entrada_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/recuperar_page.dart';
import '../../features/auth/presentation/sin_acceso_page.dart';
import '../../features/diagnostico/presentation/en_vivo_page.dart';
import '../../features/galeria/presentation/galeria_page.dart';
import '../../features/hoy/presentation/hoy_page.dart';
import '../../features/mas/presentation/mas_page.dart';
import '../../features/seccion/presentation/seccion_pendiente_page.dart';
import '../../features/solicitudes/presentation/ficha_solicitud_page.dart';
import '../../features/solicitudes/presentation/solicitudes_page.dart';
import '../permisos/permisos.dart';
import '../supabase/sesion.dart';
import 'shell.dart';

/// La entrada dura menos de 1,5 s (DESIGN.md §8): se queda al menos lo que tarda el ojo en abrir.
final entradaListaProvider = FutureProvider<bool>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 1100));
  return true;
});

/// Ruta de cada destino de la barra inferior.
const rutaDe = <Destino, String>{
  Destino.hoy: '/hoy',
  Destino.solicitudes: '/solicitudes',
  Destino.clientes: '/clientes',
  Destino.agenda: '/agenda',
  Destino.proyectos: '/proyectos',
  Destino.parrillas: '/parrillas',
  Destino.mensajes: '/mensajes',
  Destino.mas: '/mas',
};

const _publicas = {'/login', '/recuperar'};
const _entrada = {'/', '/login', '/recuperar', '/sin-acceso'};

/// Decide a dónde va cada quien. Es una función pura para poder probarla.
@visibleForTesting
String? decidirRuta({
  required String ubicacion,
  required bool entradaLista,
  required AsyncValue<Object?> sesion,
  required bool haySesion,
  required AsyncValue<Perfil?> perfil,
}) {
  if (sesion.isLoading && !sesion.hasValue) return ubicacion == '/' ? null : '/';
  if (!haySesion) {
    if (_publicas.contains(ubicacion)) return null;
    if (!entradaLista) return ubicacion == '/' ? null : '/';
    return '/login';
  }
  if (!entradaLista || perfil.isLoading || perfil.hasError || perfil.value == null) return ubicacion == '/' ? null : '/';
  if (perfil.value!.esCliente) return ubicacion == '/sin-acceso' ? null : '/sin-acceso';
  if (_entrada.contains(ubicacion)) return '/hoy';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresco = ValueNotifier<int>(0);
  void avisar(_, _) => refresco.value++;
  ref.listen(sesionProvider, avisar);
  ref.listen(perfilProvider, avisar);
  ref.listen(entradaListaProvider, avisar);
  ref.onDispose(refresco.dispose);

  Page<void> sinAnimacion(Widget child, GoRouterState s) => NoTransitionPage(key: s.pageKey, child: child);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresco,
    redirect: (context, state) {
      final sesion = ref.read(sesionProvider);
      return decidirRuta(
        ubicacion: state.matchedLocation,
        entradaLista: ref.read(entradaListaProvider).value ?? false,
        sesion: sesion,
        haySesion: sesion.value != null,
        perfil: ref.read(perfilProvider),
      );
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const EntradaPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/recuperar', builder: (_, _) => const RecuperarPage()),
      GoRoute(path: '/sin-acceso', builder: (_, _) => const SinAccesoPage()),
      // fichas: encima de la lista, sin barra inferior (como el diseño); Atrás vuelve a la lista
      GoRoute(path: '/solicitudes/:id', builder: (_, s) => FichaSolicitudPage(id: s.pathParameters['id']!)),
      ShellRoute(
        builder: (context, state, child) => AppShell(ubicacion: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/hoy', pageBuilder: (_, s) => sinAnimacion(const HoyPage(), s)),
          GoRoute(path: '/solicitudes', pageBuilder: (_, s) => sinAnimacion(const SolicitudesPage(), s)),
          GoRoute(path: '/clientes', pageBuilder: (_, s) => sinAnimacion(const SeccionPendientePage(seccion: 'clientes'), s)),
          GoRoute(path: '/agenda', pageBuilder: (_, s) => sinAnimacion(const SeccionPendientePage(seccion: 'agenda'), s)),
          GoRoute(path: '/proyectos', pageBuilder: (_, s) => sinAnimacion(const SeccionPendientePage(seccion: 'proyectos'), s)),
          GoRoute(path: '/parrillas', pageBuilder: (_, s) => sinAnimacion(const SeccionPendientePage(seccion: 'parrillas'), s)),
          GoRoute(path: '/mensajes', pageBuilder: (_, s) => sinAnimacion(const SeccionPendientePage(seccion: 'mensajes'), s)),
          GoRoute(
            path: '/mas',
            pageBuilder: (_, s) => sinAnimacion(const MasPage(), s),
            routes: [
              GoRoute(path: 'seccion/:clave', builder: (_, s) => SeccionPendientePage(seccion: s.pathParameters['clave']!, desdeMas: true)),
              GoRoute(path: 'galeria', builder: (_, _) => const GaleriaPage()),
              GoRoute(path: 'en-vivo', builder: (_, _) => const EnVivoPage()),
            ],
          ),
        ],
      ),
    ],
  );
});
