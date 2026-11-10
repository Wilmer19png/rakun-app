import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/datos/parrilla_web.dart';
import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/parrilla_repo.dart';
import '../domain/pieza.dart';
import 'pieza_hoja.dart';

/// Etiqueta de estado: lo que pide acción (cambios) en rosa; aprobada en verde; lo demás neutro.
RkTono tonoPieza(String estado) => switch (estado) {
      'cambios' => RkTono.accion,
      'aprobada' => RkTono.ok,
      'borrador' || 'por_aprobar' => RkTono.apagada,
      _ => RkTono.neutra,
    };

/// Color de la marca de cada estado (contadores y calendario).
Color colorPieza(BuildContext context, String estado) {
  final c = RkColors.of(context);
  return switch (estado) {
    'cambios' => RkColors.rosa,
    'aprobada' => c.ok,
    'lista' => c.texto,
    'borrador' => c.texto3,
    _ => c.texto2,
  };
}

/// 04 · Parrilla (viewParrilla): proyecto de Redes + mes; lista por día o calendario del mes.
class ParrillaPage extends ConsumerStatefulWidget {
  const ParrillaPage({super.key});

  @override
  ConsumerState<ParrillaPage> createState() => _ParrillaPageState();
}

class _ParrillaPageState extends ConsumerState<ParrillaPage> {
  bool _mesCompleto = false; // vista calendario
  String? _red; // filtro "Ver red"

  Future<void> _nueva(ProyectoRedes p, DateTime mes, {DateTime? dia}) async {
    final hoy = reloj();
    final base = dia ?? (hoy.isAfter(mes) && hoy.isBefore(sumarMeses(mes, 1)) ? hoy : mes);
    final r = await mostrarPieza(context, proyecto: p, dia: base);
    if (r != null) ref.read(seleccionParrillaProvider.notifier).mes(r);
  }

