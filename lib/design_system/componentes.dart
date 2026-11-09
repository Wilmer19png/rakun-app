/// Componentes del sistema aprobado (DESIGN.md §5). Cada uno replica su par del
/// prototipo (design/proto/app.css). Radio 0, líneas de 1 px, toque mínimo 48.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'ojo/ojo.dart';
import 'tipografia.dart';
import 'tokens.dart';

/* ---------------- Índice de sección (00–12) ---------------- */
/// En oscuro: mono rosa. En claro: pastilla rosa con tinta navy (nunca rosa pequeño sobre crema).
class RkIndice extends StatelessWidget {
  const RkIndice(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final estilo = RkType.mono12;
    if (!c.esClaro) return Text(texto, style: estilo.copyWith(color: RkColors.rosa));
    return Container(
      color: RkColors.rosa,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(texto, style: estilo.copyWith(color: RkColors.navy)),
    );
  }
}

/* ---------------- Barra superior grande (se encoge al desplazar) ---------------- */
class RkBarraGrande extends StatelessWidget {
  const RkBarraGrande({super.key, required this.titulo, this.indice, this.acciones = const [], this.atras = false});
  final String titulo;
  final String? indice;
  final List<Widget> acciones;
  final bool atras;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _BarraDelegate(titulo: titulo, indice: indice, acciones: acciones, atras: atras, top: top),
    );
  }
}

class _BarraDelegate extends SliverPersistentHeaderDelegate {
  _BarraDelegate({required this.titulo, this.indice, required this.acciones, required this.atras, required this.top});
  final String titulo;
  final String? indice;
  final List<Widget> acciones;
  final bool atras;
  final double top;

  @override
  double get maxExtent => top + 48 + 52;
  @override
  double get minExtent => top + 48 + 34;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final c = RkColors.of(context);
    final t = (shrink / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final tam = 34 - 12 * t; // 34 → 22, como en el prototipo
    return Container(
      color: c.fondo,
      padding: EdgeInsets.only(top: top),
      decoration: null,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Row(children: [
                if (atras) const BackButton() else const SizedBox(width: RkSpace.g - 4),
                const Spacer(),
                ...acciones,
                const SizedBox(width: 4),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(RkSpace.g, 0, RkSpace.g, 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (indice != null) ...[RkIndice(indice!), const SizedBox(width: 10)],
                  Flexible(
                    child: Text(mayus(titulo), maxLines: 1, overflow: TextOverflow.ellipsis, style: RkType.display(tam).copyWith(color: c.texto)),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_BarraDelegate o) => o.titulo != titulo || o.indice != indice || o.top != top || o.acciones != acciones;
}

/* ---------------- Marca de mundo ---------------- */
class RkMundo extends StatelessWidget {
  const RkMundo(this.mundo, {super.key, this.conNombre = true});
  final Mundo mundo;
  final bool conNombre;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: mundo.color,
          border: c.esClaro ? Border.all(color: RkColors.navy.withValues(alpha: .45), width: 1) : null,
        ),
      ),
      if (conNombre) ...[const SizedBox(width: 6), Text(mundo.nombre.toUpperCase(), style: RkType.mono11.copyWith(color: c.texto2))],
    ]);
  }
}

/* ---------------- Etiqueta de estado ---------------- */
/// Amarillo, azul y rosa son de los mundos. Los estados son neutros; solo lo que
/// exige acción va relleno de rosa.
enum RkTono { accion, neutra, apagada, ok }

class RkEtiqueta extends StatelessWidget {
  const RkEtiqueta(this.texto, {super.key, this.tono = RkTono.neutra});
  final String texto;
  final RkTono tono;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final (fondo, tinta, borde) = switch (tono) {
      RkTono.accion => (RkColors.rosa, RkColors.navy, null),
      RkTono.ok => (c.ok, c.okSobre, null),
      RkTono.neutra => (Colors.transparent, c.texto, c.esClaro ? c.texto : c.texto2),
      RkTono.apagada => (Colors.transparent, c.texto2, c.linea2),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: fondo, border: borde == null ? null : Border.all(color: borde)),
      child: Center(widthFactor: 1, child: Text(texto.toUpperCase(), style: RkType.mono11.copyWith(color: tinta))),
    );
  }
}

