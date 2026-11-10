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
import 'package:app/features/agenda/data/agenda_repo.dart';
import 'package:app/features/agenda/domain/agenda.dart';
import 'package:app/features/agenda/presentation/agenda_page.dart';
import 'package:app/features/agenda/presentation/grabacion_page.dart';
import 'package:app/features/auth/presentation/entrada_page.dart';
import 'package:app/features/auth/presentation/login_page.dart';
import 'package:app/features/auth/presentation/recuperar_page.dart';
import 'package:app/features/auth/presentation/sin_acceso_page.dart';
import 'package:app/features/galeria/presentation/galeria_page.dart';
import 'package:app/features/hoy/data/hoy_repo.dart';
import 'package:app/features/hoy/domain/tarea.dart';
import 'package:app/features/hoy/presentation/hoy_page.dart';
import 'package:app/features/hoy/presentation/tarea_page.dart';
import 'package:app/features/mas/presentation/mas_page.dart';
import 'package:app/features/seccion/presentation/seccion_pendiente_page.dart';
import 'package:app/core/supabase/equipo.dart';
import 'package:app/core/sync/datos.dart';
import 'package:app/core/utils/fechas.dart';
import 'package:app/features/clientes/data/clientes_repo.dart';
import 'package:app/features/clientes/domain/cliente.dart';
import 'package:app/features/clientes/presentation/clientes_page.dart';
import 'package:app/features/parrillas/data/parrilla_repo.dart';
import 'package:app/features/parrillas/domain/pieza.dart';
import 'package:app/features/parrillas/presentation/parrilla_page.dart';
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

/// Hoy DE EJEMPLO (como el prototipo aprobado), con el reloj fijo: lunes 9 nov, 2 p. m.
final _a14 = DateTime(2026, 11, 9, 14);
Map<String, dynamic> _tar(String id, String titulo, String tipo, String estado, Duration vence,
        {required String pid, required String proyecto, required String mundo, required String cliente, String? hace, String? revisa, String? nota, num? pago, String? notaPago, num? ronda}) =>
    {
      'id': id, 'project_id': pid, 'title': titulo, 'kind': tipo, 'status': estado, 'assignee_id': hace, 'reviewer_id': revisa,
      'due_at': _a14.add(vence).toUtc().toIso8601String(), 'brief_url': 'https://docs.google.com/document/d/brief-ejemplo',
      'delivery_note': nota, 'delivery_url': nota == null ? null : 'https://frame.io/ediciones-ejemplo',
      'delivered_at': nota == null ? null : DateTime(2026, 11, 9, 8, 40).toUtc().toIso8601String(),
      'pay_amount': pago, 'pay_note': notaPago, 'round_pay': ronda,
      'projects': {'id': pid, 'name': proyecto, 'world': mundo, 'clients': {'name': cliente}},
    };
