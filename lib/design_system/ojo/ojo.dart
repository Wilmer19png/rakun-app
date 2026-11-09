/// El ojo de RAKÜN: puerto de rakun-web/eye.js (commit cd85fe1) con la MISMA geometría
/// (viewBox 212×140, corte diagonal) y los MISMOS resortes:
///   apertura k260/c18 (abrir k260/c11) · mirada k95/c15 · pupila k200/c18
///   parpadeo: cerrar k1600/c80, abrir k520/c30 · cada 3–6 s · explora cada 1,4–2,8 s.
/// Con "reducir movimiento" (Android: quitar animaciones) no parpadea ni explora y abre
/// con resorte rígido (k400/c40), como en la web.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens.dart';

/* ---------- geometría (idéntica a eye.js) ---------- */
const _viewW = 212.0;
const _viewH = 140.0;
const _slope = 0.612;
double _d(double x) => 14 + _slope * (x - 8); // borde exterior inferior
double _ds(double x) => _d(x) - 4; // borde inferior de la esclerótica

const _outer = (p0: Offset(10, 5), p1: Offset(100, 4), c1: Offset(152, 4), c2: Offset(182, 34), q: Offset(2, 9));
const _sclera = (p0: Offset(36, 12), p1: Offset(100, 12), c1: Offset(146, 12), c2: Offset(174, 36), q: Offset(26, 16));
const _tip = Offset(204, 134);
final _scleraTip = Offset(194, _ds(194));
const _irisRest = Offset(118, 76);
const _irisYellow = 58.0, _irisPink = 40.0, _irisPupil = 21.0;
const _range = (left: 52.0, right: 50.0, up: 38.0, down: 26.0);

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _clamp(double v, double lo, double hi) => math.min(hi, math.max(lo, v));
Offset _pt(Offset open, double o) => Offset(open.dx, _lerp(_ds(open.dx), open.dy, o));

Path _outerPath(double o) => Path()
  ..moveTo(_pt(_outer.p0, o).dx, _pt(_outer.p0, o).dy)
  ..lineTo(_pt(_outer.p1, o).dx, _pt(_outer.p1, o).dy)
  ..cubicTo(_pt(_outer.c1, o).dx, _pt(_outer.c1, o).dy, _pt(_outer.c2, o).dx, _pt(_outer.c2, o).dy, _tip.dx, _tip.dy)
  ..lineTo(8, 14)
  ..quadraticBezierTo(_pt(_outer.q, o).dx, _pt(_outer.q, o).dy, _pt(_outer.p0, o).dx, _pt(_outer.p0, o).dy)
  ..close();

Path _scleraPath(double o) => Path()
  ..moveTo(_pt(_sclera.p0, o).dx, _pt(_sclera.p0, o).dy)
  ..lineTo(_pt(_sclera.p1, o).dx, _pt(_sclera.p1, o).dy)
  ..cubicTo(_pt(_sclera.c1, o).dx, _pt(_sclera.c1, o).dy, _pt(_sclera.c2, o).dx, _pt(_sclera.c2, o).dy, _scleraTip.dx, _scleraTip.dy)
  ..lineTo(32, _ds(32))
  ..quadraticBezierTo(_pt(_sclera.q, o).dx, _pt(_sclera.q, o).dy, _pt(_sclera.p0, o).dx, _pt(_sclera.p0, o).dy)
  ..close();

/// Limita el centro del iris para que la pupila nunca salga del ojo.
Offset _clampIris(double x, double y) {
  final cx = _clamp(x, _irisRest.dx - _range.left, _irisRest.dx + _range.right);
  final cy = _clamp(y, _irisRest.dy - _range.up, _ds(cx) + 2);
  return Offset(cx, cy);
}

/// Resorte amortiguado (clase Spring de eye.js).
class Resorte {
  Resorte(this.valor, [this.k = 170, this.c = 14]) : objetivo = valor;
  double valor, objetivo, v = 0, k, c;

  void ir(double destino, [double? rigidez, double? amortiguacion]) {
    objetivo = destino;
    if (rigidez != null) k = rigidez;
    if (amortiguacion != null) c = amortiguacion;
  }

  void paso(double dt) {
    final a = k * (objetivo - valor) - c * v;
    v += a * dt;
    valor += v * dt;
  }

  bool get quieto => (objetivo - valor).abs() < .002 && v.abs() < .02;
}

/// El ojo vivo. [explora]: mira a puntos al azar. [abreAlEntrar]: empieza cerrado y se abre.
class RakunOjo extends StatefulWidget {
  const RakunOjo({super.key, this.ancho = 88, this.explora = true, this.abreAlEntrar = false, this.parpadea = true});

  final double ancho;
  final bool explora;
  final bool abreAlEntrar;
  final bool parpadea;

