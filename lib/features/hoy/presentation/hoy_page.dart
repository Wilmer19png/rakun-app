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
import '../../../core/utils/abrir.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/ojo/ojo.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../proyectos/domain/proyecto.dart';
import '../../solicitudes/data/solicitudes_repo.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../data/hoy_repo.dart';
import '../domain/tarea.dart';
import 'entregar_hoja.dart';

/// 00 · Hoy (viewPending de la web): saludo y resumen, mis pendientes por plazo, lo que me toca
/// revisar, solicitudes nuevas, mensajes sin ver y lo que gano. «Agenda de hoy» llega con 02 Agenda
/// y «Seguimiento de campañas» con 11 Métricas.
class HoyPage extends ConsumerStatefulWidget {
  const HoyPage({super.key});

  @override
  ConsumerState<HoyPage> createState() => _HoyPageState();
}

class _HoyPageState extends ConsumerState<HoyPage> {
  String? _proyecto; // filtro por proyecto (id)
  String? _tipo; // filtro por tipo ("revision" o el kind)

  Future<void> _refrescar() async {
    ref.invalidate(tareasProvider);
    ref.invalidate(mensajesSinVerProvider);
    ref.invalidate(gananciasProvider);
    await ref.read(tareasProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final terminados = ref.watch(verTerminadosProvider);
    final async = ref.watch(tareasProvider);
    final datos = async.value;
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final sinRed = ref.watch(sinConexionProvider) || (datos?.desdeCache ?? false);
    final ahora = reloj();

    final tareas = datos?.valor ?? const <Tarea>[];
    final lista = tareas.where((t) => (_proyecto == null || t.d.proyectoId == _proyecto) && (_tipo == null || t.claveTipo == _tipo)).toList();

    final mensajes = terminados ? const <MensajeSinVer>[] : (ref.watch(mensajesSinVerProvider).value ?? const []);
    final ganancias = terminados ? const Ganancias() : (ref.watch(gananciasProvider).value ?? const Ganancias());
    final verSolicitudes = !terminados && puede(perfil, 'solicitudes');
    final nuevas = verSolicitudes
        ? (ref.watch(solicitudesProvider).value?.valor ?? const <Solicitud>[]).where((s) => s.estado == EstadoSolicitud.nueva).take(3).toList()
        : const <Solicitud>[];

    Perfil? persona(String? id) => equipo.where((x) => x.id == id).firstOrNull;

    final hijos = <Widget>[
      _Saludo(nombre: perfil?.primerNombre ?? 'equipo', ahora: ahora, resumen: datos == null || (!terminados && tareas.isEmpty) ? null : _Resumen(tareas: tareas, terminados: terminados, ahora: ahora)),
      if (datos?.desdeCache ?? false) RkSinConexion(desde: horaCorta(datos!.guardadoA!)),
      _Filtros(
        terminados: terminados,
        tareas: tareas,
        proyecto: _proyecto,
        tipo: _tipo,
        onTerminados: (v) => setState(() {
          _proyecto = null;
          _tipo = null;
          ref.read(verTerminadosProvider.notifier).poner(v);
        }),
        onProyecto: (v) => setState(() => _proyecto = v),
        onTipo: (v) => setState(() => _tipo = v),
      ),
    ];

    if (datos == null) {
      hijos.add(async.hasError
          ? (async.error is SinPermiso ? const RkSinPermiso() : RkError(mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(tareasProvider)))
          : const RkEsqueleto(filas: 5));
    } else if (terminados) {
      if (lista.isEmpty) {
        hijos.add(Padding(padding: const EdgeInsets.all(RkSpace.g), child: Text('Aún no hay entregas aprobadas.', style: RkType.body.copyWith(color: c.texto2))));
      } else {
        hijos.add(RkGrupo('Aprobado', cuenta: lista.length));
        for (final t in lista) {
          hijos.add(_FilaTarea(t: t, ahora: ahora, revisa: persona(t.d.revisa), hizo: persona(t.d.hace)));
        }
      }
    } else {
      for (final g in GrupoHoy.values) {
        final ts = lista.where((t) => grupoDe(t, ahora: ahora) == g).toList();
        if (ts.isEmpty) continue;
        hijos.add(RkGrupo(g.nombre, cuenta: ts.length, urgente: g == GrupoHoy.vencido));
        for (final t in ts) {
          hijos.add(_FilaTarea(
            t: t,
            ahora: ahora,
            revisa: persona(t.d.revisa),
            hizo: persona(t.d.hace),
            onEntregar: sinRed ? null : () => mostrarEntregar(context, t, revisa: persona(t.d.revisa)),
          ));
        }
      }
      if (tareas.isNotEmpty && lista.isEmpty) {
        hijos.add(Padding(padding: const EdgeInsets.all(RkSpace.g), child: Text('Nada con ese filtro.', style: RkType.body.copyWith(color: c.texto2))));
      }
    }

    if (nuevas.isNotEmpty) {
      hijos.add(RkGrupo('Solicitudes nuevas', accion: 'Ver todas', onAccion: () => context.go('/solicitudes')));
      for (final s in nuevas) {
        hijos.add(_FilaSolicitud(s: s));
      }
    }
    if (mensajes.isNotEmpty) {
      hijos.add(RkGrupo('Mensajes sin ver', cuenta: mensajes.length));
      for (final m in mensajes.take(3)) {
        hijos.add(_Mensaje(m: m, autor: persona(m.autor), onVisto: sinRed || perfil == null ? null : () => _marcarVisto(m, perfil.id)));
      }
    }
    if (ganancias.hayAlgo) hijos.add(_LoQueGanas(g: ganancias));

    final todoAlDia = datos != null && !terminados && tareas.isEmpty && nuevas.isEmpty && mensajes.isEmpty;
    if (todoAlDia) {
      hijos.add(const RkVacio(antes: 'Todo', rosa: 'al día.', texto: 'No tienes pendientes ni revisiones. Cuando te asignen un entregable o llegue una solicitud, aparece aquí.'));
    }
    hijos.add(const SizedBox(height: 32));

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(color: RkColors.rosa, onRefresh: _refrescar, child: ListView(padding: EdgeInsets.zero, children: hijos)),
    );
  }