final _tareasFilas = [
  _tar('h1', 'Guiones del mes', 'guion', 'en_curso', const Duration(hours: -20), pid: 'p1', proyecto: 'Redes · noviembre', mundo: 'marca', cliente: 'Marca Ejemplo',
      hace: 'ejemplo-admin', revisa: 'ej-sofia', nota: null, pago: 400000, notaPago: '16 guiones'),
  _tar('h2', 'Wireframe', 'diseno', 'por_hacer', const Duration(days: -3), pid: 'p2', proyecto: 'Página de citas', mundo: 'web', cliente: 'Consultorio Ejemplo', hace: 'ejemplo-admin'),
  _tar('h3', 'Ediciones del mes', 'edicion', 'en_revision', const Duration(days: 2), pid: 'p1', proyecto: 'Redes · noviembre', mundo: 'marca', cliente: 'Marca Ejemplo',
      hace: 'ej-alex', revisa: 'ejemplo-admin', nota: 'Van 12 de 14, faltan 2 Premium', pago: 588000, ronda: 18000),
  _tar('h4', 'Carruseles del mes', 'diseno', 'por_hacer', const Duration(hours: 4), pid: 'p1', proyecto: 'Redes · noviembre', mundo: 'marca', cliente: 'Marca Ejemplo', hace: 'ejemplo-admin'),
  _tar('h5', 'Montaje · versión 2', 'edicion', 'en_curso', const Duration(hours: 4, minutes: 1), pid: 'p3', proyecto: 'Videoclip «Ejemplo»', mundo: 'produccion', cliente: 'Colectivo Ejemplo', hace: 'ejemplo-admin'),
];
final _tareas = [for (final f in _tareasFilas) Tarea.desdeFila(f, yo: 'ejemplo-admin')];
final _leadsHoy = [
  _lead('ej1', 'Ana Ejemplo', 'marca', 'Gestión completa · Equilibrio', 'nueva', 0),
  _lead('ej2', 'Dr. Ejemplo Pérez', 'web', 'Página de citas', 'nueva', 0, anuncio: 'Médicos · ejemplo'),
].map((f) => Solicitud.desdeFila({...f, 'created_at': _a14.subtract(Duration(minutes: f['id'] == 'ej1' ? 12 : 130)).toUtc().toIso8601String()})).toList();
final _extraHoy = [
  tareasProvider.overrideWith((ref) async => Datos(_tareas)),
  tareaProvider.overrideWith((ref, id) async => Datos(_tareas.firstWhere((t) => t.id == id))),
  solicitudesProvider.overrideWith((ref) async => Datos(_leadsHoy)),
  mensajesSinVerProvider.overrideWith((ref) async => [
        MensajeSinVer(id: 'm1', autor: 'ej-sofia', texto: 'El lunes cambiamos la grabación de Marca Ejemplo a las 10 a. m. por la luz del estudio.', paraMi: false, creado: _a14),
      ]),
  gananciasProvider.overrideWith((ref) async => const Ganancias(aprobadas: 300000, comisiones: 186000, enCurso: 212000)),
  equipoProvider.overrideWith((ref) async => _equipoEj),
  agendaDeHoyProvider.overrideWith((ref) async => (hoy: [Evento.grabacion(_grabaciones.first)], pedidas: [_reuniones.first])),
  referenciasAgendaProvider.overrideWith((ref) async => _refsAg),
];
/// Agenda DE EJEMPLO (como el prototipo aprobado).
const _refsAg = Referencias(
  clientes: [
    (id: 'c1', nombre: 'Marca Ejemplo', telefono: '3000000000'),
    (id: 'c2', nombre: 'Consultorio Ejemplo', telefono: null),
    (id: 'c3', nombre: 'Videoclip Ejemplo', telefono: '3000000000'),
    (id: 'c4', nombre: 'Mentor Ejemplo', telefono: null),
  ],
  proyectos: [(id: 'p1', nombre: 'Redes · noviembre', clienteId: 'c1')],
);
final _grabaciones = [
  Grabacion(id: 'g1', clienteId: 'c1', proyectoId: 'p1', inicio: DateTime(2026, 11, 9, 15), horas: 3, lugar: 'Estudio Ejemplo', direccion: 'Calle Ejemplo # 00-00, Manizales',
      equipo: const ['ej-alex', 'ej-sofia'], prepara: const ['3 cambios de ropa en colores lisos', 'Revisar los guiones que le enviamos', 'Llegar sin maquillaje pesado'], respuesta: 'confirmada'),
  Grabacion(id: 'g2', clienteId: 'c3', inicio: DateTime(2026, 11, 12, 9), horas: 8, lugar: 'Locación Ejemplo', equipo: const ['ej-alex'], respuesta: 'reprogramar'),
];
final _reuniones = [
  const Reunion(id: 'r1', clienteId: 'c2', titulo: 'Revisión del diseño', tipo: 'revision', estado: 'solicitada', notaCliente: 'Quiero revisar el diseño antes del viernes.'),
  Reunion(id: 'r2', clienteId: 'c4', titulo: 'Reporte del mes', tipo: 'reporte', inicio: DateTime(2026, 11, 10, 10), minutos: 20, enlace: 'https://meet.google.com/ejemplo', conQuien: 'ej-sofia'),
];
final _extraAgenda = [
  grabacionesProvider.overrideWith((ref) async => Datos(_grabaciones)),
  reunionesProvider.overrideWith((ref) async => Datos(_reuniones)),
  grabacionProvider.overrideWith((ref, id) async => Datos(_grabaciones.firstWhere((g) => g.id == id))),
  referenciasAgendaProvider.overrideWith((ref) async => _refsAg),
  equipoProvider.overrideWith((ref) async => _equipoEj),
];

/// Parrilla DE EJEMPLO (como el prototipo aprobado).
const ProyectoRedes _pRedes = (id: 'p1', nombre: 'Redes · noviembre', clienteId: 'c1', cliente: 'Marca Ejemplo');
Pieza _pz(String id, String titulo, String formato, String estado, DateTime cuando, List<String> redes, {String? aCargo, bool pauta = false, String? nota}) => Pieza.desdeFila({
      'id': id, 'project_id': 'p1', 'client_id': 'c1', 'publish_at': cuando.toUtc().toIso8601String(), 'title': titulo, 'format': formato,
      'networks': redes, 'status': estado, 'assigned_to': aCargo, 'has_ads': pauta, 'client_note': nota, 'copy': 'Texto de ejemplo para la pieza.',
    });
