import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../proyectos/data/proyectos_repo.dart';
import '../../proyectos/domain/proyecto.dart';
import '../../proyectos/presentation/ficha_proyecto_page.dart' show tonoEntregable;
import '../data/hoy_repo.dart';
import '../domain/tarea.dart';
import 'entregar_hoja.dart';

/// Abre el brief o la entrega (archivo de «entregas» → enlace firmado de 1 h, como la web).
Future<void> abrirEntrega(BuildContext context, WidgetRef ref, String url) async {
  final m = ScaffoldMessenger.of(context);
  try {
    final s = await ref.read(proyectosRepoProvider).enlaceDeEntrega(url);
    if (s == null || !await Abrir.enlace(s)) m.showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
  } catch (e) {
    m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
  }
}

/// "frame.io · ediciones-noviembre" o "archivo · guiones.pdf".
String describirEnlace(String url) {
  if (url.startsWith('storage:')) {
    final nombre = url.split('/').last.replaceFirst(RegExp(r'^\d+-'), '');
    return 'archivo · $nombre';
  }
  final u = Uri.tryParse(enlaceSeguro(url));
  if (u == null || u.host.isEmpty) return url;
  final host = u.host.replaceFirst(RegExp(r'^www\.'), '');
  final ultimo = u.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
  return ultimo == null ? host : '$host · $ultimo';
}

/// Lo de arriba de una tarea: plazo, título y proyecto.
class _Cabeza extends StatelessWidget {
  const _Cabeza({required this.t, this.marca});
  final Tarea t;
  final Widget? marca;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final d = t.d;
    final tarde = plazoDe(d) == Plazo.vencido;
    final v = d.vence;
    return Padding(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        marca ??
            Row(children: [
              if (tarde) ...[Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  v == null ? 'Sin fecha límite' : [if (RegExp(r'^(Venció|Faltan)').hasMatch(etiquetaVence(d))) etiquetaVence(d), diaCorto(v), horaCorta(v)].join(' · '),
                  style: RkType.mono12.copyWith(color: tarde ? c.rosaTexto : c.texto2),
                ),
              ),
            ]),
        const SizedBox(height: 10),
        Text(mayus(d.titulo), style: RkType.ficha.copyWith(color: c.texto)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (t.mundo != null) RkMundo(t.mundo!),
          Text([t.proyectoNombre ?? '—', ?t.clienteNombre].join(' · '), style: RkType.small.copyWith(color: c.texto2)),
        ]),
      ]),
    );
  }
}

/// Fila "rótulo · valor" (Lo revisa, Tipo, Brief…).
class _Dato extends StatelessWidget {
  const _Dato(this.rotulo, this.valor, {this.onTap});
  final String rotulo;
  final Widget valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
        padding: const EdgeInsets.fromLTRB(RkSpace.g, 14, RkSpace.g, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 104, child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)))),
          Expanded(child: DefaultTextStyle.merge(style: RkType.body.copyWith(color: c.texto), child: valor)),
          if (onTap != null) Padding(padding: const EdgeInsets.only(left: 8, top: 2), child: Icon(Symbols.open_in_new_sharp, size: 20, color: c.texto2)),
        ]),
      ),
    );
  }
}

Widget _cargando(BuildContext context, WidgetRef ref, AsyncValue<Datos<Tarea>> async, String id, String titulo) => Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: async.hasError
          ? (async.error is SinPermiso
              ? const RkSinPermiso()
              : RkError(titulo: 'No pudimos abrir esta tarea.', mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(tareaProvider(id))))
          : const RkEsqueleto(filas: 4),
    );

Widget _barraAbajo(BuildContext context, Widget hijo) {
  final c = RkColors.of(context);
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, RkSpace.g, 10),
      decoration: BoxDecoration(color: c.s2, border: Border(top: BorderSide(color: c.linea2))),
      child: hijo,
    ),
  );
}

/* ==========================================================================
   Tarea: lo que me toca hacer
   ========================================================================== */
class TareaPage extends ConsumerWidget {
  const TareaPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final async = ref.watch(tareaProvider(id));
    final datos = async.value;
    if (datos == null) return _cargando(context, ref, async, id, 'Tarea');
    final t = datos.valor;
    final d = t.d;
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final revisa = equipo.where((x) => x.id == d.revisa).firstOrNull;
    final sinRed = ref.watch(sinConexionProvider) || datos.desdeCache;
    final yo = ref.watch(perfilProvider).value?.id;
    final mia = d.hace == yo;
    final abierta = d.estado != EstadoEntregable.aprobado;