  Future<void> _marcarVisto(MensajeSinVer m, String yo) async {
    final avisos = ScaffoldMessenger.of(context);
    try {
      await ref.read(hoyRepoProvider).marcarVisto(m.id, yo);
      ref.invalidate(mensajesSinVerProvider);
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo({required this.nombre, required this.ahora, this.resumen});
  final String nombre;
  final DateTime ahora;
  final Widget? resumen;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 16, RkSpace.g, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${diaCorto(ahora).toUpperCase()} · '),
                  TextSpan(text: '00', style: TextStyle(color: c.rosaTexto)),
                  const TextSpan(text: ' HOY'),
                ]),
                style: RkType.mono12.copyWith(letterSpacing: 12 * .06, color: c.texto2),
              ),
            ),
          ),
          const RakunOjo(ancho: 88),
        ]),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [const TextSpan(text: 'HOLA, '), TextSpan(text: '${mayus(nombre)}.', style: const TextStyle(color: RkColors.rosa))]),
          style: RkType.saludo.copyWith(color: c.texto),
        ),
        if (resumen != null) ...[const SizedBox(height: 14), resumen!],
      ]),
    );
  }
}

/// "Tienes 6 pendientes en 3 proyectos · 2 vencidos · 3 para hoy." (la frase de la web)
class _Resumen extends StatelessWidget {
  const _Resumen({required this.tareas, required this.terminados, required this.ahora});
  final List<Tarea> tareas;
  final bool terminados;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final estilo = RkType.body.copyWith(color: c.texto2);
    if (terminados) return Text('Lo último que entregaste y te aprobaron.', style: estilo);
    if (tareas.isEmpty) return Text('No tienes pendientes. Cuando te asignen un entregable aparece aquí.', style: estilo);
    final r = resumen(tareas, ahora: ahora);
    final fuerte = TextStyle(color: c.texto, fontWeight: FontWeight.w500);
    return Text.rich(
      TextSpan(children: [
        const TextSpan(text: 'Tienes '),
        TextSpan(text: '${r.total} ${r.total == 1 ? 'pendiente' : 'pendientes'}', style: fuerte),
        TextSpan(text: ' en ${r.proyectos} ${r.proyectos == 1 ? 'proyecto' : 'proyectos'}'),
        if (r.vencidos > 0) ...[
          const TextSpan(text: ' · '),
          // en claro, texto navy con marca rosa (nunca rosa pequeño sobre crema)
          if (c.esClaro) WidgetSpan(alignment: PlaceholderAlignment.middle, child: Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), color: RkColors.rosa)),
          TextSpan(text: '${r.vencidos} ${r.vencidos == 1 ? 'vencido' : 'vencidos'}', style: fuerte.copyWith(color: c.rosaTexto)),
        ],
        if (r.hoy > 0) TextSpan(text: ' · ${r.hoy} para hoy'),
        const TextSpan(text: '.'),
      ]),
      style: estilo,
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.terminados,
    required this.tareas,
    required this.proyecto,
    required this.tipo,
    required this.onTerminados,
    required this.onProyecto,
    required this.onTipo,
  });
  final bool terminados;
  final List<Tarea> tareas;
  final String? proyecto, tipo;
  final ValueChanged<bool> onTerminados;
  final ValueChanged<String?> onProyecto, onTipo;

  @override
  Widget build(BuildContext context) {
    final proyectos = <String, String>{for (final t in tareas) t.d.proyectoId: t.proyectoNombre ?? '—'};
    final tipos = {for (final t in tareas) t.claveTipo};
    return SizedBox(
      height: 60,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 6), children: [
        _Chip(texto: 'Pendientes', on: !terminados, onTap: () => onTerminados(false)),
        _Chip(texto: 'Terminados', on: terminados, onTap: () => onTerminados(true)),
        if (proyectos.length > 1)
          _Chip(
            texto: proyecto == null ? 'Proyecto' : proyectos[proyecto] ?? 'Proyecto',
            on: proyecto != null,
            elegir: true,
            onTap: () async {
              final r = await elegirEnHoja<String>(context, titulo: 'Proyecto', opciones: [('', 'Todos'), ...proyectos.entries.map((e) => (e.key, e.value))], actual: proyecto ?? '');
              if (r != null) onProyecto(r.isEmpty ? null : r);
            },
          ),
        if (tareas.length > 1 && tipos.length > 1)
          _Chip(
            texto: tipo == null ? 'Tipo' : nombreClaveTipo(tipo!),
            on: tipo != null,
            elegir: true,
            onTap: () async {
              final r = await elegirEnHoja<String>(context, titulo: 'Tipo', opciones: [('', 'Todos'), for (final k in tipos) (k, nombreClaveTipo(k))], actual: tipo ?? '');
              if (r != null) onTipo(r.isEmpty ? null : r);
            },
          ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.on, required this.onTap, this.elegir = false});
  final String texto;
  final bool on, elegir;
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
              padding: EdgeInsets.only(left: 14, right: elegir ? 8 : 14),
              decoration: BoxDecoration(color: on ? c.texto : Colors.transparent, border: Border.all(color: on ? c.texto : c.linea2)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(texto, overflow: TextOverflow.ellipsis, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: on ? c.fondo : c.texto2)),
                ),
                if (elegir) ...[const SizedBox(width: 4), Icon(Symbols.expand_more_sharp, size: 18, color: on ? c.fondo : c.texto3)],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaTarea extends StatelessWidget {
  const _FilaTarea({required this.t, required this.ahora, this.revisa, this.hizo, this.onEntregar});
  final Tarea t;
  final DateTime ahora;
  final Perfil? revisa, hizo;
  final VoidCallback? onEntregar;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final d = t.d;
    final tarde = plazoDe(d, ahora: ahora) == Plazo.vencido;
    // como el prototipo: el cliente (o el proyecto) y quién revisa; el nombre del proyecto está en la tarea
    final texto = [
      if (!t.revision) t.clienteNombre ?? t.proyectoNombre ?? '—',
      if (t.revision) hizo == null ? 'sin asignar' : 'lo entregó ${hizo!.primerNombre}',
      if (t.revision && (d.notaEntrega ?? '').isNotEmpty) '“${d.notaEntrega}”',
      if (!t.revision && revisa != null) 'lo revisa ${revisa!.primerNombre}',
    ].join(' · ');
    final puedeEntregar = !t.revision && d.estado != EstadoEntregable.aprobado;
    return RkFila(
      titulo: d.titulo,
      onTap: () => context.push(t.revision ? '/hoy/revisar/${d.id}' : '/hoy/tarea/${d.id}'),
      subtitulo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (t.mundo != null) Padding(padding: const EdgeInsets.only(bottom: 2), child: RkMundo(t.mundo!)),
        Text(texto, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
      final_: t.revision
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              const RkEtiqueta('Revisar', tono: RkTono.accion),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Symbols.chevron_right_sharp, color: c.texto3)),
            ])
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (tarde) ...[Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 6)],
                  Text(etiquetaVence(d, ahora: ahora), style: RkType.mono12.copyWith(color: tarde ? c.rosaTexto : c.texto2, fontWeight: tarde ? FontWeight.w600 : null)),
                ]),
              ),
              if (puedeEntregar)
                IconButton(tooltip: 'Entregar', onPressed: onEntregar, icon: const Icon(Symbols.upload_sharp))
              else
                const SizedBox(width: 12),
            ]),
    );
  }
}

