import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/datos/proyectos_web.dart';
import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/utils/abrir.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/proyectos_repo.dart';
import '../domain/proyecto.dart';
import 'ficha_proyecto_page.dart';

/// Un entregable en una hoja: lo que en la web es una fila de 9 columnas (título, tipo, lo hace,
/// lo revisa, fecha límite, estado, brief, entrega, quitar). Sin `entregable` = nuevo.
Future<void> mostrarEntregable(BuildContext context, {required Proyecto proyecto, Entregable? entregable, required int orden, bool soloVer = false}) =>
    mostrarHoja<void>(context, titulo: entregable == null ? 'Nuevo entregable' : 'Entregable', cuerpo: _Hoja(proyecto, entregable, orden, soloVer));

class _Hoja extends ConsumerStatefulWidget {
  const _Hoja(this.p, this.d, this.orden, this.soloVer);
  final Proyecto p;
  final Entregable? d;
  final int orden;
  final bool soloVer;

  @override
  ConsumerState<_Hoja> createState() => _HojaState();
}

class _HojaState extends ConsumerState<_Hoja> {
  late final _titulo = TextEditingController(text: widget.d?.titulo ?? 'Nuevo entregable');
  late final _brief = TextEditingController(text: widget.d?.brief ?? '');
  late String _tipo = widget.d?.tipo ?? 'otro';
  late String? _hace = widget.d == null ? widget.p.aCargo : widget.d!.hace;
  late String? _revisa = widget.d?.revisa;
  late EstadoEntregable _estado = widget.d?.estado ?? EstadoEntregable.porHacer;
  // nuevo: a 7 días, como «+ Entregable» de la web
  late DateTime? _vence = widget.d == null ? venceElDia(DateTime.now().add(const Duration(days: 7))) : widget.d!.vence;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _titulo.dispose();
    _brief.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) return setState(() => _error = 'Ponle un nombre al entregable.');
    final b = _brief.text.trim();
    final brief = b.isEmpty ? null : enlaceSeguro(b);
    if (b.isNotEmpty && (brief == null || brief.isEmpty)) return setState(() => _error = 'Ese enlace del brief no parece válido.');
    setState(() {
      _guardando = true;
      _error = null;
    });
    final campos = <String, Object?>{
      'title': titulo,
      'kind': _tipo,
      'assignee_id': _hace,
      'reviewer_id': _revisa,
      'due_at': _vence?.toUtc().toIso8601String(),
      'status': _estado.clave,
      'brief_url': brief,
    };
    try {
      final repo = ref.read(proyectosRepoProvider);
      if (widget.d == null) {
        await repo.crearEntregable({'project_id': widget.p.id, 'sort': widget.orden, ...campos});
      } else {
        await repo.cambiarEntregable(widget.d!.id, campos);
      }
      ref.invalidate(entregablesProvider(widget.p.id));
      ref.invalidate(pendientesPorProyectoProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = textoDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _quitar() async {
    final ok = await mostrarHoja<bool>(
      context,
      titulo: '¿Quitar?',
      cuerpo: Text('Se quita «${widget.d!.titulo}» de este proyecto.', style: RkType.body.copyWith(color: RkColors.of(context).texto2)),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('QUITAR ENTREGABLE'))),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(proyectosRepoProvider).quitarEntregable(widget.d!.id);
      ref.invalidate(entregablesProvider(widget.p.id));
      ref.invalidate(pendientesPorProyectoProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = textoDeError(e));
    }
  }

  Future<void> _abrir(String url) async {
    final m = ScaffoldMessenger.of(context);
    try {
      final s = await ref.read(proyectosRepoProvider).enlaceDeEntrega(url);
      if (s == null || !await Abrir.enlace(s)) m.showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final lee = widget.soloVer;
    String quien(String? id, String vacio) => equipo.where((x) => x.id == id).firstOrNull?.primerNombre ?? vacio;

    Widget campo(String rotulo, Widget hijo) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(rotulo, style: RkType.small.copyWith(color: c.texto2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            hijo,
          ]),
        );
    Widget elegible(String texto, VoidCallback? onTap) => RkCampoElegible(texto: texto, onTap: lee ? null : onTap);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      campo('Nombre', TextField(controller: _titulo, enabled: !lee, maxLength: 200, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(counterText: ''))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: campo(
            'Tipo',
            elegible(nombreTipo(_tipo), () async {
              final r = await elegirEnHoja<String>(context, titulo: 'Tipo', opciones: [for (final e in tiposWeb.entries) (e.key, e.value)], actual: _tipo);
              if (r != null) setState(() => _tipo = r);
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            'Fecha límite',
            elegible(_vence == null ? 'Sin fecha' : diaCorto(_vence!), () async {
              final hoy = DateTime.now();
              final r = await showDatePicker(
                context: context,
                initialDate: _vence ?? hoy,
                firstDate: DateTime(hoy.year - 2),
                lastDate: DateTime(hoy.year + 3),
                helpText: 'FECHA LÍMITE',
              );
              if (r != null) setState(() => _vence = venceElDia(r)); // 6 p. m., como la web
            }),
          ),
        ),
      ]),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: campo(
            'Lo hace',
            elegible(quien(_hace, 'Sin asignar'), () async {
              final r = await elegirPersona(context, titulo: 'Lo hace', equipo: equipo, actual: _hace, vacio: 'Sin asignar');
              if (r != null) setState(() => _hace = r.id);
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            'Lo revisa',
            elegible(quien(_revisa, 'Nadie'), () async {
              final r = await elegirPersona(context, titulo: 'Lo revisa', equipo: equipo, actual: _revisa, vacio: 'Nadie');
              if (r != null) setState(() => _revisa = r.id);
            }),
          ),
        ),
      ]),
      campo(
        'Estado',
        elegible(_estado.nombre, () async {
          final r = await elegirEnHoja<EstadoEntregable>(context, titulo: 'Estado', opciones: [for (final e in EstadoEntregable.values) (e, e.nombre)], actual: _estado);
          if (r != null) setState(() => _estado = r);
        }),
      ),
      campo(
        'Brief (enlace)',
        TextField(
          controller: _brief,
          enabled: !lee,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'https://',
            suffixIcon: (widget.d?.brief ?? '').isEmpty ? null : IconButton(tooltip: 'Abrir brief', icon: const Icon(Symbols.open_in_new_sharp), onPressed: () => _abrir(widget.d!.brief!)),
          ),
        ),
      ),
      if ((widget.d?.entrega ?? '').isNotEmpty) ...[
        OutlinedButton.icon(onPressed: () => _abrir(widget.d!.entrega!), icon: const Icon(Symbols.open_in_new_sharp, size: 20), label: const Text('VER ENTREGA')),
        if ((widget.d?.notaEntrega ?? '').isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text('“${widget.d!.notaEntrega}”', style: RkType.small.copyWith(color: c.texto2))),
        const SizedBox(height: 14),
      ],
      if (_error != null) ...[Text(_error!, style: RkType.small.copyWith(color: c.texto)), const SizedBox(height: 12)],
      if (!lee)
        Row(children: [
          if (widget.d != null) ...[
            TextButton(onPressed: _guardando ? null : _quitar, child: Text('QUITAR', style: TextStyle(color: c.rosaTexto))),
            const SizedBox(width: 8),
          ],
          Expanded(child: FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'GUARDANDO…' : 'GUARDAR'))),
        ]),
    ]);
  }
}
