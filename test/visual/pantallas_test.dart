// Capturas de referencia de la app (pruebas "golden"): cada pantalla se dibuja con un
// perfil DE EJEMPLO, sin conectarse a Supabase, a 360×800 (×3) en los dos temas.
// Generar o actualizar:  flutter test test/visual --update-goldens
// Las imágenes quedan en test/visual/goldens/ y se comparan con el prototipo aprobado.
import 'package:app/core/navegacion/shell.dart';
import 'package:app/core/permisos/permisos.dart';
import 'package:app/core/supabase/sesion.dart';
import 'package:app/design_system/apariencia.dart';
import 'package:app/design_system/tema.dart';
import 'package:app/design_system/tokens.dart';
import 'package:app/features/auth/presentation/entrada_page.dart';
import 'package:app/features/auth/presentation/login_page.dart';
import 'package:app/features/auth/presentation/recuperar_page.dart';
import 'package:app/features/auth/presentation/sin_acceso_page.dart';
import 'package:app/features/galeria/presentation/galeria_page.dart';
import 'package:app/features/hoy/presentation/hoy_page.dart';
import 'package:app/features/mas/presentation/mas_page.dart';
import 'package:app/features/seccion/presentation/seccion_pendiente_page.dart';
import 'package:app/core/supabase/equipo.dart';
import 'package:app/core/sync/datos.dart';
import 'package:app/core/utils/fechas.dart';
import 'package:app/features/clientes/data/clientes_repo.dart';
import 'package:app/features/clientes/domain/cliente.dart';
import 'package:app/features/clientes/presentation/clientes_page.dart';
import 'package:app/features/proyectos/data/proyectos_repo.dart';
import 'package:app/features/proyectos/domain/proyecto.dart';
import 'package:app/features/proyectos/presentation/ficha_proyecto_page.dart';
import 'package:app/features/proyectos/presentation/proyectos_page.dart';
import 'package:app/features/solicitudes/data/solicitudes_repo.dart';
import 'package:app/features/solicitudes/domain/solicitud.dart';
import 'package:app/features/solicitudes/presentation/ficha_solicitud_page.dart';
import 'package:app/features/solicitudes/presentation/solicitudes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ejemploAdmin = Perfil(id: 'ejemplo-admin', rol: 'admin', nombre: 'Wilmer Ejemplo', area: 'Dirección', color: '#FF2C68');
final _ejemploEditor = Perfil(id: 'ejemplo-editor', rol: 'equipo', nombre: 'Alexander Ejemplo', area: 'Edición', color: '#2BCDFF', perms: presets['editor']!.perms);

/// Solicitudes DE EJEMPLO (nunca datos reales en las capturas del repositorio).
final _ahora = DateTime.now();
Map<String, dynamic> _lead(String id, String nombre, String mundo, String plan, String estado, int minutos, {String? ciudad, String? anuncio, String? aCargo, List<String> links = const []}) => {
      'id': id, 'created_at': _ahora.subtract(Duration(minutes: minutos)).toUtc().toIso8601String(), 'world': mundo, 'name': nombre,
      'email': '$id@ejemplo.com', 'phone': '3000000000', 'status': estado, 'plan': plan, 'city': ciudad, 'links': links,
      'utm_source': anuncio == null ? null : 'meta', 'utm_content': anuncio, 'assigned_to': aCargo, 'occupation': 'Ocupación de ejemplo',
      'goal': 'Texto de ejemplo de lo que quiere.', 'contact_via': 'WhatsApp', 'contact_time': 'En la tarde', 'price_label': r'$1.990.000 / mes (ejemplo)',
    };
final _solicitudes = [
  _lead('ej1', 'Ana Ejemplo', 'marca', 'Gestión completa · Equilibrio', 'nueva', 12, ciudad: 'Manizales', links: ['instagram.com/ejemplo', 'tiktok.com/@ejemplo']),
  _lead('ej2', 'Dr. Ejemplo Pérez', 'web', 'Página de citas', 'nueva', 130, ciudad: 'Medellín', anuncio: 'Médicos · ejemplo'),
  _lead('ej3', 'Colectivo Ejemplo', 'produccion', 'Videoclip', 'contactado', 1500, ciudad: 'Bogotá', aCargo: 'ejemplo-admin'),
].map(Solicitud.desdeFila).toList();
final _extraSolicitudes = [
  solicitudesProvider.overrideWith((ref) async => Datos(_solicitudes)),
  equipoProvider.overrideWith((ref) async => [_ejemploAdmin]),
];

/// Clientes DE EJEMPLO.
Map<String, dynamic> _cli(String id, String nombre, {String? marca, String? ciudad, bool acceso = false, String? tel = '3000000000'}) => {
      'id': id, 'created_at': '2026-10-02T15:00:00Z', 'name': nombre, 'company': marca, 'email': '$id@ejemplo.com', 'phone': tel, 'city': ciudad,
      'user_id': acceso ? 'u-$id' : null,
    };
