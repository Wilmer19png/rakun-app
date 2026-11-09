import 'package:flutter/material.dart';

/// Colores del sistema aprobado (DESIGN.md, 2026-11-09). Dos temas.
/// La barra inferior y la entrada usan siempre la noche (ver [RkColors.noche]).
@immutable
class RkColors extends ThemeExtension<RkColors> {
  const RkColors({
    required this.fondo,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.texto,
    required this.texto2,
    required this.texto3,
    required this.ok,
    required this.okSobre,
    required this.linea,
    required this.linea2,
    required this.rosaTexto,
    required this.esClaro,
  });

  // comunes (no cambian con el tema)
  static const rosa = Color(0xFFFF2C68);
  static const amarillo = Color(0xFFFFF02B);
  static const azul = Color(0xFF2BCDFF);
  static const navy = Color(0xFF1B1A35); // tinta sobre color, párpado y pupila del ojo
  static const noche = Color(0xFF010221);
  static const lila = Color(0xFFC3C0DD); // franja sin conexión (los dos temas)
  static const propuesta = Color(0xFF8B6CF0);

  final Color fondo, s1, s2, s3, texto, texto2, texto3, ok, okSobre, linea, linea2;

  /// Rosa como TEXTO. En claro pasa a navy (regla: nunca rosa pequeño sobre crema).
  final Color rosaTexto;
  final bool esClaro;

  static const oscuro = RkColors(
    fondo: noche,
    s1: Color(0xFF0A0A2B),
    s2: Color(0xFF14132B),
    s3: navy,
    texto: Color(0xFFFFFFFF),
    texto2: lila,
    texto3: Color(0xFF9A97BD),
    ok: Color(0xFF4FB58C),
    okSobre: noche,
    linea: Color(0x24FFFFFF), // 14 %
    linea2: Color(0x47FFFFFF), // 28 %
    rosaTexto: rosa,
    esClaro: false,
  );

  static const claro = RkColors(
    fondo: Color(0xFFF3F0EA),
    s1: Color(0xFFFFFFFF),
    s2: Color(0xFFE8E4DB),
    s3: Color(0xFFDCD7CC),
    texto: navy,
    texto2: Color(0xFF3C3A5C),
    texto3: Color(0xFF5C5980),
    ok: Color(0xFF17664A),
    okSobre: Color(0xFFFFFFFF),
    linea: Color(0x291B1A35), // 16 %
    linea2: Color(0x571B1A35), // 34 %
    rosaTexto: navy,
    esClaro: true,
  );

  static RkColors of(BuildContext context) => Theme.of(context).extension<RkColors>()!;

  @override
  RkColors copyWith() => this;

  @override
  RkColors lerp(ThemeExtension<RkColors>? other, double t) => t < .5 ? this : (other as RkColors? ?? this);
}

/// Mundo de cada cosa: Marca (amarillo), Producción (azul), Web (rosa).
enum Mundo {
  marca('Redes', RkColors.amarillo),
  produccion('Producción', RkColors.azul),
  web('Web', RkColors.rosa);

  const Mundo(this.nombre, this.color);
  final String nombre;
  final Color color;

  static Mundo? desde(String? clave) => switch (clave) {
        'marca' => Mundo.marca,
        'produccion' => Mundo.produccion,
        'web' => Mundo.web,
        _ => null,
      };
}

/// Espacios (grilla de 4) y medidas táctiles.
abstract final class RkSpace {
  static const g = 16.0; // margen lateral
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s24 = 24.0, s32 = 32.0, s48 = 48.0;
  static const toque = 48.0;
  static const fila = 64.0;
  static const barra = 64.0;
}