/* ---------------- Encabezado de grupo ---------------- */
class RkGrupo extends StatelessWidget {
  const RkGrupo(this.titulo, {super.key, this.cuenta, this.urgente = false, this.accion, this.onAccion});
  final String titulo;
  final int? cuenta;
  final bool urgente;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final color = urgente && !c.esClaro ? RkColors.rosa : c.texto2;
    final estilo = RkType.mono12.copyWith(letterSpacing: 12 * .08, color: color);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 24, 4, 0),
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(children: [
        if (urgente && c.esClaro) ...[Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 6)],
        Expanded(child: Text(titulo.toUpperCase(), style: estilo)),
        if (accion != null)
          TextButton.icon(
            onPressed: onAccion,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Symbols.chevron_right_sharp, size: 20),
            label: Text(accion!, style: RkType.mono12.copyWith(color: c.texto2)),
          )
        else if (cuenta != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('$cuenta', style: estilo.copyWith(color: urgente && !c.esClaro ? RkColors.rosa : c.texto)),
          ),
      ]),
    );
  }
}

/* ---------------- Fila de lista ---------------- */
class RkFila extends StatelessWidget {
  const RkFila({super.key, required this.titulo, this.subtitulo, this.inicio, this.final_, this.onTap, this.nueva = false});
  final String titulo;
  final Widget? subtitulo;
  final Widget? inicio;
  final Widget? final_;
  final VoidCallback? onTap;
  final bool nueva;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: RkSpace.fila),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, 4, 12),
          child: Row(children: [
            if (nueva) ...[Container(width: 4, height: 4, color: RkColors.rosa), const SizedBox(width: 8)],
            if (inicio != null) ...[inicio!, const SizedBox(width: 12)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: RkType.bodyMedio.copyWith(color: c.texto)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(style: RkType.small.copyWith(color: c.texto2), child: subtitulo!),
                ],
              ]),
            ),
            ?final_,
          ]),
        ),
      ),
    );
  }
}

/* ---------------- Botón flotante: la única placa desplazada ---------------- */
class RkFab extends StatelessWidget {
  const RkFab({super.key, required this.onPressed, required this.etiqueta, this.icono = Symbols.add_sharp});
  final VoidCallback? onPressed;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      child: SizedBox(
        width: 61,
        height: 61,
        child: Stack(children: [
          Positioned(left: 5, top: 5, width: 56, height: 56, child: Container(color: RkColors.amarillo)),
          Positioned(
            left: 0,
            top: 0,
            width: 56,
            height: 56,
            child: Material(
              color: RkColors.rosa,
              child: InkWell(
                onTap: onPressed,
                child: Center(child: Icon(icono, size: 28, color: RkColors.navy, weight: 400)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/* ---------------- Estados ---------------- */
class RkVacio extends StatelessWidget {
  const RkVacio({super.key, required this.antes, required this.rosa, required this.texto, this.accion});
  final String antes; // "Todo"
  final String rosa; // "al día."
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 48, RkSpace.g, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const RakunOjo(ancho: 112),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '${mayus(antes)} '),
            TextSpan(text: mayus(rosa), style: const TextStyle(color: RkColors.rosa)), // tamaño display: permitido en crema
          ]),
          style: RkType.seccion.copyWith(color: c.texto),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: Text(texto, style: RkType.body.copyWith(color: c.texto2))),
        if (accion != null) ...[const SizedBox(height: 16), accion!],
      ]),
    );
  }
}

class RkEsqueleto extends StatelessWidget {
  const RkEsqueleto({super.key, this.filas = 6});
  final int filas;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    const anchos = [.58, .44, .66, .44, .58, .66];
    return Semantics(
      label: 'Cargando',
      child: Column(
        children: List.generate(filas, (i) {
          return Container(
            height: 64,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
            padding: const EdgeInsets.fromLTRB(RkSpace.g, 18, RkSpace.g, 0),
            alignment: Alignment.topLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FractionallySizedBox(widthFactor: anchos[i % anchos.length], child: Container(height: 10, color: c.s3)),
              const SizedBox(height: 10),
              FractionallySizedBox(widthFactor: .34, child: Container(height: 10, color: c.s2)),
            ]),
          );
        }),
      ),
    );
  }
}