final _clientes = [
  _cli('c1', 'Ana Ejemplo', marca: 'Marca Ejemplo', ciudad: 'Manizales, Caldas', acceso: true),
  _cli('c2', 'Dr. Ejemplo Pérez', marca: 'Consultorio Ejemplo', ciudad: 'Medellín, Antioquia'),
  _cli('c3', 'Colectivo Ejemplo', marca: 'Videoclip Ejemplo', ciudad: 'Bogotá, Bogotá D.C.', acceso: true),
  _cli('c4', 'Mentor Ejemplo', ciudad: 'Pereira, Risaralda', acceso: true, tel: null),
  _cli('c5', 'Tienda Ejemplo', ciudad: 'Ecuador'),
].map(Cliente.desdeFila).toList();
final _extraClientes = [
  clientesProvider.overrideWith((ref) async => Datos(_clientes)),
  mundosPorClienteProvider.overrideWith((ref) async => {
        'c1': {Mundo.marca, Mundo.produccion},
        'c2': {Mundo.web},
        'c3': {Mundo.produccion},
        'c4': {Mundo.marca},
      }),
];

/// Proyectos y entregables DE EJEMPLO (fechas relativas a hoy, así la etiqueta "vencido" no cambia con el tiempo).
final _hoy = DateTime(2026, 11, 9); // reloj fijo de las etiquetas de fecha (ver setUpAll)
final _equipoEj = [
  _ejemploAdmin,
  const Perfil(id: 'ej-sofia', rol: 'equipo', nombre: 'Sofía Ejemplo', color: '#2BCDFF'),
  const Perfil(id: 'ej-alex', rol: 'equipo', nombre: 'Alexander Ejemplo', color: '#FFF02B'),
];
Map<String, dynamic> _pj(String id, String nombre, String mundo, String cliente, String etapa, {String? plan, String estado = 'activo', String? dueno}) => {
      'id': id, 'client_id': 'c-$id', 'world': mundo, 'name': nombre, 'status': estado, 'stage': etapa, 'plan': plan,
      'owner_id': dueno, 'clients': {'name': cliente}, 'start_date': '2026-11-01',
    };
final _proyectos = [
  _pj('p1', 'Redes · noviembre', 'marca', 'Marca Ejemplo', 'Guiones', plan: 'Equilibrio', dueno: 'ejemplo-admin'),
  _pj('p2', 'Página de citas', 'web', 'Consultorio Ejemplo', 'Wireframe', dueno: 'ej-sofia'),
  _pj('p3', 'Videoclip «Ejemplo»', 'produccion', 'Colectivo Ejemplo', 'Postproducción', dueno: 'ej-alex'),
  _pj('p4', 'Redes · octubre', 'marca', 'Mentor Ejemplo', 'Publicación', plan: 'Ritmo', estado: 'pausado', dueno: 'ejemplo-admin'),
].map(Proyecto.desdeFila).toList();
Map<String, dynamic> _ent(String id, String titulo, String tipo, String estado, int dias, {String? hace, String? revisa}) => {
      'id': id, 'project_id': 'p1', 'title': titulo, 'kind': tipo, 'status': estado, 'assignee_id': hace, 'reviewer_id': revisa,
      'due_at': _hoy.add(Duration(days: dias, hours: 18)).toUtc().toIso8601String(), 'brief_url': 'https://docs.google.com/ejemplo',
    };
final _entregables = [
  _ent('d1', 'Estrategia y parrilla del mes', 'estrategia', 'aprobado', -8, hace: 'ejemplo-admin'),
  _ent('d2', 'Guiones del mes', 'guion', 'en_curso', -1, hace: 'ej-sofia', revisa: 'ejemplo-admin'),
  _ent('d3', 'Carruseles del mes', 'diseno', 'por_hacer', 0, hace: 'ej-sofia'),
  _ent('d4', 'Sesión de grabación', 'grabacion', 'por_hacer', 4, hace: 'ej-alex'),
  _ent('d5', 'Ediciones del mes', 'edicion', 'en_revision', 13, hace: 'ej-alex', revisa: 'ejemplo-admin'),
].map(Entregable.desdeFila).toList();
final _extraProyectos = [
  proyectosProvider.overrideWith((ref) async => Datos(_proyectos)),
  pendientesPorProyectoProvider.overrideWith((ref) async => {'p1': _entregables.where((e) => e.estado != EstadoEntregable.aprobado).toList()}),
  proyectoProvider.overrideWith((ref, id) async => Datos(_proyectos.firstWhere((p) => p.id == id))),
  entregablesProvider.overrideWith((ref, id) async => Datos(id == 'p1' ? _entregables : <Entregable>[])),
  equipoProvider.overrideWith((ref) async => _equipoEj),
];

Future<void> _fuentes() async {
  Future<void> f(String familia, String ruta) async => (FontLoader(familia)..addFont(rootBundle.load(ruta))).load();
  await f('KnuckleDown', 'assets/fonts/KnuckleDown.otf');
  await f('Jost', 'assets/fonts/Jost-Variable.ttf');
  await f('JetBrainsMono', 'assets/fonts/JetBrainsMono-Variable.ttf');
  await f('packages/material_symbols_icons/MaterialSymbolsSharp', 'packages/material_symbols_icons/lib/fonts/MaterialSymbolsSharp.ttf');
}