class _FilaSolicitud extends StatelessWidget {
  const _FilaSolicitud({required this.s});
  final Solicitud s;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return RkFila(
      titulo: s.nombre,
      nueva: true,
      onTap: () => context.push('/solicitudes/${s.id}'),
      subtitulo: Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (s.mundo != null) RkMundo(s.mundo!),
        Text([?s.plan, if (s.vinoDeAnuncio) 'vino de un anuncio'].join(' · ')),
      ]),
      final_: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(hace(s.creada, ahora: reloj()), style: RkType.mono11.copyWith(color: c.texto3)),
        if (s.telefono.isNotEmpty)
          IconButton(tooltip: 'Llamar', onPressed: () => Abrir.llamar(s.telefono), icon: const Icon(Symbols.call_sharp))
        else
          const SizedBox(width: 12),
      ]),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.m, this.autor, this.onVisto});
  final MensajeSinVer m;
  final Perfil? autor;
  final VoidCallback? onVisto;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 14, RkSpace.g, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (autor != null) avatarDe(autor!) else const RkAvatar(iniciales: 'EQ'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${autor?.primerNombre ?? 'Equipo'} · ${m.paraMi ? 'para ti' : 'para todo el equipo'}', style: RkType.mono11.copyWith(color: c.texto3)),
            const SizedBox(height: 4),
            Text(m.texto, style: RkType.body.copyWith(color: c.texto)),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: onVisto, child: const Text('MARCAR VISTO'))),
          ]),
        ),
      ]),
    );
  }
}

class _LoQueGanas extends StatelessWidget {
  const _LoQueGanas({required this.g});
  final Ganancias g;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final detalle = [
      if (g.aprobadas > 0) '${pesos(g.aprobadas)} de tareas aprobadas',
      if (g.comisiones > 0) '${pesos(g.comisiones)} en comisiones${g.mensuales > 0 ? ' (${g.mensuales} mensuales)' : ''}',
    ].join(' · ');
    Widget celda(String rotulo, double valor, String nota) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.linea)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)),
              const SizedBox(height: 6),
              Text(pesos(valor), style: RkType.cifra.copyWith(color: c.texto)),
              if (nota.isNotEmpty) ...[const SizedBox(height: 4), Text(nota, style: RkType.small.copyWith(color: c.texto2))],
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const RkGrupo('Lo que ganas'),
      Padding(
        padding: const EdgeInsets.fromLTRB(RkSpace.g, 14, RkSpace.g, 0),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            celda('Por cobrar', g.porCobrar, detalle),
            if (g.enCurso > 0) ...[const SizedBox(width: 8), celda('En curso', g.enCurso, 'se suma cuando te aprueben')],
          ]),
        ),
      ),
    ]);
  }
}
