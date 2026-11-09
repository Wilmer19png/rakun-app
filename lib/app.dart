import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navegacion/rutas.dart';
import 'design_system/apariencia.dart';
import 'design_system/tema.dart';
import 'design_system/tokens.dart';

class RakunApp extends ConsumerWidget {
  const RakunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'RAKÜN Studio',
      debugShowCheckedModeBanner: false,
      theme: temaRakun(RkColors.claro),
      darkTheme: temaRakun(RkColors.oscuro),
      themeMode: ref.watch(aparienciaProvider).modo,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