Widget _conBarra(Perfil p, Destino actual, Widget pagina) =>
    Scaffold(body: pagina, bottomNavigationBar: RkBarraInferior(destinos: barraPara(p), actual: actual, onElegir: (_) {}));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _fuentes();
    reloj = () => DateTime(2026, 11, 9, 14); // lunes 9 nov, 2 p. m.
  });

  Future<void> captura(WidgetTester tester, String nombre, Widget pantalla, {required bool claro, Perfil? perfil, int ms = 1400, List extra = const [], Future<void> Function(WidgetTester)? accion}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 72, bottom: 48); // barra de estado y gestos
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'rk-tema': claro ? 'claro' : 'oscuro'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        sesionProvider.overrideWith((ref) => Stream.value(null)),
        perfilProvider.overrideWith((ref) async => perfil),
        ...extra.cast(),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaRakun(claro ? RkColors.claro : RkColors.oscuro),
        // "reducir movimiento": el ojo no explora ni parpadea, así la captura es siempre igual
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: pantalla,
      ),
    ));
    await tester.pump();
    // cuadro a cuadro (60 por segundo) como en un teléfono: el ojo usa resortes por cuadro
    for (var i = 0; i < ms ~/ 16; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (accion != null) {
      await accion(tester);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre-${claro ? 'claro' : 'oscuro'}.png'));
    await tester.pumpWidget(const SizedBox()); // suelta el ojo y sus temporizadores
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('entrada', (t) => captura(t, '01-entrada', const EntradaPage(), claro: false));

  for (final claro in [false, true]) {
    testWidgets('login ${claro ? 'claro' : 'oscuro'}', (t) => captura(t, '02-login', const LoginPage(), claro: claro));
    testWidgets('recuperar ${claro ? 'claro' : 'oscuro'}', (t) => captura(t, '03-recuperar', const RecuperarPage(), claro: claro));
    testWidgets('sin acceso ${claro ? 'claro' : 'oscuro'}', (t) => captura(t, '04-sin-acceso', const SinAccesoPage(), claro: claro));
    testWidgets('hoy admin ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '10-hoy-admin', _conBarra(_ejemploAdmin, Destino.hoy, const HoyPage()), claro: claro, perfil: _ejemploAdmin));
    testWidgets('hoy editor ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '11-hoy-editor', _conBarra(_ejemploEditor, Destino.hoy, const HoyPage()), claro: claro, perfil: _ejemploEditor));
    testWidgets('sección ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '20-seccion', _conBarra(_ejemploAdmin, Destino.solicitudes, const SeccionPendientePage(seccion: 'solicitudes')), claro: claro, perfil: _ejemploAdmin));
    testWidgets('sin permiso ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '21-sin-permiso', _conBarra(_ejemploEditor, Destino.mas, const SeccionPendientePage(seccion: 'solicitudes')), claro: claro, perfil: _ejemploEditor));
    testWidgets('solicitudes ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '50-solicitudes', _conBarra(_ejemploAdmin, Destino.solicitudes, const SolicitudesPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraSolicitudes));
    testWidgets('ficha de solicitud ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '51-solicitud', const FichaSolicitudPage(id: 'ej1'), claro: claro, perfil: _ejemploAdmin, extra: _extraSolicitudes));
    testWidgets('clientes ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '52-clientes', _conBarra(_ejemploAdmin, Destino.clientes, const ClientesPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraClientes));
    testWidgets('nuevo cliente ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '53-nuevo-cliente', _conBarra(_ejemploAdmin, Destino.clientes, const ClientesPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraClientes,
            accion: (t) => t.tap(find.bySemanticsLabel('Nuevo cliente'))));
    testWidgets('ficha de cliente ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '54-cliente', _conBarra(_ejemploAdmin, Destino.clientes, const ClientesPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraClientes,
            accion: (t) => t.tap(find.text('Marca Ejemplo'))));
    testWidgets('proyectos ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '60-proyectos', _conBarra(_ejemploAdmin, Destino.proyectos, const ProyectosPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraProyectos));
    testWidgets('ficha de proyecto ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '61-proyecto', const FichaProyectoPage(id: 'p1'), claro: claro, perfil: _ejemploAdmin, extra: _extraProyectos));
    testWidgets('entregable ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '62-entregable', const FichaProyectoPage(id: 'p1'), claro: claro, perfil: _ejemploAdmin, extra: _extraProyectos,
            accion: (t) => t.tap(find.text('Guiones del mes'))));
    testWidgets('más ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '30-mas', _conBarra(_ejemploAdmin, Destino.mas, const MasPage()), claro: claro, perfil: _ejemploAdmin));
    testWidgets('galería ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '40-galeria', _conBarra(_ejemploAdmin, Destino.mas, const GaleriaPage()), claro: claro, perfil: _ejemploAdmin));
  }
}
