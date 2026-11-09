import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/config/env.dart';
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
import '../data/proyectos_repo.dart';
import '../domain/proyecto.dart';
import 'entregable_hoja.dart';

/// Ficha de un proyecto (viewProject de la web): etapa (la ve el cliente), estado, a cargo,
/// fechas, enlace a su cotización y sus entregables. «Dinero del proyecto» llega con P2.
class FichaProyectoPage extends ConsumerStatefulWidget {
  const FichaProyectoPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<FichaProyectoPage> createState() => _FichaProyectoPageState();
}

class _FichaProyectoPageState extends ConsumerState<FichaProyectoPage> {
  Future<void> _cambiar(Map<String, Object?> campos, String aviso) async {
    final m = ScaffoldMessenger.of(context);
    try {
      await ref.read(proyectosRepoProvider).cambiar(widget.id, campos);
      ref.invalidate(proyectoProvider(widget.id));
      ref.invalidate(proyectosProvider);
      m.showSnackBar(SnackBar(content: Text('✓ $aviso')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }

  Future<void> _plantilla(Proyecto p, int yaHay) async {
    final ok = await mostrarHoja<bool>(
      context,
      titulo: 'Cargar plantilla',
      cuerpo: Text('Se agregan los entregables de la plantilla de ${p.mundo.nombre}, con fechas contando desde hoy. Los que ya están no se tocan.',
          style: RkType.body.copyWith(color: RkColors.of(context).texto2)),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('AGREGAR ENTREGABLES'))),
    );
    if (ok != true || !mounted) return;
    final m = ScaffoldMessenger.of(context);
    try {
      await ref.read(proyectosRepoProvider).cargarPlantilla(filasPlantilla(p, desde: yaHay));
      ref.invalidate(entregablesProvider(p.id));
      m.showSnackBar(const SnackBar(content: Text('✓ Plantilla cargada')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final async = ref.watch(proyectoProvider(widget.id));
    final entAsync = ref.watch(entregablesProvider(widget.id));
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final perfil = ref.watch(perfilProvider).value;
    final datos = async.value;
    final sinRed = ref.watch(sinConexionProvider) || (datos?.desdeCache ?? false);
    final editar = puede(perfil, 'proyectos', editar: true) && !sinRed;

    if (datos == null) {
      return Scaffold(
        appBar: AppBar(),
        body: async.hasError
            ? (async.error is SinPermiso
                ? const RkSinPermiso()
                : RkError(titulo: 'No pudimos abrir este proyecto.', mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(proyectoProvider(widget.id))))
            : const RkEsqueleto(filas: 4),
      );
    }
    final p = datos.valor;
    final dueno = equipo.where((x) => x.id == p.aCargo).firstOrNull;
    final entregables = entAsync.value?.valor ?? const <Entregable>[];
    final etapas = p.etapas;
    final n = p.etapa == null ? 0 : etapas.indexOf(p.etapa!) + 1;

    return Scaffold(
      appBar: AppBar(title: Text(p.clienteNombre ?? '', style: RkType.bodyMedio.copyWith(color: c.texto))),
      floatingActionButton: editar ? RkFab(etiqueta: 'Nuevo entregable', onPressed: () => mostrarEntregable(context, proyecto: p, orden: entregables.length)) : null,
      body: RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () async {
          ref.invalidate(entregablesProvider(widget.id));
          ref.invalidate(proyectoProvider(widget.id));
          await ref.read(proyectoProvider(widget.id).future);
        },
        child: ListView(padding: const EdgeInsets.only(bottom: 120), children: [
          if (datos.desdeCache) RkSinConexion(desde: horaCorta(datos.guardadoA!)),
          Padding(
            padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                RkMundo(p.mundo),
                if (p.plan != null) Text('· ${p.plan}', style: RkType.small.copyWith(color: c.texto2)),
              ]),
              const SizedBox(height: 10),
              Text(mayus(p.nombre), style: RkType.ficha.copyWith(color: c.texto)),
            ]),
          ),
          _Control(
            rotulo: 'Etapa · la ve el cliente',
            onTap: editar
                ? () async {
                    final e = await elegirEnHoja<String>(
                      context,
                      titulo: 'Etapa',
                      ayuda: 'El cliente ve esta etapa en su portal.',
                      opciones: [for (final e in etapas) (e, e)],
                      actual: p.etapa,
                      dibujar: (v, nombre) => Row(children: [
                        SizedBox(width: 28, child: Text('${etapas.indexOf(v) + 1}', style: RkType.mono12.copyWith(color: c.texto3))),
                        Text(nombre, style: RkType.body.copyWith(color: c.texto)),
                      ]),
                    );
                    if (e != null && e != p.etapa) await _cambiar({'stage': e}, 'Etapa: $e');
                  }
                : null,
            valor: Row(children: [
              Text(p.etapa ?? '—', style: RkType.bodyMedio.copyWith(color: c.texto)),
              if (n > 0) ...[const SizedBox(width: 8), Text('$n de ${etapas.length}', style: RkType.mono11.copyWith(color: c.texto3))],
            ]),
          ),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: _Control(
                  rotulo: 'Estado',
                  onTap: editar
                      ? () async {
                          final e = await elegirEnHoja<EstadoProyecto>(context, titulo: 'Estado', opciones: [for (final e in EstadoProyecto.values) (e, e.nombre)], actual: p.estado);
                          if (e != null && e != p.estado) await _cambiar({'status': e.name}, 'Estado: ${e.nombre}');
                        }
                      : null,
                  valor: RkEtiqueta(p.estado.nombre, tono: p.estado == EstadoProyecto.activo ? RkTono.ok : RkTono.apagada),
                ),
              ),
              VerticalDivider(width: 1, color: c.linea),
              Expanded(
                child: _Control(
                  rotulo: 'A cargo',
                  onTap: editar
                      ? () async {
                          final r = await elegirPersona(context, titulo: 'A cargo', equipo: equipo, actual: p.aCargo, vacio: 'Sin asignar');
                          if (r != null && r.id != p.aCargo) await _cambiar({'owner_id': r.id}, r.id == null ? 'Sin asignar' : 'A cargo: ${r.nombre}');
                        }
                      : null,
                  valor: dueno == null
                      ? Text('Sin asignar', style: RkType.bodyMedio.copyWith(color: c.texto2))
                      : Row(children: [avatarDe(dueno, chico: true), const SizedBox(width: 8), Flexible(child: Text(dueno.primerNombre, overflow: TextOverflow.ellipsis, style: RkType.bodyMedio.copyWith(color: c.texto)))]),
                ),
              ),
            ]),
          ),
          if (p.inicio != null || p.fin != null || p.cotizacionToken != null)
            Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
              padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 12),
              child: Wrap(spacing: 16, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (p.inicio != null) Text('Inicio ${fechaLarga(p.inicio!)}', style: RkType.small.copyWith(color: c.texto2)),
                if (p.fin != null) Text('Cierre ${fechaLarga(p.fin!)}', style: RkType.small.copyWith(color: c.texto2)),
                if (p.cotizacionToken != null)
                  TextButton.icon(
                    onPressed: () => Abrir.enlace('${Env.webUrl}/cotizacion.html?c=${p.cotizacionToken}'),
                    icon: const Icon(Symbols.open_in_new_sharp, size: 18),
                    label: Text('COTIZACIÓN ${p.cotizacionNumero ?? ''}'.trim()),
                  ),
              ]),
            ),
          RkGrupo('Entregables', cuenta: entregables.length),
          if (entAsync.hasError && entAsync.value == null)
            RkError(mensaje: textoDeError(entAsync.error), onReintentar: () => ref.invalidate(entregablesProvider(widget.id)))
          else if (entAsync.value == null)
            const RkEsqueleto(filas: 3)
          else if (entregables.isEmpty)
            Padding(
              padding: const EdgeInsets.all(RkSpace.g),
              child: Text('Aún no hay entregables. Carga la plantilla o agrega uno con +.', style: RkType.body.copyWith(color: c.texto2)),
            )
          else
            for (final d in entregables)
              _FilaEntregable(
                d: d,
                hace: equipo.where((x) => x.id == d.hace).firstOrNull,
                revisa: equipo.where((x) => x.id == d.revisa).firstOrNull,
                onTap: () => mostrarEntregable(context, proyecto: p, entregable: d, orden: entregables.length, soloVer: !editar),
              ),
          if (editar)
            Padding(
              padding: const EdgeInsets.fromLTRB(RkSpace.g, 16, RkSpace.g, 0),
              child: OutlinedButton(onPressed: () => _plantilla(p, entregables.length), child: Text('CARGAR PLANTILLA DE ${p.mundo.nombre.toUpperCase()}')),
            ),
        ]),
      ),
    );
  }
}