  Future<void> _enviar(List<Pieza> listas) async {
    final ok = await mostrarHoja<bool>(
      context,
      titulo: 'Enviar al cliente',
      cuerpo: Text(
        '${listas.length == 1 ? 'La pieza lista pasa' : 'Las ${listas.length} piezas listas pasan'} a «Por aprobar» y el cliente ${listas.length == 1 ? 'la' : 'las'} ve en su portal para aprobar o pedir cambios.',
        style: RkType.body.copyWith(color: RkColors.of(context).texto2),
      ),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ENVIAR PARA APROBAR'))),
    );
    if (ok != true || !mounted) return;
    final m = ScaffoldMessenger.of(context);
    try {
      await ref.read(parrillaRepoProvider).enviarAlCliente([for (final p in listas) p.id]);
      ref.invalidate(piezasProvider);
      m.showSnackBar(SnackBar(content: Text('✓ Enviadas al cliente: ${listas.length}')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }

  Future<void> _duplicar(ProyectoRedes p, DateTime mes, List<Pieza> piezas) async {
    final m = ScaffoldMessenger.of(context);
    if (piezas.isEmpty) {
      m.showSnackBar(const SnackBar(content: Text('Este mes no tiene piezas para duplicar.')));
      return;
    }
    final sig = sumarMeses(mes, 1);
    final ok = await mostrarHoja<bool>(
      context,
      titulo: 'Duplicar el mes',
      cuerpo: Text('¿Copiar ${piezas.length == 1 ? 'la pieza' : 'las ${piezas.length} piezas'} a ${nombreMes(sig, hoy: reloj()).toLowerCase()} como borrador? Mismos días y horas; el texto y las redes se copian.',
          style: RkType.body.copyWith(color: RkColors.of(context).texto2)),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DUPLICAR'))),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(parrillaRepoProvider).duplicar(filasDuplicadas(piezas, mes: mes, proyectoId: p.id, clienteId: p.clienteId));
      ref.invalidate(piezasProvider);
      ref.read(seleccionParrillaProvider.notifier).mes(sig);
      m.showSnackBar(SnackBar(content: Text(piezas.length == 1 ? '✓ 1 pieza copiada como borrador' : '✓ ${piezas.length} piezas copiadas como borrador')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final pAsync = ref.watch(proyectosRedesProvider);
    final sel = ref.watch(seleccionParrillaProvider);
    final proyectos = pAsync.value?.valor ?? const <ProyectoRedes>[];
    final proyecto = proyectos.where((p) => p.id == sel.proyecto).firstOrNull ?? proyectos.firstOrNull;
    final piezasAsync = proyecto == null ? null : ref.watch(piezasProvider((proyecto.id, sel.mes)));
    final piezas = piezasAsync?.value?.valor ?? const <Pieza>[];
    final sinRed = ref.watch(sinConexionProvider) || (pAsync.value?.desdeCache ?? false) || (piezasAsync?.value?.desdeCache ?? false);
    final editar = puede(perfil, 'parrillas', editar: true) && !sinRed;
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final hoy = reloj();

    final barra = RkBarraGrande(
      titulo: 'Parrilla',
      indice: '04',
      atras: Navigator.canPop(context),
      acciones: [
        if (editar && proyecto != null) ...[
          IconButton(tooltip: 'Nueva pieza', onPressed: () => _nueva(proyecto, sel.mes), icon: const Icon(Symbols.add_sharp)),
          IconButton(tooltip: 'Duplicar al mes siguiente', onPressed: () => _duplicar(proyecto, sel.mes, piezas), icon: const Icon(Symbols.content_copy_sharp)),
        ],
      ],
    );

    if (pAsync.value == null) {
      final cuerpo = pAsync.hasError
          ? (pAsync.error is SinPermiso
              ? RkSinPermiso(onIrAHoy: () => context.go('/hoy'))
              : RkError(mensaje: textoDeError(pAsync.error), onReintentar: () => ref.invalidate(proyectosRedesProvider)))
          : const RkEsqueleto();
      return CustomScrollView(slivers: [barra, SliverToBoxAdapter(child: cuerpo)]);
    }
    if (proyecto == null) {
      return CustomScrollView(slivers: [
        barra,
        const SliverToBoxAdapter(child: RkVacio(antes: 'Sin', rosa: 'parrillas.', texto: 'Aún no hay proyectos de Redes. Crea uno en Proyectos y vuelve aquí para armar su parrilla.')),
      ]);
    }

    final listas = piezas.where((p) => p.estado == 'lista').toList();
    final conteo = contarPorEstado(piezas);
    void mes(int n) => ref.read(seleccionParrillaProvider.notifier).mes(sumarMeses(sel.mes, n));

    final hijos = <Widget>[
      if (sinRed && (piezasAsync?.value?.desdeCache ?? false)) RkSinConexion(desde: horaCorta(piezasAsync!.value!.guardadoA!)),
      // proyecto
      InkWell(
        onTap: proyectos.length < 2
            ? null
            : () async {
                final x = await elegirEnHoja<String>(context, titulo: 'Proyecto', opciones: [for (final p in proyectos) (p.id, '${p.cliente} · ${p.nombre}')], actual: proyecto.id);
                if (x != null) ref.read(seleccionParrillaProvider.notifier).proyecto(x);
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, 12, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PROYECTO', style: RkType.mono11.copyWith(color: c.texto3)),
                const SizedBox(height: 4),
                Row(children: [
                  const RkMundo(Mundo.marca, conNombre: false),
                  const SizedBox(width: 8),
                  Flexible(child: Text('${proyecto.cliente} · ${proyecto.nombre}', overflow: TextOverflow.ellipsis, style: RkType.bodyMedio.copyWith(color: c.texto))),
                ]),
              ]),
            ),
            if (proyectos.length > 1) Icon(Symbols.expand_more_sharp, size: 20, color: c.texto3),
          ]),
        ),
      ),
      // mes y vista
      Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
        padding: const EdgeInsets.fromLTRB(4, 6, RkSpace.g, 6),
        child: Row(children: [
          IconButton(tooltip: 'Mes anterior', onPressed: () => mes(-1), icon: const Icon(Symbols.chevron_left_sharp)),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(mayus(nombreMes(sel.mes, hoy: hoy)), maxLines: 1, style: RkType.hoja.copyWith(color: c.texto)))),
          IconButton(tooltip: 'Mes siguiente', onPressed: () => mes(1), icon: const Icon(Symbols.chevron_right_sharp)),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(shape: const RoundedRectangleBorder(), minimumSize: const Size(48, 48), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: false, icon: Icon(Symbols.view_agenda_sharp), tooltip: 'Lista por día'),
              ButtonSegment(value: true, icon: Icon(Symbols.calendar_view_month_sharp), tooltip: 'Mes'),
            ],
            selected: {_mesCompleto},
            onSelectionChanged: (s) => setState(() => _mesCompleto = s.first),
          ),
        ]),
      ),
      // contadores y red
      Padding(
        padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, 4, 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: conteo.isEmpty
                ? Text(editar ? 'MES VACÍO · AGREGA UNA PIEZA CON +' : 'MES VACÍO', style: RkType.mono11.copyWith(color: c.texto3))
                : Wrap(spacing: 14, runSpacing: 6, children: [
                    for (final (estado, n) in conteo)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 8, height: 8, color: colorPieza(context, estado)),
                        const SizedBox(width: 6),
                        Text('${estadoCorto(estado).toUpperCase()} $n', style: RkType.mono11.copyWith(color: c.texto2)),
                      ]),
                  ]),
          ),
          TextButton(
            onPressed: () async {
              final x = await elegirEnHoja<String>(context, titulo: 'Ver red', opciones: [('', 'Todas'), ...redesWeb], actual: _red ?? '');
              if (x != null) setState(() => _red = x.isEmpty ? null : x);
            },
            child: Text(_red == null ? 'RED: TODAS' : 'RED: $_red', style: RkType.mono11),
          ),
        ]),
      ),
    ];

    if (piezasAsync != null && piezasAsync.value == null) {
      hijos.add(piezasAsync.hasError
          ? RkError(mensaje: textoDeError(piezasAsync.error), onReintentar: () => ref.invalidate(piezasProvider))
          : const RkEsqueleto(filas: 4));
    } else if (_mesCompleto) {
      hijos.add(_Calendario(
        mes: sel.mes,
        piezas: piezas,
        red: _red,
        onDia: (dia) => _verDia(proyecto, dia, piezas.where((p) => DateUtils.isSameDay(p.publica, dia)).toList(), editar, equipo),
      ));
      hijos.add(Padding(
        padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 0),
        child: Text('Toca un día para ver sus piezas${editar ? ' o agregar una' : ''}.', style: RkType.small.copyWith(color: c.texto2)),
      ));
    } else if (piezas.isEmpty) {
      hijos.add(Padding(
        padding: const EdgeInsets.all(RkSpace.g),
        child: Text('No hay piezas en ${nombreMes(sel.mes, hoy: hoy).toLowerCase()}.${editar ? ' Agrega una con +, o duplica el mes anterior.' : ''}', style: RkType.body.copyWith(color: c.texto2)),
      ));
    } else {
      for (final (dia, lista) in porDiaDelMes(piezas)) {
        final cambios = lista.any((p) => p.pidioCambio);
        hijos.add(_Dia(dia: dia, cuantas: lista.length, cambios: cambios));
        for (final p in lista) {
          hijos.add(Opacity(
            opacity: _red != null && !p.redes.contains(_red) ? .3 : 1,
            child: _FilaPieza(p: p, aCargo: equipo.where((x) => x.id == p.aCargo).firstOrNull?.primerNombre, onTap: () => _abrir(proyecto, p, editar)),
          ));
        }
      }
    }
    hijos.add(const SizedBox(height: 32));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () async {
          ref.invalidate(proyectosRedesProvider);
          ref.invalidate(piezasProvider);
          await ref.read(piezasProvider((proyecto.id, sel.mes)).future);
        },
        child: CustomScrollView(slivers: [barra, SliverList.list(children: hijos)]),
      ),
      bottomNavigationBar: listas.isNotEmpty && editar
          ? Container(
              padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, RkSpace.g, 10),
              decoration: BoxDecoration(color: c.s2, border: Border(top: BorderSide(color: c.linea2))),
              child: Row(children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${listas.length} ${listas.length == 1 ? 'lista' : 'listas'}', style: TextStyle(color: c.texto, fontWeight: FontWeight.w500)),
                      const TextSpan(text: ' que el cliente aún no ve'),
                    ]),
                    style: RkType.small.copyWith(color: c.texto2),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: () => _enviar(listas), child: const Text('ENVIAR AL CLIENTE')),
              ]),
            )
          : null,
    );
  }

  Future<void> _abrir(ProyectoRedes proyecto, Pieza p, bool editar) async {
    final r = await mostrarPieza(context, pieza: p, proyecto: proyecto, soloVer: !editar);
    if (r != null) ref.read(seleccionParrillaProvider.notifier).mes(r);
  }

  Future<void> _verDia(ProyectoRedes proyecto, DateTime dia, List<Pieza> lista, bool editar, List<Perfil> equipo) async {
    final accion = await mostrarHoja<Object>(
      context,
      titulo: diaCorto(dia),
      cuerpo: Builder(
        builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (lista.isEmpty) Text('Nada este día.', style: RkType.body.copyWith(color: RkColors.of(ctx).texto2)),
          for (final p in lista) _FilaPieza(p: p, aCargo: equipo.where((x) => x.id == p.aCargo).firstOrNull?.primerNombre, onTap: () => Navigator.pop(ctx, p)),
          if (editar) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => Navigator.pop(ctx, 'nueva'), child: const Text('AGREGAR PIEZA ESTE DÍA')),
          ],
        ]),
      ),
    );
    if (!mounted) return;
    if (accion is Pieza) await _abrir(proyecto, accion, editar);
    if (accion == 'nueva') await _nueva(proyecto, ref.read(seleccionParrillaProvider).mes, dia: dia);
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.dia, required this.cuantas, required this.cambios});
  final DateTime dia;
  final int cuantas;
  final bool cambios;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 20, RkSpace.g, 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: diaSemanaYNumero(dia).toUpperCase(), style: RkType.mono12.copyWith(color: c.texto, letterSpacing: 12 * .08)),
        TextSpan(text: '  ${cuantas == 1 ? '1 PIEZA' : '$cuantas PIEZAS'}', style: RkType.mono11.copyWith(color: c.texto3)),
        if (cambios) ...[
          const TextSpan(text: '  '),
          if (c.esClaro) WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), color: RkColors.rosa)),
          TextSpan(text: c.esClaro ? 'EL CLIENTE PIDIÓ UN CAMBIO' : '· EL CLIENTE PIDIÓ UN CAMBIO', style: RkType.mono11.copyWith(color: c.rosaTexto)),
        ],
      ])),
    );
  }
}

