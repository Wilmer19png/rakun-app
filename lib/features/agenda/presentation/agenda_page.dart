import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/abrir.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/agenda_repo.dart';
import '../domain/agenda.dart';
import 'programar_hoja.dart';

enum _Filtro { todo, grabaciones, reuniones }

/// 05 Grabaciones + 06 Reuniones en una sola agenda (viewShoots y viewMeetings de la web):
/// pedidas por clientes arriba, luego por día. El reloj de arriba muestra las anteriores.
class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  _Filtro _filtro = _Filtro.todo;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final anteriores = ref.watch(verAnterioresProvider);
    final gAsync = ref.watch(grabacionesProvider);
    final rAsync = ref.watch(reunionesProvider);
    final refs = ref.watch(referenciasAgendaProvider).value ?? const Referencias();
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final verG = puede(perfil, 'grabaciones') || (gAsync.value?.valor.isNotEmpty ?? false);
    final verR = puede(perfil, 'reuniones');
    final sinRed = ref.watch(sinConexionProvider) || (gAsync.value?.desdeCache ?? false) || (rAsync.value?.desdeCache ?? false);
    final editar = (puede(perfil, 'grabaciones', editar: true) || puede(perfil, 'reuniones', editar: true)) && !sinRed;

    final barra = RkBarraGrande(
      titulo: anteriores ? 'Anteriores' : 'Agenda',
      indice: '05·06',
      atras: Navigator.canPop(context),
      acciones: [
        IconButton(
          tooltip: anteriores ? 'Ver próximas' : 'Ver anteriores',
          isSelected: anteriores,
          icon: Icon(anteriores ? Symbols.event_upcoming_sharp : Symbols.history_sharp),
          onPressed: () => ref.read(verAnterioresProvider.notifier).poner(!anteriores),
        ),
      ],
    );

    if (gAsync.value == null) {
      final cuerpo = gAsync.hasError
          ? (gAsync.error is SinPermiso
              ? RkSinPermiso(onIrAHoy: () => context.go('/hoy'))
              : RkError(mensaje: textoDeError(gAsync.error), onReintentar: () => ref.invalidate(grabacionesProvider)))
          : const RkEsqueleto();
      return CustomScrollView(slivers: [barra, SliverToBoxAdapter(child: cuerpo)]);
    }

    final grabaciones = _filtro == _Filtro.reuniones ? const <Grabacion>[] : gAsync.value!.valor;
    final reparto = repartirReuniones(rAsync.value?.valor ?? const []);
    final reuniones = _filtro == _Filtro.grabaciones ? const <Reunion>[] : (anteriores ? reparto.anteriores : reparto.proximas);
    final pedidas = anteriores || _filtro == _Filtro.grabaciones ? const <Reunion>[] : reparto.pedidas;

    final eventos = [...grabaciones.map(Evento.grabacion), ...reuniones.where((m) => m.inicio != null).map(Evento.reunion)]
      ..sort((a, b) => anteriores ? b.inicio!.compareTo(a.inicio!) : a.inicio!.compareTo(b.inicio!));
    final dias = porDia(eventos);
    final sinFecha = anteriores ? reuniones.where((m) => m.inicio == null).toList() : const <Reunion>[];

    String cliente(String id) => refs.cliente(id)?.nombre ?? '—';

    final hijos = <Widget>[
      if (gAsync.value!.desdeCache) RkSinConexion(desde: horaCorta(gAsync.value!.guardadoA!)),
      if (verG && verR)
        SizedBox(
          height: 60,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 6), children: [
            _Chip(texto: 'Todo', on: _filtro == _Filtro.todo, onTap: () => setState(() => _filtro = _Filtro.todo)),
            _Chip(texto: 'Grabaciones', icono: Symbols.videocam_sharp, on: _filtro == _Filtro.grabaciones, onTap: () => setState(() => _filtro = _Filtro.grabaciones)),
            _Chip(texto: 'Reuniones', icono: Symbols.groups_sharp, on: _filtro == _Filtro.reuniones, onTap: () => setState(() => _filtro = _Filtro.reuniones)),
          ]),
        ),
      if (pedidas.isNotEmpty) ...[
        RkGrupo('Pedidas por clientes', cuenta: pedidas.length, urgente: true),
        for (final m in pedidas) FilaPedida(m: m, cliente: cliente(m.clienteId), onConfirmar: editar ? () => mostrarProgramar(context, reunion: m) : null),
      ],
      for (final (dia, lista) in dias) ...[
        RkGrupo(dia),
        for (final e in lista)
          e.g != null
              ? FilaGrabacion(g: e.g!, cliente: cliente(e.g!.clienteId))
              : FilaReunion(
                  m: e.r!,
                  cliente: cliente(e.r!.clienteId),
                  conQuien: equipo.where((p) => p.id == e.r!.conQuien).firstOrNull?.primerNombre,
                  onTap: editar ? () => mostrarProgramar(context, reunion: e.r) : null,
                ),
      ],
      if (sinFecha.isNotEmpty) ...[
        const RkGrupo('Sin fecha'),
        for (final m in sinFecha)
          FilaReunion(m: m, cliente: cliente(m.clienteId), onTap: editar ? () => mostrarProgramar(context, reunion: m) : null),
      ],
      if (eventos.isEmpty && pedidas.isEmpty && sinFecha.isEmpty)
        anteriores
            ? Padding(padding: const EdgeInsets.all(RkSpace.g), child: Text('Nada por aquí.', style: RkType.body.copyWith(color: c.texto2)))
            : RkVacio(antes: 'Agenda', rosa: 'libre.', texto: editar ? 'No hay grabaciones ni reuniones próximas. Programa una con el botón +.' : 'No hay grabaciones ni reuniones próximas.'),
      const SizedBox(height: 96),
    ];

    return Stack(children: [
      RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () async {
          ref.invalidate(grabacionesProvider);
          ref.invalidate(reunionesProvider);
          await ref.read(grabacionesProvider.future);
        },
        child: CustomScrollView(slivers: [barra, SliverList.list(children: hijos)]),
      ),
      if (editar)
        Positioned(
          right: RkSpace.g,
          bottom: 16,
          child: RkFab(etiqueta: 'Programar', onPressed: () => mostrarProgramar(context, reunionPrimero: _filtro == _Filtro.reuniones || !puede(perfil, 'grabaciones', editar: true))),
        ),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.on, required this.onTap, this.icono});
  final String texto;
  final bool on;
  final IconData? icono;
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
                if (icono != null) ...[Icon(icono, size: 18, color: on ? c.fondo : c.texto2), const SizedBox(width: 6)],
                Text(texto, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: on ? c.fondo : c.texto2)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// La hora a la izquierda, en dos líneas: "3:00" / "P. M.".
