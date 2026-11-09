import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/avatar.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/proyectos_repo.dart';
import '../domain/proyecto.dart';
import 'nuevo_proyecto_hoja.dart';

enum _Filtro {
  activos('Activos'),
  marca('Redes'),
  produccion('Producción'),
  web('Web'),
  mios('Míos'),
  terminados('Terminados');

  const _Filtro(this.nombre);
  final String nombre;
}

/// 03 · Proyectos: lista con filtro (activos, por mundo, míos, terminados), etapa y vencidos.
/// La pestaña Cotizaciones llega con P2.
class ProyectosPage extends ConsumerStatefulWidget {
  const ProyectosPage({super.key});

  @override
  ConsumerState<ProyectosPage> createState() => _ProyectosPageState();
}

class _ProyectosPageState extends ConsumerState<ProyectosPage> {
  _Filtro _filtro = _Filtro.activos;
  bool _buscando = false;
  String _q = '';

  bool _pasa(Proyecto p, _Filtro f, String? yo) => switch (f) {
        _Filtro.activos => p.estado == EstadoProyecto.activo,
        _Filtro.marca => p.mundo == Mundo.marca && p.estado != EstadoProyecto.terminado,
        _Filtro.produccion => p.mundo == Mundo.produccion && p.estado != EstadoProyecto.terminado,
        _Filtro.web => p.mundo == Mundo.web && p.estado != EstadoProyecto.terminado,
        _Filtro.mios => p.aCargo == yo && p.estado != EstadoProyecto.terminado,
        _Filtro.terminados => p.estado == EstadoProyecto.terminado,
      };

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final async = ref.watch(proyectosProvider);
    final pendientes = ref.watch(pendientesPorProyectoProvider).value ?? const {};
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final perfil = ref.watch(perfilProvider).value;
    final datos = async.value;
    final sinRed = ref.watch(sinConexionProvider) || (datos?.desdeCache ?? false);
    final editar = puede(perfil, 'proyectos', editar: true) && !sinRed;

    final barra = RkBarraGrande(
      titulo: 'Proyectos',
      indice: '03',
      atras: Navigator.canPop(context),
      acciones: [
        IconButton(
          tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
          icon: Icon(_buscando ? Symbols.close_sharp : Symbols.search_sharp),
          onPressed: () => setState(() {
            _buscando = !_buscando;
            if (!_buscando) _q = '';
          }),
        ),
        IconButton(tooltip: 'Actualizar', icon: const Icon(Symbols.refresh_sharp), onPressed: () => ref.invalidate(proyectosProvider)),
      ],
    );

    if (datos == null) {
      final cuerpo = async.hasError
          ? (async.error is SinPermiso
              ? RkSinPermiso(onIrAHoy: () => context.go('/hoy'))
              : RkError(mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(proyectosProvider)))
          : const RkEsqueleto();
      return CustomScrollView(slivers: [barra, SliverToBoxAdapter(child: cuerpo)]);
    }

    final buscados = datos.valor.where((p) => p.coincide(_q)).toList();
    final cuenta = {for (final f in _Filtro.values) f: buscados.where((p) => _pasa(p, f, perfil?.id)).length};
    final lista = buscados.where((p) => _pasa(p, _filtro, perfil?.id)).toList();

    return Stack(children: [
      RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () => ref.refresh(proyectosProvider.future),
        child: CustomScrollView(slivers: [
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
                  decoration: const InputDecoration(hintText: 'Proyecto, cliente, plan, etapa…', prefixIcon: Icon(Symbols.search_sharp)),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 6), children: [
                for (final f in _Filtro.values)
                  _Chip(
                    nombre: f.nombre,
                    cuenta: cuenta[f] ?? 0,
                    on: f == _filtro,
                    mundo: switch (f) {
                      _Filtro.marca => Mundo.marca,
                      _Filtro.produccion => Mundo.produccion,
                      _Filtro.web => Mundo.web,
                      _ => null,
                    },
                    onTap: () => setState(() => _filtro = f),
                  ),
              ]),
            ),
          ),
          if (datos.valor.isEmpty)
            const SliverToBoxAdapter(
              child: RkVacio(antes: 'Nada', rosa: 'arrancó aún.', texto: 'Crea el primero para un cliente, o registra el anticipo de una cotización y se crea solo.'),
            )
          else if (lista.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(RkSpace.g),
                child: Text(_q.isNotEmpty ? 'Nada con «$_q» en ${_filtro.nombre}.' : 'Nada en ${_filtro.nombre}.', style: RkType.body.copyWith(color: c.texto2)),
              ),
            )
          else
            SliverList.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) => _Fila(
                p: lista[i],
                vencidos: (pendientes[lista[i].id] ?? const []).where((e) => plazoDe(e) == Plazo.vencido).length,
                responsable: equipo.where((x) => x.id == lista[i].aCargo).firstOrNull,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ]),
      ),
      if (editar)
        Positioned(right: RkSpace.g, bottom: 16, child: RkFab(etiqueta: 'Nuevo proyecto', onPressed: () => mostrarNuevoProyecto(context))),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.nombre, required this.cuenta, required this.on, required this.onTap, this.mundo});
  final String nombre;
  final int cuenta;
  final bool on;
  final Mundo? mundo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        selected: on,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: on ? c.texto : Colors.transparent, border: Border.all(color: on ? c.texto : c.linea2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (mundo != null) ...[RkMundo(mundo!, conNombre: false), const SizedBox(width: 6)],
                Text(nombre, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: on ? c.fondo : c.texto2)),
                const SizedBox(width: 8),
                Text('$cuenta', style: RkType.mono11.copyWith(color: on ? c.fondo : c.texto3)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.p, required this.vencidos, this.responsable});
  final Proyecto p;
  final int vencidos;
  final Perfil? responsable;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return RkFila(
      titulo: p.nombre,
      onTap: () => context.push('/proyectos/${p.id}'),
      subtitulo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
          RkMundo(p.mundo),
          Text([p.clienteNombre ?? '—', ?p.plan].join(' · ')),
        ]),
        const SizedBox(height: 2),
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Etapa '),
          TextSpan(text: p.etapa ?? '—', style: TextStyle(color: c.texto, fontWeight: FontWeight.w500)),
          const TextSpan(text: ' · '),
          if (vencidos > 0) ...[
            // marca rosa: en tema claro el texto queda navy (regla de DESIGN.md)
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), color: RkColors.rosa)),
            TextSpan(text: vencidos == 1 ? '1 vencido' : '$vencidos vencidos', style: TextStyle(color: c.rosaTexto, fontWeight: FontWeight.w500)),
          ] else
            const TextSpan(text: 'al día'),
        ])),
      ]),
      final_: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (p.estado != EstadoProyecto.activo) ...[RkEtiqueta(p.estado.nombre, tono: RkTono.apagada), const SizedBox(width: 10)],
          if (responsable != null) avatarDe(responsable!, chico: true),
        ]),
      ),
    );
  }
}