class _FilaPieza extends StatelessWidget {
  const _FilaPieza({required this.p, required this.onTap, this.aCargo});
  final Pieza p;
  final String? aCargo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final detalle = p.pidioCambio && (p.notaCliente ?? '').isNotEmpty
        ? '“${p.notaCliente}”'
        : [if (p.redes.isNotEmpty) p.redes.join(' · '), horaCorta(p.publica), ?aCargo, if (p.pauta) 'lleva pauta'].join(' · ');
    return RkFila(
      titulo: '${nombreFormato(p.formato)} · ${p.titulo}',
      onTap: onTap,
      subtitulo: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RkEtiqueta(estadoCorto(p.estado), tono: tonoPieza(p.estado)),
        Text(detalle),
      ]),
      final_: Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Symbols.chevron_right_sharp, color: c.texto3)),
    );
  }
}

/// Mes completo: 7 columnas desde el lunes; cada pieza es una marca del color de su estado.
class _Calendario extends StatelessWidget {
  const _Calendario({required this.mes, required this.piezas, required this.onDia, this.red});
  final DateTime mes;
  final List<Pieza> piezas;
  final String? red;
  final ValueChanged<DateTime> onDia;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final antes = (mes.weekday + 6) % 7; // lunes = 0
    final dias = DateTime(mes.year, mes.month + 1, 0).day;
    final celdas = ((antes + dias) / 7).ceil() * 7;
    final hoy = reloj();
    const nombres = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 0),
      child: Column(children: [
        Row(children: [
          for (final n in nombres) Expanded(child: Center(child: Text(n, style: RkType.mono11.copyWith(color: c.texto3)))),
        ]),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: .8,
          children: [
            for (var i = 0; i < celdas; i++)
              if (i < antes || i >= antes + dias)
                const SizedBox.shrink()
              else
                Builder(builder: (_) {
                  final d = DateTime(mes.year, mes.month, i - antes + 1);
                  final del = piezas.where((p) => DateUtils.isSameDay(p.publica, d)).toList();
                  final esHoy = DateUtils.isSameDay(d, hoy);
                  return Semantics(
                    button: true,
                    label: '${diaCorto(d)}, ${del.isEmpty ? 'sin piezas' : '${del.length} piezas'}',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => onDia(d),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: esHoy ? c.texto : c.linea, width: esHoy ? 1.5 : .5)),
                        padding: const EdgeInsets.all(4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${d.day}', style: RkType.mono11.copyWith(color: c.texto2)),
                          const Spacer(),
                          Wrap(spacing: 3, runSpacing: 3, children: [
                            for (final p in del.take(6))
                              Opacity(
                                opacity: red != null && !p.redes.contains(red) ? .25 : 1,
                                child: Container(width: 8, height: 8, color: colorPieza(context, p.estado)),
                              ),
                          ]),
                        ]),
                      ),
                    ),
                  );
                }),
          ],
        ),
      ]),
    );
  }
}