  @override
  State<RakunOjo> createState() => _RakunOjoState();
}

class _RakunOjoState extends State<RakunOjo> with SingleTickerProviderStateMixin {
  final _azar = math.Random();
  late final Resorte _abre = Resorte(widget.abreAlEntrar ? 0 : 1, 260, 18);
  final _ix = Resorte(_irisRest.dx, 95, 15);
  final _iy = Resorte(_irisRest.dy, 95, 15);
  final _pupila = Resorte(1, 200, 18);
  late final Ticker _ticker = createTicker(_tick);
  Duration _ultimo = Duration.zero;
  double _ahora = 0; // ms desde que se montó
  double _proxParpadeo = 0, _proxMirada = 0;
  bool _parpadeando = false;

  bool get _quieto => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _proxParpadeo = _rand(3000, 6000);
    _ticker.start();
    if (widget.abreAlEntrar) Future.delayed(const Duration(milliseconds: 180), _abrir);
  }

  double _rand(double a, double b) => a + _azar.nextDouble() * (b - a);

  void _abrir() {
    if (!mounted) return;
    final rm = _quieto;
    _abre.ir(1, rm ? 400 : 260, rm ? 40 : 11);
  }

  Future<void> parpadear() async {
    if (_parpadeando || _abre.objetivo < .5) return;
    _parpadeando = true;
    _abre.ir(0, 1600, 80);
    await Future.delayed(const Duration(milliseconds: 160));
    await Future.delayed(const Duration(milliseconds: 40));
    if (mounted) _abre.ir(1, 520, 30);
    _parpadeando = false;
  }

  void _mirar(double nx, double ny) {
    final tx = _irisRest.dx + nx * (nx < 0 ? _range.left : _range.right);
    final ty = _irisRest.dy + ny * (ny < 0 ? _range.up : _range.down);
    final p = _clampIris(tx, ty);
    _ix.ir(p.dx);
    _iy.ir(p.dy);
  }

  void _tick(Duration t) {
    final dt = _ultimo == Duration.zero ? 1 / 60 : math.min(1 / 30, (t - _ultimo).inMicroseconds / 1e6);
    _ultimo = t;
    _ahora = t.inMicroseconds / 1000;
    final rm = _quieto;
    if (!rm && widget.explora && _ahora > _proxMirada) {
      _mirar(_rand(-1, 1), _rand(-1, .8));
      _proxMirada = _ahora + _rand(1400, 2800);
    }
    if (!rm && widget.parpadea && _ahora > _proxParpadeo && _abre.objetivo > .5) {
      parpadear();
      _proxParpadeo = _ahora + _rand(3000, 6000);
    }
    _abre.paso(dt);
    _ix.paso(dt);
    _iy.paso(dt);
    _pupila.paso(dt);
    setState(() {});
    // sin nada que mover (reducir movimiento y todo quieto): se detiene para ahorrar batería
    if (rm && _abre.quieto && _ix.quieto && _iy.quieto) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true, // decorativo, como aria-hidden en la web
      child: GestureDetector(
        onTap: parpadear,
        child: SizedBox(
          width: widget.ancho,
          height: widget.ancho * _viewH / _viewW,
          child: CustomPaint(
            painter: _OjoPainter(
              abre: _clamp(_abre.valor, 0, 1.08),
              iris: Offset(_ix.valor, _iy.valor),
              pupila: _pupila.valor,
            ),
          ),
        ),
      ),
    );
  }
}

class _OjoPainter extends CustomPainter {
  _OjoPainter({required this.abre, required this.iris, required this.pupila});
  final double abre, pupila;
  final Offset iris;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewW, size.height / _viewH);
    final exterior = _outerPath(abre);
    canvas.drawPath(exterior, Paint()..color = RkColors.navy);
    canvas.drawPath(
      exterior,
      Paint()
        ..color = RkColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      Offset(26, _d(26) - 2),
      Offset(207, _d(207) - 2),
      Paint()
        ..color = RkColors.rosa
        ..strokeWidth = 3.6
        ..strokeCap = StrokeCap.round,
    );
    final esclera = _scleraPath(abre);
    canvas.drawPath(esclera, Paint()..color = RkColors.azul);
    canvas.clipPath(esclera);
    final r = _irisPupil * pupila;
    canvas.drawCircle(iris, _irisYellow, Paint()..color = RkColors.amarillo);
    canvas.drawCircle(iris, _irisPink, Paint()..color = RkColors.rosa);
    canvas.drawCircle(iris, r + 3.5, Paint()..color = Colors.white);
    canvas.drawCircle(iris, r, Paint()..color = RkColors.navy);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OjoPainter o) => o.abre != abre || o.iris != iris || o.pupila != pupila;
}
