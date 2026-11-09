import 'package:flutter/material.dart';

/// Tipografía aprobada. Tamaños en px lógicos: Flutter los escala con el tamaño de
/// letra del sistema (como sp). Jost y JetBrains Mono son variables: el peso se pide
/// con `fontWeight` y con el eje `wght`.
abstract final class RkType {
  static const kd = 'KnuckleDown';
  static const jost = 'Jost';
  static const mono = 'JetBrainsMono';

  static TextStyle _jost(double size, FontWeight w, double height) => TextStyle(
        fontFamily: jost,
        fontSize: size,
        fontWeight: w,
        height: height,
        fontVariations: [FontVariation('wght', w.value.toDouble())],
      );

  static TextStyle _mono(double size, FontWeight w, {double spacing = .04}) => TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: w,
        height: 1.25,
        letterSpacing: size * spacing,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: [FontVariation('wght', w.value.toDouble())],
      );

  /// Knuckle Down: un solo peso, siempre en MAYÚSCULAS (usar [mayus]).
  static TextStyle display(double size, {double height = .9}) =>
      TextStyle(fontFamily: kd, fontSize: size, height: height, letterSpacing: -.01 * size, fontWeight: FontWeight.w400);

  static final saludo = display(48, height: .86); // Hoy, entrada
  static final seccion = display(34); // título de sección
  static final ficha = display(30, height: .92); // nombre en una ficha (máx. 2 líneas)
  static final hoja = display(24, height: .95); // título de hoja inferior

  static final body = _jost(16, FontWeight.w400, 1.45);
  static final bodyMedio = _jost(16, FontWeight.w500, 1.3);
  static final small = _jost(14, FontWeight.w400, 1.35);
  static final boton = _jost(14, FontWeight.w500, 1).copyWith(letterSpacing: 14 * .08);

  static final mono12 = _mono(12, FontWeight.w500);
  static final mono11 = _mono(11, FontWeight.w500, spacing: .06);
  static final cifra = _mono(20, FontWeight.w500, spacing: -.02);
  static final cifraGrande = _mono(26, FontWeight.w500, spacing: -.02);
}

/// Knuckle Down solo va en mayúsculas (regla de la marca).
String mayus(String s) => s.toUpperCase();
