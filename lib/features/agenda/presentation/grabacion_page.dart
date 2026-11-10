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
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/agenda_repo.dart';
import '../domain/agenda.dart';
import 'programar_hoja.dart';

/// Una grabación: cuándo, dónde (Cómo llegar), llamar o escribir al cliente, equipo y qué prepara.
class GrabacionPage extends ConsumerWidget {
  const GrabacionPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final async = ref.watch(grabacionProvider(id));
    final datos = async.value;
    if (datos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grabación')),
        body: async.hasError
            ? (async.error is SinPermiso
                ? const RkSinPermiso()
                : RkError(titulo: 'No pudimos abrir esta grabación.', mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(grabacionProvider(id))))
            : const RkEsqueleto(filas: 4),
      );
    }
    final g = datos.valor;
    final perfil = ref.watch(perfilProvider).value;
    final refs = ref.watch(referenciasAgendaProvider).value ?? const Referencias();
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final sinRed = ref.watch(sinConexionProvider) || datos.desdeCache;
    final editar = puede(perfil, 'grabaciones', editar: true) && !sinRed;
    final cliente = refs.cliente(g.clienteId);
    final proyecto = refs.proyecto(g.proyectoId);
    final tel = cliente?.telefono ?? '';
    final ahora = reloj();
    final dia = DateTime(g.inicio.year, g.inicio.month, g.inicio.day).difference(DateTime(ahora.year, ahora.month, ahora.day)).inHours ~/ 24;
    final cuando = '${dia == 0 ? 'Hoy' : dia == 1 ? 'Mañana' : diaCorto(g.inicio)} ${horaCorta(g.inicio)}';
    final resp = g.respuestaCliente;
    final va = [for (final id in g.equipo) ?equipo.where((p) => p.id == id).firstOrNull];

    Widget dato(String rotulo, Widget valor) => Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 14, RkSpace.g, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 104, child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)))),
            Expanded(child: DefaultTextStyle.merge(style: RkType.body.copyWith(color: c.texto), child: valor)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grabación'),
        actions: [if (editar) IconButton(tooltip: 'Editar', onPressed: () async {
              final r = await mostrarProgramar(context, grabacion: g);
              if (r == 'eliminado' && context.mounted) context.pop();
            }, icon: const Icon(Symbols.edit_sharp))],
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        if (datos.desdeCache) RkSinConexion(desde: horaCorta(datos.guardadoA!)),
        Padding(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              RkEtiqueta(nombreEstadoGrabacion(g.estado), tono: g.estado == 'cancelada' ? RkTono.apagada : RkTono.neutra),
              if (resp != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 6, height: 6, color: g.confirmo ? c.ok : g.pideOtraFecha ? RkColors.rosa : c.texto3),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('el cliente ${resp == 'esperando confirmación' ? 'aún no confirma' : resp}',
                        style: RkType.mono12.copyWith(color: g.confirmo ? c.ok : g.pideOtraFecha ? c.rosaTexto : c.texto2)),
                  ),
                ]),
            ]),
            const SizedBox(height: 10),
            Text(mayus(cuando), style: RkType.ficha.copyWith(color: c.texto)),
            const SizedBox(height: 8),
            Text('${cliente?.nombre ?? '—'} · ${g.duracion.replaceAll(' h', g.horas == 1 ? ' hora' : ' horas')}', style: RkType.body.copyWith(color: c.texto2)),
          ]),
        ),
        RkAcciones([
          RkAccion('Cómo llegar', Symbols.near_me_sharp, () => Abrir.mapa(g.paraMapa), principal: g.paraMapa.isNotEmpty),
          if (tel.isNotEmpty) RkAccion('Llamar', Symbols.call_sharp, () => Abrir.llamar(tel)),
          if (tel.isNotEmpty) RkAccion('WhatsApp', Symbols.chat_sharp, () => Abrir.whatsapp(tel)),
        ]),
        dato(
          'Lugar',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.lugar ?? 'Por definir', style: RkType.bodyMedio.copyWith(color: g.lugar == null ? c.texto2 : c.texto)),
            if ((g.direccion ?? '').isNotEmpty) Text(g.direccion!, style: TextStyle(color: c.texto2)),
          ]),
        ),
        if (proyecto != null)
          InkWell(
            onTap: puede(perfil, 'proyectos') ? () => context.push('/proyectos/${proyecto.id}') : null,
            child: dato('Proyecto', Text(proyecto.nombre, style: TextStyle(decoration: TextDecoration.underline, decorationColor: RkColors.rosa))),
          ),
        dato(
          'Equipo',
          va.isEmpty
              ? Text('Nadie todavía', style: TextStyle(color: c.texto2))
              : Wrap(spacing: 12, runSpacing: 8, children: [
                  for (final p in va) Row(mainAxisSize: MainAxisSize.min, children: [avatarDe(p, chico: true), const SizedBox(width: 6), Text(p.primerNombre)]),
                ]),
        ),
        if (g.pideOtraFecha && (g.notaCliente ?? '').isNotEmpty) dato('El cliente', Text('“${g.notaCliente}”', style: TextStyle(color: c.texto2))),
        if (g.prepara.isNotEmpty) ...[
          RkGrupo('Qué prepara el cliente', cuenta: g.prepara.length),
          for (final p in g.prepara)
            Container(
              constraints: const BoxConstraints(minHeight: 52),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
              child: Text(p, style: RkType.body.copyWith(color: c.texto)),
            ),
        ],
      ]),
    );
  }
}