    Future<void> cambiarEstado() async {
      final e = await elegirEnHoja<EstadoEntregable>(
        context,
        titulo: 'Estado',
        opciones: [for (final e in estadosParaMi(d)) (e, e.nombre)],
        actual: d.estado,
        ayuda: d.revisa != null ? '“Aprobado” lo marca quien revisa. Para enviarlo a revisión, usa Entregar.' : null,
      );
      if (e == null || e == d.estado || !context.mounted) return;
      final m = ScaffoldMessenger.of(context);
      try {
        await ref.read(hoyRepoProvider).cambiarEstado(d.id, e);
        ref.invalidate(tareaProvider(id));
        ref.invalidate(tareasProvider);
        m.showSnackBar(SnackBar(content: Text('✓ Estado: ${e.nombre}')));
      } catch (err) {
        m.showSnackBar(SnackBar(content: Text(textoDeError(err))));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tarea')),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        if (datos.desdeCache) RkSinConexion(desde: horaCorta(datos.guardadoA!)),
        _Cabeza(t: t),
        InkWell(
          onTap: mia && abierta && !sinRed ? cambiarEstado : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea), top: BorderSide(color: c.linea))),
            padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, 12, 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ESTADO', style: RkType.mono11.copyWith(color: c.texto3)),
                  const SizedBox(height: 6),
                  RkEtiqueta(d.estado.nombre, tono: tonoEntregable(d.estado)),
                ]),
              ),
              if (mia && abierta && !sinRed) Icon(Symbols.expand_more_sharp, size: 20, color: c.texto3),
            ]),
          ),
        ),
        _Dato(
          'Lo revisa',
          revisa == null
              ? Text('Nadie', style: TextStyle(color: c.texto2))
              : Row(children: [avatarDe(revisa, chico: true), const SizedBox(width: 8), Flexible(child: Text(revisa.primerNombre))]),
        ),
        _Dato('Tipo', Text(nombreTipo(d.tipo))),
        if ((d.brief ?? '').isNotEmpty) _Dato('Brief', Text(describirEnlace(d.brief!)), onTap: () => abrirEntrega(context, ref, d.brief!)),
        if ((d.entrega ?? '').isNotEmpty) _Dato('Mi entrega', Text(describirEnlace(d.entrega!)), onTap: () => abrirEntrega(context, ref, d.entrega!)),
        if ((d.notaEntrega ?? '').isNotEmpty) _Dato('Nota', Text('“${d.notaEntrega}”', style: TextStyle(color: c.texto2))),
        if ((d.pago ?? 0) > 0)
          _Dato(
            'Ganas',
            Text.rich(TextSpan(children: [
              TextSpan(text: pesos(d.pago), style: RkType.cifra.copyWith(fontSize: 16, color: c.texto)),
              if ((d.notaPago ?? '').isNotEmpty) TextSpan(text: ' · ${d.notaPago}', style: TextStyle(color: c.texto2)),
            ])),
          ),
      ]),
      bottomNavigationBar: mia && abierta
          ? _barraAbajo(
              context,
              Row(children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Pega un enlace o sube el archivo.'),
                      if (revisa != null && revisa.id != yo) ...[
                        const TextSpan(text: ' '),
                        TextSpan(text: revisa.primerNombre, style: TextStyle(color: c.texto, fontWeight: FontWeight.w500)),
                        const TextSpan(text: ' lo revisa.'),
                      ],
                    ]),
                    style: RkType.small.copyWith(color: c.texto2),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: sinRed ? null : () => mostrarEntregar(context, t, revisa: revisa),
                  icon: const Icon(Symbols.upload_sharp, size: 20),
                  label: Text(sinRed ? 'SIN CONEXIÓN' : 'ENTREGAR'),
                ),
              ]),
            )
          : null,
    );
  }
}

/* ==========================================================================
   Revisar: lo que me entregaron
   ========================================================================== */
class RevisarPage extends ConsumerWidget {
  const RevisarPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final async = ref.watch(tareaProvider(id));
    final datos = async.value;
    if (datos == null) return _cargando(context, ref, async, id, 'Te toca revisar');
    final t = datos.valor;
    final d = t.d;
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final hizo = equipo.where((x) => x.id == d.hace).firstOrNull;
    final sinRed = ref.watch(sinConexionProvider) || datos.desdeCache;
    final ahora = reloj();
    final e = d.entregadoA;
    final cuando = e == null
        ? null
        : (e.year == ahora.year && e.month == ahora.month && e.day == ahora.day ? 'entregado hoy ${horaCorta(e)}' : 'entregado ${diaCorto(e)} · ${horaCorta(e)}');