/// Fila que abre una hoja para cambiar un dato (etapa, estado, a cargo).
class _Control extends StatelessWidget {
  const _Control({required this.rotulo, required this.valor, this.onTap});
  final String rotulo;
  final Widget valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea), top: BorderSide(color: c.linea, width: 0))),
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, 12, 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)),
                const SizedBox(height: 4),
                valor,
              ]),
            ),
            if (onTap != null) Icon(Symbols.expand_more_sharp, size: 20, color: c.texto3),
          ]),
        ),
      ),
    );
  }
}

class _FilaEntregable extends StatelessWidget {
  const _FilaEntregable({required this.d, required this.onTap, this.hace, this.revisa});
  final Entregable d;
  final Perfil? hace, revisa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final tarde = plazoDe(d) == Plazo.vencido;
    final quien = [hace?.primerNombre ?? 'Sin asignar', if (revisa != null) 'revisa ${revisa!.primerNombre}'].join(' · ');
    return RkFila(
      titulo: d.titulo,
      onTap: onTap,
      subtitulo: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RkEtiqueta(d.estado.nombre, tono: tonoEntregable(d.estado)),
        Text('${nombreTipo(d.tipo)} · $quien'),
      ]),
      final_: Padding(
        padding: const EdgeInsets.only(right: 12, left: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // en tema claro el texto queda navy: la marca rosa es lo que dice "vencido" (regla de DESIGN.md)
          if (tarde) ...[Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 6)],
          Text(
            etiquetaVence(d),
            style: RkType.mono12.copyWith(color: tarde ? c.rosaTexto : c.texto2, fontWeight: tarde ? FontWeight.w600 : null),
          ),
        ]),
      ),
    );
  }
}

