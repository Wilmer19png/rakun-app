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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ejemploAdmin = Perfil(id: 'ejemplo-admin', rol: 'admin', nombre: 'Wilmer Ejemplo', area: 'Dirección', color: '#FF2C68');
final _ejemploEditor = Perfil(id: 'ejemplo-editor', rol: 'equipo', nombre: 'Alexander Ejemplo', area: 'Edición', color: '#2BCDFF', perms: presets['editor']!.perms);

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
  });

  Future<void> captura(WidgetTester tester, String nombre, Widget pantalla, {required bool claro, Perfil? perfil, int ms = 1400}) async {
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
    testWidgets('más ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '30-mas', _conBarra(_ejemploAdmin, Destino.mas, const MasPage()), claro: claro, perfil: _ejemploAdmin));
    testWidgets('galería ${claro ? 'claro' : 'oscuro'}',
        (t) => captura(t, '40-galeria', _conBarra(_ejemploAdmin, Destino.mas, const GaleriaPage()), claro: claro, perfil: _ejemploAdmin));
  }
}