    Future<void> aprobar() async {
      final m = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      try {
        await ref.read(hoyRepoProvider).aprobar(d.id);
        ref.invalidate(tareasProvider);
        ref.invalidate(tareaProvider(id));
        m.showSnackBar(const SnackBar(content: Text('✓ Aprobado')));
        nav.maybePop();
      } catch (err) {
        m.showSnackBar(SnackBar(content: Text(textoDeError(err))));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Te toca revisar')),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        if (datos.desdeCache) RkSinConexion(desde: horaCorta(datos.guardadoA!)),
        _Cabeza(
          t: t,
          marca: Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            t.revision ? const RkEtiqueta('Te toca revisar', tono: RkTono.accion) : RkEtiqueta(d.estado.nombre, tono: tonoEntregable(d.estado)),
            if (cuando != null) Text(cuando, style: RkType.mono12.copyWith(color: c.texto2)),
          ]),
        ),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.linea), bottom: BorderSide(color: c.linea))),
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 16, RkSpace.g, 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (hizo != null) avatarDe(hizo) else const RkAvatar(iniciales: '?'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${hizo?.primerNombre ?? 'Sin asignar'} · su nota', style: RkType.mono11.copyWith(color: c.texto3)),
                const SizedBox(height: 4),
                Text((d.notaEntrega ?? '').isEmpty ? 'Sin nota.' : d.notaEntrega!, style: RkType.body.copyWith(color: (d.notaEntrega ?? '').isEmpty ? c.texto2 : c.texto)),
              ]),
            ),
          ]),
        ),
        if ((d.entrega ?? '').isNotEmpty)
          InkWell(
            onTap: () => abrirEntrega(context, ref, d.entrega!),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
              padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ver la entrega', style: RkType.bodyMedio.copyWith(color: c.texto)),
                    Text(describirEnlace(d.entrega!), style: RkType.small.copyWith(color: c.texto2)),
                  ]),
                ),
                Icon(Symbols.open_in_new_sharp, color: c.texto),
              ]),
            ),
          ),
        if ((d.brief ?? '').isNotEmpty) _Dato('Brief', Text(describirEnlace(d.brief!)), onTap: () => abrirEntrega(context, ref, d.brief!)),
        _Dato('Tipo', Text(nombreTipo(d.tipo))),
        if ((d.pago ?? 0) > 0)
          _Dato(
            'Su pago',
            Text.rich(TextSpan(children: [
              TextSpan(text: pesos(d.pago), style: RkType.cifra.copyWith(fontSize: 16, color: c.texto)),
              if ((d.pagoRonda ?? 0) > 0) TextSpan(text: ' · ronda extra +⁠${pesos(d.pagoRonda)}', style: TextStyle(color: c.texto2)),
            ])),
          ),
        if (!t.revision)
          Padding(
            padding: const EdgeInsets.all(RkSpace.g),
            child: Text('Esta tarea ya no está esperando tu revisión.', style: RkType.body.copyWith(color: c.texto2)),
          ),
      ]),
      bottomNavigationBar: t.revision
          ? _barraAbajo(
              context,
              Row(children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: sinRed ? null : () => _devolver(context, ref, t, hizo),
                    child: const Text('DEVOLVER'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: sinRed ? null : aprobar,
                    icon: const Icon(Symbols.check_sharp, size: 20),
                    label: Text(sinRed ? 'SIN CONEXIÓN' : 'APROBAR'),
                  ),
                ),
              ]),
            )
          : null,
    );
  }

  Future<void> _devolver(BuildContext context, WidgetRef ref, Tarea t, Perfil? hizo) async {
    final ok = await mostrarHoja<bool>(context, titulo: 'Devolver', cuerpo: _Devolver(t: t, hizo: hizo));
    if (ok == true && context.mounted) Navigator.of(context).maybePop();
  }
}

class _Devolver extends ConsumerStatefulWidget {
  const _Devolver({required this.t, this.hizo});
  final Tarea t;
  final Perfil? hizo;

  @override
  ConsumerState<_Devolver> createState() => _DevolverState();
}

class _DevolverState extends ConsumerState<_Devolver> {
  final _porque = TextEditingController();
  bool _ronda = false;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _porque.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final repo = ref.read(hoyRepoProvider);
    final d = widget.t.d;
    try {
      // como la web: primero la ronda extra (si aplica), luego la devolución
      if (_ronda) await repo.rondaExtra(d.id);
      await repo.devolver(d.id, _porque.text);
      ref.invalidate(tareasProvider);
      ref.invalidate(tareaProvider(d.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Devuelto a ${widget.hizo?.primerNombre ?? 'quien lo hizo'}')));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _enviando = false;
        _error = textoDeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final d = widget.t.d;
    final quien = widget.hizo?.primerNombre ?? 'quien la hizo';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('¿QUÉ HAY QUE CAMBIAR?', style: RkType.mono11.copyWith(color: c.texto3)),
      const SizedBox(height: 6),
      TextField(controller: _porque, autofocus: true, maxLines: 4, maxLength: 1000, decoration: const InputDecoration(hintText: 'Le llega como nota')),
      if ((d.pagoRonda ?? 0) > 0)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _ronda,
          onChanged: _enviando ? null : (v) => setState(() => _ronda = v ?? false),
          title: Text('Es una ronda extra (ya no es la primera ronda de cambios). Se le suman ${pesos(d.pagoRonda)} a $quien.', style: RkType.small.copyWith(color: c.texto)),
        ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Row(children: [Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 8), Expanded(child: Text(_error!, style: RkType.small.copyWith(color: c.texto)))]),
      ],
      const SizedBox(height: 16),
      FilledButton(onPressed: _enviando ? null : _enviar, child: Text(_enviando ? 'DEVOLVIENDO…' : 'DEVOLVER A ${quien.toUpperCase()}')),
    ]);
  }
}