class RkError extends StatelessWidget {
  const RkError({super.key, required this.mensaje, this.onReintentar, this.titulo = 'No pudimos traer esta lista.'});
  final String titulo;
  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      margin: const EdgeInsets.all(RkSpace.g),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: RkColors.rosa)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: RkType.bodyMedio.copyWith(color: c.texto)),
        const SizedBox(height: 8),
        Text(mensaje, style: RkType.small.copyWith(color: c.texto2)),
        if (onReintentar != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onReintentar, child: const Text('REINTENTAR'))],
      ]),
    );
  }
}

class RkSinConexion extends StatelessWidget {
  const RkSinConexion({super.key, required this.desde});
  final String desde; // "9:12 a. m."

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        color: RkColors.lila,
        padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 8),
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(children: [
          const Icon(Symbols.cloud_off_sharp, size: 20, color: RkColors.navy),
          const SizedBox(width: 10),
          Expanded(child: Text('Sin conexión desde las $desde · ves lo guardado; los cambios se activan al volver.', style: RkType.small.copyWith(color: RkColors.navy))),
        ]),
      ),
    );
  }
}

class RkSinPermiso extends StatelessWidget {
  const RkSinPermiso({super.key, this.onIrAHoy});
  final VoidCallback? onIrAHoy;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 48, RkSpace.g, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Symbols.lock_sharp, size: 40, color: RkColors.rosa),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(children: [const TextSpan(text: 'NO ESTÁ EN '), TextSpan(text: 'TUS PERMISOS.', style: const TextStyle(color: RkColors.rosa))]),
          style: RkType.seccion.copyWith(color: c.texto),
        ),
        const SizedBox(height: 16),
        Text('Esta sección no está habilitada para tu cuenta. Si la necesitas, pídele acceso a Wilmer.', style: RkType.body.copyWith(color: c.texto2)),
        if (onIrAHoy != null) ...[const SizedBox(height: 16), OutlinedButton(onPressed: onIrAHoy, child: const Text('IR A HOY'))],
      ]),
    );
  }
}

/// "Llegó algo en vivo": flota sobre la lista y no mueve lo que estás leyendo.
class RkEnVivo extends StatelessWidget {
  const RkEnVivo({super.key, required this.texto, required this.onTap});
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      button: true,
      child: Material(
        color: RkColors.rosa,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Symbols.arrow_upward_sharp, size: 20, color: RkColors.navy),
              const SizedBox(width: 6),
              Text(texto, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: RkColors.navy)),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ---------------- Hoja inferior ---------------- */
/// Editar sin perder el contexto: título Knuckle Down, cuerpo, botón principal fijo abajo.
Future<T?> mostrarHoja<T>(BuildContext context, {required String titulo, required Widget cuerpo, Widget? pie}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true, // encima de toda la app: tapa la barra inferior, como en el diseño
    builder: (ctx) {
      final c = RkColors.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .88),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(RkSpace.g, 0, 4, 8),
              child: Row(children: [
                Expanded(child: Text(mayus(titulo), style: RkType.hoja.copyWith(color: c.texto))),
                IconButton(onPressed: () => Navigator.pop(ctx), tooltip: 'Cerrar', icon: const Icon(Symbols.close_sharp)),
              ]),
            ),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 16), child: cuerpo)),
            if (pie != null)
              DecoratedBox(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.linea))),
                child: Padding(padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 16), child: pie),
              ),
          ]),
        ),
      );
    },
  );
}

/* ---------------- Franja de acciones de contacto (Llamar · WhatsApp · Correo) ---------------- */
class RkAccion {
  const RkAccion(this.texto, this.icono, this.onTap, {this.principal = false, this.colorIcono});
  final String texto;
  final IconData icono;
  final VoidCallback onTap;
  final bool principal;
  final Color? colorIcono;
}

