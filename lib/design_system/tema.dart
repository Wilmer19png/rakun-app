import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tipografia.dart';
import 'tokens.dart';

/// Tema Material 3 con la marca: radio 0, sin sombras difusas, líneas de 1 px.
ThemeData temaRakun(RkColors c) {
  const recto = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final esquema = ColorScheme(
    brightness: c.esClaro ? Brightness.light : Brightness.dark,
    primary: RkColors.rosa,
    onPrimary: RkColors.navy,
    secondary: c.texto,
    onSecondary: c.fondo,
    error: RkColors.rosa,
    onError: RkColors.navy,
    surface: c.fondo,
    onSurface: c.texto,
    onSurfaceVariant: c.texto2,
    surfaceContainerLowest: c.fondo,
    surfaceContainerLow: c.s1,
    surfaceContainer: c.s2,
    surfaceContainerHigh: c.s2,
    surfaceContainerHighest: c.s3,
    outline: c.linea2,
    outlineVariant: c.linea,
    inverseSurface: c.texto,
    onInverseSurface: c.fondo,
    surfaceTint: Colors.transparent,
  );

  final texto = TextTheme(
    displayLarge: RkType.saludo.copyWith(color: c.texto),
    headlineLarge: RkType.seccion.copyWith(color: c.texto),
    headlineMedium: RkType.ficha.copyWith(color: c.texto),
    titleLarge: RkType.hoja.copyWith(color: c.texto),
    titleMedium: RkType.bodyMedio.copyWith(color: c.texto),
    bodyLarge: RkType.body.copyWith(color: c.texto),
    bodyMedium: RkType.small.copyWith(color: c.texto2),
    labelLarge: RkType.boton,
    labelMedium: RkType.mono12.copyWith(color: c.texto2),
    labelSmall: RkType.mono11.copyWith(color: c.texto3),
  );

  final barraSistema = (c.esClaro ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: RkColors.noche, // la barra inferior es noche en los dos temas
    systemNavigationBarIconBrightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: c.fondo,
    canvasColor: c.fondo,
    fontFamily: RkType.jost,
    textTheme: texto,
    extensions: [c],
    splashFactory: InkRipple.splashFactory,
    dividerTheme: DividerThemeData(color: c.linea, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: c.fondo,
      foregroundColor: c.texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: barraSistema,
      shape: Border(bottom: BorderSide(color: c.linea)),
      titleTextStyle: RkType.bodyMedio.copyWith(fontSize: 18, color: c.texto),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: recto,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: RkColors.rosa,
        foregroundColor: RkColors.navy,
        disabledBackgroundColor: c.s2,
        disabledForegroundColor: c.texto3,
        textStyle: RkType.boton,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: recto,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        foregroundColor: c.texto,
        side: BorderSide(color: c.linea2),
        textStyle: RkType.boton,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: recto, minimumSize: const Size(48, 48), foregroundColor: c.texto, textStyle: RkType.boton),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: recto, minimumSize: const Size(48, 48), foregroundColor: c.texto),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: recto,
      backgroundColor: RkColors.rosa,
      foregroundColor: RkColors.navy,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.s1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: RkType.body.copyWith(color: c.texto3),
      labelStyle: RkType.mono12.copyWith(color: c.texto2),
      floatingLabelStyle: RkType.mono12.copyWith(color: c.texto2),
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: c.linea2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: c.linea2)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: RkColors.rosa, width: 2)),
      errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: RkColors.rosa)),
      focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: RkColors.rosa, width: 2)),
      errorStyle: RkType.small.copyWith(color: c.texto),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: RkColors.rosa,
      selectionColor: RkColors.rosa.withValues(alpha: .35),
      selectionHandleColor: RkColors.rosa,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.s2,
      modalBackgroundColor: c.s2,
      shape: const Border(top: BorderSide(color: RkColors.rosa, width: 3)),
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: c.texto3,
      dragHandleSize: const Size(40, 3),
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: (c.esClaro ? RkColors.navy : RkColors.noche).withValues(alpha: c.esClaro ? .55 : .72),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.texto,
      contentTextStyle: RkType.body.copyWith(color: c.fondo, fontSize: 15),
      actionTextColor: c.fondo,
      shape: recto,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(shape: recto, backgroundColor: c.s2, elevation: 0, surfaceTintColor: Colors.transparent),
    chipTheme: ChipThemeData(
      shape: recto,
      side: BorderSide(color: c.linea2),
      backgroundColor: Colors.transparent,
      selectedColor: c.texto,
      labelStyle: RkType.small.copyWith(fontWeight: FontWeight.w500, color: c.texto2),
      secondaryLabelStyle: RkType.small.copyWith(fontWeight: FontWeight.w500, color: c.fondo),
      showCheckmark: false,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: recto,
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? RkColors.rosa : Colors.transparent),
      checkColor: const WidgetStatePropertyAll(RkColors.navy),
      side: BorderSide(color: c.linea2, width: 1.5),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: RkColors.rosa),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(), // gesto Atrás predictivo de Android
    }),
  );
}