class _Hora extends StatelessWidget {
  const _Hora(this.d);
  final DateTime? d;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    if (d == null) {
      return SizedBox(
        width: 64,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('?', style: RkType.cifra.copyWith(color: c.rosaTexto)),
          Text('POR\nDEFINIR', style: RkType.mono11.copyWith(color: c.texto2)),
        ]),
      );
    }
    final h = horaCorta(d!);
    final i = h.indexOf(' ');
    return SizedBox(
      width: 64,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(i < 0 ? h : h.substring(0, i), style: RkType.cifra.copyWith(color: c.texto)),
        if (i > 0) Text(h.substring(i + 1).toUpperCase(), style: RkType.mono11.copyWith(color: c.texto2)),
      ]),
    );
  }
}

class FilaGrabacion extends StatelessWidget {
  const FilaGrabacion({super.key, required this.g, required this.cliente});
  final Grabacion g;
  final String cliente;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final resp = g.respuestaCliente;
    final aviso = g.pideOtraFecha;
    return RkFila(
      titulo: 'Grabación · $cliente',
      inicio: _Hora(g.inicio),
      onTap: () => context.push('/agenda/grabacion/${g.id}'),
      subtitulo: Text.rich(TextSpan(children: [
        WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Symbols.videocam_sharp, size: 16, color: c.texto2))),
        TextSpan(text: [g.duracion, g.lugar ?? 'Lugar por definir'].join(' · ')),
        if (g.estado != 'programada') TextSpan(text: ' · ${nombreEstadoGrabacion(g.estado).toLowerCase()}'),
        if (resp != null) ...[
          const TextSpan(text: ' · '),
          if (aviso) WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), color: RkColors.rosa)),
          TextSpan(text: resp, style: TextStyle(color: g.confirmo ? c.ok : aviso ? c.rosaTexto : c.texto2, fontWeight: aviso ? FontWeight.w500 : null)),
        ],
      ])),
      final_: g.paraMapa.isEmpty
          ? const SizedBox(width: 12)
          : IconButton(tooltip: 'Cómo llegar', onPressed: () => Abrir.mapa(g.paraMapa), icon: const Icon(Symbols.near_me_sharp)),
    );
  }
}

class FilaReunion extends StatelessWidget {
  const FilaReunion({super.key, required this.m, required this.cliente, this.conQuien, this.onTap});
  final Reunion m;
  final String cliente;
  final String? conQuien;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final enlace = m.enlace ?? '';
    return RkFila(
      titulo: '${m.titulo} · $cliente',
      inicio: _Hora(m.inicio),
      onTap: onTap,
      subtitulo: Text.rich(TextSpan(children: [
        WidgetSpan(alignment: PlaceholderAlignment.middle, child: Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Symbols.groups_sharp, size: 16, color: c.texto2))),
        TextSpan(text: [if (enlace.isNotEmpty) 'Meet', if (nombreTipoReunion(m.tipo) != m.titulo) nombreTipoReunion(m.tipo), '${m.minutos} min', ?conQuien, if (m.estado != 'confirmada') nombreEstadoReunion(m.estado).toLowerCase()].join(' · ')),
      ])),
      final_: enlace.isEmpty
          ? const SizedBox(width: 12)
          : IconButton(tooltip: 'Abrir Meet', onPressed: () => Abrir.enlace(enlace), icon: const Icon(Symbols.open_in_new_sharp)),
    );
  }
}

class FilaPedida extends StatelessWidget {
  const FilaPedida({super.key, required this.m, required this.cliente, this.onConfirmar});
  final Reunion m;
  final String cliente;
  final VoidCallback? onConfirmar;

  @override
  Widget build(BuildContext context) {
    return RkFila(
      titulo: m.titulo,
      inicio: const _Hora(null),
      onTap: onConfirmar,
      subtitulo: Text([cliente, if ((m.notaCliente ?? '').isNotEmpty) '“${m.notaCliente}”'].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      final_: Padding(padding: const EdgeInsets.only(right: 12, left: 8), child: RkEtiqueta('Confirmar', tono: onConfirmar == null ? RkTono.apagada : RkTono.accion)),
    );
  }
}