/// Ícono arriba y palabra abajo: caben tres en 360 dp sin partir palabras.
class RkAcciones extends StatelessWidget {
  const RkAcciones(this.acciones, {super.key});
  final List<RkAccion> acciones;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: c.linea))),
      child: Row(children: [
        for (final a in acciones)
          Expanded(
            child: Material(
              color: a.principal ? RkColors.rosa : Colors.transparent,
              child: InkWell(
                onTap: a.onTap,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(border: Border(right: BorderSide(color: c.linea))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(a.icono, size: 26, color: a.principal ? RkColors.navy : (a.colorIcono ?? c.texto)),
                    const SizedBox(height: 6),
                    Text(a.texto.toUpperCase(), style: RkType.mono11.copyWith(color: a.principal ? RkColors.navy : c.texto)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/* ---------------- Opción de una hoja (estado, etapa, persona…) ---------------- */
class RkOpcion extends StatelessWidget {
  const RkOpcion({super.key, required this.child, required this.marcada, required this.onTap});
  final Widget child;
  final bool marcada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Semantics(
      selected: marcada,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
          // Align: la etiqueta conserva su tamaño (no se estira a todo el ancho)
          child: Row(children: [
            Expanded(child: Align(alignment: Alignment.centerLeft, child: child)),
            if (marcada) Icon(Symbols.check_sharp, color: c.rosaTexto),
          ]),
        ),
      ),
    );
  }
}

/// Hoja con una lista de opciones; devuelve la elegida (null si la cierran).
/// Con más de 8 opciones trae buscador (sin tildes: "bogota" encuentra "Bogotá").
Future<T?> elegirEnHoja<T>(
  BuildContext context, {
  required String titulo,
  required List<(T, String)> opciones,
  T? actual,
  String? ayuda,
  Widget Function(T valor, String nombre)? dibujar,
}) =>
    mostrarHoja<T>(context, titulo: titulo, cuerpo: _Opciones<T>(opciones: opciones, actual: actual, ayuda: ayuda, dibujar: dibujar));

class _Opciones<T> extends StatefulWidget {
  const _Opciones({required this.opciones, this.actual, this.ayuda, this.dibujar});
  final List<(T, String)> opciones;
  final T? actual;
  final String? ayuda;
  final Widget Function(T valor, String nombre)? dibujar;

  @override
  State<_Opciones<T>> createState() => _OpcionesState<T>();
}

class _OpcionesState<T> extends State<_Opciones<T>> {
  String _q = '';

  static String _plano(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .replaceAll('ñ', 'n');

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final q = _plano(_q.trim());
    final lista = widget.opciones.where((o) => q.isEmpty || _plano(o.$2).contains(q)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.ayuda != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(widget.ayuda!, style: RkType.small.copyWith(color: c.texto2))),
      if (widget.opciones.length > 8)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'Buscar…', prefixIcon: Icon(Symbols.search_sharp)),
          ),
        ),
      for (final o in lista)
        RkOpcion(
          marcada: o.$1 == widget.actual,
          onTap: () => Navigator.pop(context, o.$1),
          child: widget.dibujar?.call(o.$1, o.$2) ?? Text(o.$2, style: RkType.body.copyWith(color: c.texto)),
        ),
      if (lista.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Nada con «$_q».', style: RkType.body.copyWith(color: c.texto2))),
    ]);
  }
}

/* ---------------- Campo que se elige en una hoja (no se escribe) ---------------- */
class RkCampoElegible extends StatelessWidget {
  const RkCampoElegible({super.key, required this.texto, this.vacio = false, this.onTap});
  final String texto;
  final bool vacio; // texto en gris: todavía no se eligió nada
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: onTap == null ? c.linea : c.linea2)),
          child: Row(children: [
            Expanded(child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis, style: RkType.body.copyWith(color: vacio ? c.texto3 : c.texto))),
            Icon(Symbols.expand_more_sharp, size: 20, color: onTap == null ? c.texto3 : c.texto2),
          ]),
        ),
      ),
    );
  }
}

/* ---------------- Avatar: cuadrado con iniciales sobre el color de la persona ---------------- */
class RkAvatar extends StatelessWidget {
  const RkAvatar({super.key, required this.iniciales, this.colorHex, this.chico = false});
  final String iniciales;
  final String? colorHex;
  final bool chico;

  @override
  Widget build(BuildContext context) {
    final hex = colorHex;
    final color = hex != null && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex) ? Color(int.parse('FF${hex.substring(1)}', radix: 16)) : RkColors.lila;
    final lado = chico ? 24.0 : 32.0;
    return Container(
      width: lado,
      height: lado,
      color: color,
      alignment: Alignment.center,
      child: Text(iniciales, style: RkType.mono11.copyWith(color: RkColors.navy, fontWeight: FontWeight.w600)),
    );
  }
}
