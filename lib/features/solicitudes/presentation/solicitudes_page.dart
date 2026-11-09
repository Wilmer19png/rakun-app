import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/sync/datos.dart';
import '../../../core/utils/abrir.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/solicitudes_repo.dart';
import '../domain/solicitud.dart';

/// 01 · Solicitudes · dirección A (aprobada): una pestaña por estado, filtro por mundo, buscador.
class SolicitudesPage extends ConsumerStatefulWidget {
  const SolicitudesPage({super.key});

  @override
  ConsumerState<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends ConsumerState<SolicitudesPage> {
  EstadoSolicitud _estado = EstadoSolicitud.nueva;
  Mundo? _mundo;
  bool _buscando = false;
  String _q = '';
  final _scroll = ScrollController();
  Set<String>? _vistas; // ids de solicitudes nuevas que ya estaban en pantalla
  int _llegaron = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _arriba() {
    _scroll.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    setState(() {
      _llegaron = 0;
      _estado = EstadoSolicitud.nueva;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final async = ref.watch(solicitudesProvider);
    final equipo = ref.watch(equipoProvider).value ?? const [];

    // llegó una solicitud nueva en vivo mientras se mira más abajo: píldora, sin mover la lista
    ref.listen(solicitudesProvider, (_, sig) {
      final ids = {for (final s in sig.value?.valor ?? const <Solicitud>[]) if (s.estado == EstadoSolicitud.nueva) s.id};
      if (_vistas != null) {
        final nuevas = ids.difference(_vistas!).length;
        if (nuevas > 0 && _scroll.hasClients && _scroll.offset > 40) setState(() => _llegaron += nuevas);
      }
      _vistas = ids;
    });

    final barra = RkBarraGrande(
      titulo: 'Solicitudes',
      indice: '01',
      acciones: [
        IconButton(
          tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
          icon: Icon(_buscando ? Symbols.close_sharp : Symbols.search_sharp),
          onPressed: () => setState(() {
            _buscando = !_buscando;
            if (!_buscando) _q = '';
          }),
        ),
        IconButton(tooltip: 'Actualizar', icon: const Icon(Symbols.refresh_sharp), onPressed: () => ref.invalidate(solicitudesProvider)),
      ],
    );

    Widget cuerpo;
    final datos = async.value;
    if (datos == null) {
      cuerpo = async.hasError
          ? (async.error is SinPermiso
              ? RkSinPermiso(onIrAHoy: () => context.go('/hoy'))
              : RkError(mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(solicitudesProvider)))
          : const RkEsqueleto();
      return CustomScrollView(slivers: [barra, SliverToBoxAdapter(child: cuerpo)]);
    }

    final todas = datos.valor.where((s) => (_mundo == null || s.mundo == _mundo) && s.coincide(_q)).toList();
    final cuenta = {for (final e in EstadoSolicitud.values) e: todas.where((s) => s.estado == e).length};
    final lista = todas.where((s) => s.estado == _estado).toList();

    return Stack(children: [
      RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () => ref.refresh(solicitudesProvider.future),
        child: CustomScrollView(controller: _scroll, slivers: [
          barra,
          if (datos.desdeCache) SliverToBoxAdapter(child: RkSinConexion(desde: horaCorta(datos.guardadoA!))),
          if (_buscando)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 0),
                child: TextField(
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(hintText: 'Nombre, ciudad, plan, enlace…', prefixIcon: Icon(Symbols.search_sharp)),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _Pestanas(actual: _estado, cuenta: cuenta, onElegir: (e) => setState(() => _estado = e))),
          SliverToBoxAdapter(child: _Mundos(actual: _mundo, onElegir: (m) => setState(() => _mundo = m))),
          if (datos.valor.isEmpty)
            const SliverToBoxAdapter(
              child: RkVacio(antes: 'Nadie', rosa: 'todavía.', texto: 'Cuando alguien toque «Quiero este plan» en la página, su solicitud aparece aquí y te avisamos.'),
            )
          else if (lista.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(RkSpace.g),
                child: Text(_q.isNotEmpty ? 'Nada con «$_q» en ${_estado.nombre}.' : 'Nadie en ${_estado.nombre}.', style: RkType.body.copyWith(color: c.texto2)),
              ),
            )
          else
            SliverList.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) => _Fila(s: lista[i], responsable: equipo.where((p) => p.id == lista[i].aCargo).firstOrNull?.primerNombre),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
      if (_llegaron > 0)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 100,
          left: 0,
          right: 0,
          child: Center(child: RkEnVivo(texto: _llegaron == 1 ? '1 solicitud nueva' : '$_llegaron solicitudes nuevas', onTap: _arriba)),
        ),
    ]);
  }
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.actual, required this.cuenta, required this.onElegir});
  final EstadoSolicitud actual;
  final Map<EstadoSolicitud, int> cuenta;
  final ValueChanged<EstadoSolicitud> onElegir;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
      height: 48,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final e in EstadoSolicitud.values)
          Semantics(
            selected: e == actual,
            button: true,
            child: InkWell(
              onTap: () => onElegir(e),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(border: e == actual ? const Border(bottom: BorderSide(color: RkColors.rosa, width: 3)) : null),
                child: Row(children: [
                  Text(e.pestana, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: e == actual ? c.texto : c.texto2)),
                  const SizedBox(width: 8),
                  Text('${cuenta[e] ?? 0}', style: RkType.mono11.copyWith(color: e == actual ? c.rosaTexto : c.texto3)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Mundos extends StatelessWidget {
  const _Mundos({required this.actual, required this.onElegir});
  final Mundo? actual;
  final ValueChanged<Mundo?> onElegir;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    Widget chip(Mundo? m, String nombre) {
      final on = m == actual;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          selected: on,
          button: true,
          child: InkWell(
            onTap: () => onElegir(m),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: on ? c.texto : Colors.transparent, border: Border.all(color: on ? c.texto : c.linea2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (m != null) ...[RkMundo(m, conNombre: false), const SizedBox(width: 6)],
                  Text(nombre, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: on ? c.fondo : c.texto2)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 6), children: [
        chip(null, 'Todos'),
        chip(Mundo.marca, 'Redes'),
        chip(Mundo.produccion, 'Producción'),
        chip(Mundo.web, 'Web'),
      ]),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.s, this.responsable});
  final Solicitud s;
  final String? responsable;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return RkFila(
      titulo: s.nombre,
      nueva: s.estado == EstadoSolicitud.nueva,
      onTap: () => context.push('/solicitudes/${s.id}'),
      subtitulo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
          if (s.mundo != null) RkMundo(s.mundo!),
          Text(s.plan ?? s.mundo?.nombre ?? '—'),
        ]),
        Text([s.ciudad ?? '—', '${s.enlaces.length} ${s.enlaces.length == 1 ? 'perfil' : 'perfiles'}', responsable ?? 'sin asignar'].join(' · ')),
        if (s.vinoDeAnuncio)
          Row(children: [
            Icon(Symbols.campaign_sharp, size: 18, color: c.esClaro ? c.texto2 : RkColors.rosa),
            const SizedBox(width: 4),
            Flexible(child: Text(textoPlano(s.anuncio ?? s.campana).isEmpty ? 'Anuncio de Meta' : textoPlano(s.anuncio ?? s.campana), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
      ]),
      final_: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(hace(s.creada).replaceFirst('hace ', ''), style: RkType.mono12.copyWith(color: c.texto2)),
        IconButton(tooltip: 'Llamar a ${s.nombre}', icon: const Icon(Symbols.call_sharp), onPressed: () => Abrir.llamar(s.telefono)),
      ]),
    );
  }
}