final _piezas = [
  _pz('z1', 'rutina de 15 min', 'carrusel', 'aprobada', DateTime(2026, 11, 3, 12), ['IG', 'FB']),
  _pz('z2', '“3 errores al entrenar”', 'reel', 'lista', DateTime(2026, 11, 10, 18, 30), ['IG', 'TT'], aCargo: 'ej-alex'),
  _pz('z3', 'rutina de 15 min', 'carrusel', 'por_aprobar', DateTime(2026, 11, 10, 12), ['IG', 'FB']),
  _pz('z4', 'detrás de cámara', 'reel', 'cambios', DateTime(2026, 11, 12, 18, 30), ['IG', 'TT'], nota: 'Que se vea más el producto'),
  _pz('z5', 'encuesta', 'historias', 'borrador', DateTime(2026, 11, 14, 9), ['IG']),
  _pz('z6', 'testimonio', 'reel', 'lista', DateTime(2026, 11, 14, 18, 30), ['IG', 'TT', 'YT'], pauta: true),
];
final _extraParrilla = [
  proyectosRedesProvider.overrideWith((ref) async => const Datos([_pRedes])),
  piezasProvider.overrideWith((ref, clave) async => Datos(_piezas)),
  equipoProvider.overrideWith((ref) async => _equipoEj),
];

final _extraHoyVacio = [
  agendaDeHoyProvider.overrideWith((ref) async => (hoy: const <Evento>[], pedidas: const <Reunion>[])),
  tareasProvider.overrideWith((ref) async => const Datos(<Tarea>[])),
  mensajesSinVerProvider.overrideWith((ref) async => const <MensajeSinVer>[]),
  gananciasProvider.overrideWith((ref) async => const Ganancias()),
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
        (t) => captura(t, '10-hoy-admin', _conBarra(_ejemploAdmin, Destino.hoy, const HoyPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraHoy));
    testWidgets('hoy editor ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '11-hoy-editor', _conBarra(_ejemploEditor, Destino.hoy, const HoyPage()), claro: claro, perfil: _ejemploEditor, extra: _extraHoyVacio));
    testWidgets('hoy entregar ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '12-hoy-entregar', _conBarra(_ejemploAdmin, Destino.hoy, const HoyPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraHoy,
            accion: (t) => t.tap(find.byTooltip('Entregar').first)));
    testWidgets('tarea ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '13-tarea', const TareaPage(id: 'h1'), claro: claro, perfil: _ejemploAdmin, extra: _extraHoy));
    testWidgets('revisar ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '14-revisar', const RevisarPage(id: 'h3'), claro: claro, perfil: _ejemploAdmin, extra: _extraHoy));
    testWidgets('devolver ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '15-devolver', const RevisarPage(id: 'h3'), claro: claro, perfil: _ejemploAdmin, extra: _extraHoy,
            accion: (t) => t.tap(find.text('DEVOLVER'))));
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
    testWidgets('agenda ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '70-agenda', _conBarra(_ejemploAdmin, Destino.agenda, const AgendaPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraAgenda));
    testWidgets('agenda confirmar ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '71-agenda-confirmar', _conBarra(_ejemploAdmin, Destino.agenda, const AgendaPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraAgenda,
            accion: (t) => t.tap(find.text('Revisión del diseño'))));
    testWidgets('agenda programar ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '72-agenda-programar', _conBarra(_ejemploAdmin, Destino.agenda, const AgendaPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraAgenda,
            accion: (t) => t.tap(find.bySemanticsLabel('Programar'))));
    testWidgets('grabación ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '73-grabacion', const GrabacionPage(id: 'g1'), claro: claro, perfil: _ejemploAdmin, extra: _extraAgenda));
    testWidgets('parrilla ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '80-parrilla', _conBarra(_ejemploAdmin, Destino.mas, const ParrillaPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraParrilla));
    testWidgets('parrilla mes ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '81-parrilla-mes', _conBarra(_ejemploAdmin, Destino.mas, const ParrillaPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraParrilla,
            accion: (t) => t.tap(find.byTooltip('Mes'))));
    testWidgets('pieza ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '82-pieza', _conBarra(_ejemploAdmin, Destino.mas, const ParrillaPage()), claro: claro, perfil: _ejemploAdmin, extra: _extraParrilla,
            accion: (t) async {
              await t.scrollUntilVisible(find.text('Reel · detrás de cámara'), 200, scrollable: find.byType(Scrollable).first);
              await t.tap(find.text('Reel · detrás de cámara'));
            }));
    testWidgets('más ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '30-mas', _conBarra(_ejemploAdmin, Destino.mas, const MasPage()), claro: claro, perfil: _ejemploAdmin));
    testWidgets('galería ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '40-galeria', _conBarra(_ejemploAdmin, Destino.mas, const GaleriaPage()), claro: claro, perfil: _ejemploAdmin));
  }
}