/// Estados de un entregable con etiquetas neutras (el rosa lleno queda para "requiere acción").
RkTono tonoEntregable(EstadoEntregable e) => switch (e) {
      EstadoEntregable.porHacer => RkTono.apagada,
      EstadoEntregable.enCurso || EstadoEntregable.enRevision => RkTono.neutra,
      EstadoEntregable.aprobado => RkTono.ok,
    };

/// Elegir una persona del equipo (o "nadie"). Devuelve (id: null) si eligen la opción vacía.
Future<({String? id, String nombre})?> elegirPersona(BuildContext context, {required String titulo, required List<Perfil> equipo, String? actual, required String vacio}) async {
  final r = await elegirEnHoja<String>(
    context,
    titulo: titulo,
    opciones: [('', vacio), for (final p in equipo) (p.id, nombreDe(p))],
    actual: actual ?? '',
    dibujar: (id, nombre) {
      final c = RkColors.of(context);
      final p = equipo.where((x) => x.id == id).firstOrNull;
      return p == null
          ? Text(nombre, style: RkType.body.copyWith(color: c.texto2))
          : Row(children: [avatarDe(p), const SizedBox(width: 12), Flexible(child: Text(nombre, style: RkType.body.copyWith(color: c.texto)))]);
    },
  );
  if (r == null) return null;
  return (id: r.isEmpty ? null : r, nombre: r.isEmpty ? vacio : (equipo.where((x) => x.id == r).firstOrNull?.primerNombre ?? ''));
}
