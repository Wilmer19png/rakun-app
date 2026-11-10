import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/datos/parrilla_web.dart';
import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/utils/abrir.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../agenda/domain/agenda.dart' show aInstante;
import '../../proyectos/presentation/ficha_proyecto_page.dart' show elegirPersona;
import '../data/parrilla_repo.dart';
import '../domain/pieza.dart';

/// Ficha de una pieza (editPost de la web). Sin `pieza` = nueva ese `dia` a las 6:30 p. m.
/// Devuelve la fecha de publicación guardada (para ir a su mes), o null.
Future<DateTime?> mostrarPieza(BuildContext context, {Pieza? pieza, required ProyectoRedes proyecto, DateTime? dia, bool soloVer = false}) =>
    mostrarHoja<DateTime>(context, titulo: pieza == null ? 'Nueva pieza' : 'Pieza', cuerpo: _Pieza(p: pieza, proyecto: proyecto, dia: dia, soloVer: soloVer));

class _Pieza extends ConsumerStatefulWidget {
  const _Pieza({this.p, required this.proyecto, this.dia, this.soloVer = false});
  final Pieza? p;
  final ProyectoRedes proyecto;
  final DateTime? dia;
  final bool soloVer;

  @override
  ConsumerState<_Pieza> createState() => _PiezaState();
}

class _PiezaState extends ConsumerState<_Pieza> {
  Pieza? get p => widget.p;
  late final _titulo = TextEditingController(text: p?.titulo ?? '');
  late String _formato = p?.formato ?? 'reel';
  late String _estado = p?.estado ?? 'borrador';
  late DateTime _dia = p?.publica ?? widget.dia ?? reloj();
  late TimeOfDay _hora = p == null ? const TimeOfDay(hour: 18, minute: 30) : TimeOfDay.fromDateTime(p!.publica);
  late final Set<String> _redes = {...(p?.redes ?? const ['IG', 'FB'])};
  late final _texto = TextEditingController(text: p?.texto ?? '');
  late final _alterno = TextEditingController(text: p?.textoAlterno ?? '');
  late final _medio = TextEditingController(text: p?.medio ?? '');
  late final _guion = TextEditingController(text: p?.guion ?? '');
  late String? _aCargo = p?.aCargo;
  late bool _pauta = p?.pauta ?? false;
  late final _publicada = TextEditingController(text: p?.publicada ?? '');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_titulo, _texto, _alterno, _medio, _guion, _publicada]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _url(TextEditingController c) {
    final s = enlaceSeguro(c.text);
    return s.isEmpty ? null : s;
  }

  Future<void> _guardar() async {
    final titulo = _titulo.text.trim();
    if (titulo.isEmpty) return setState(() => _error = 'Ponle un título.');
    for (final (c, nombre) in [(_medio, 'del video o diseño'), (_guion, 'del guion'), (_publicada, 'del post publicado')]) {
      if (c.text.trim().isNotEmpty && _url(c) == null) return setState(() => _error = 'El enlace $nombre no parece válido.');
    }
    final cuando = aInstante(_dia, _hora.hour, _hora.minute);
    setState(() {
      _guardando = true;
      _error = null;
    });
    final fila = <String, Object?>{
      'title': titulo,
      'format': _formato,
      'status': _estado,
      'publish_at': cuando.toUtc().toIso8601String(),
      'networks': [for (final r in redesWeb) if (_redes.contains(r.$1)) r.$1],
      'copy': _texto.text.trim().isEmpty ? null : _texto.text.trim(),
      'copy_variants': _alterno.text.trim().isEmpty ? <String, String>{} : {'alt': _alterno.text.trim()},
      'media_url': _url(_medio),
      'script_url': _url(_guion),
      'assigned_to': _aCargo,
      'has_ads': _pauta,
      'published_url': _url(_publicada),
      if (p == null) ...{'project_id': widget.proyecto.id, 'client_id': widget.proyecto.clienteId},
    };
    try {
      await ref.read(parrillaRepoProvider).guardar(p?.id, fila);
      ref.invalidate(piezasProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p == null ? '✓ Pieza creada' : '✓ Pieza guardada')));
      Navigator.pop(context, cuando);
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = textoDeError(e);
      });
    }
  }

  Future<void> _eliminar() async {
    final ok = await mostrarHoja<bool>(
      context,
      titulo: 'Eliminar pieza',
      cuerpo: Text('¿Eliminar esta pieza de la parrilla? No se puede deshacer.', style: RkType.body.copyWith(color: RkColors.of(context).texto2)),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR'))),
    );
    if (ok != true || !mounted) return;
    setState(() => _guardando = true);
    try {
      await ref.read(parrillaRepoProvider).eliminar(p!.id);
      ref.invalidate(piezasProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Pieza eliminada')));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = textoDeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final lee = widget.soloVer;

    Widget campo(String rotulo, Widget hijo) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)),
            const SizedBox(height: 6),
            hijo,
          ]),
        );
    Widget enlace(String rotulo, TextEditingController ctl, String pista) => campo(
          rotulo,
          TextField(
            controller: ctl,
            readOnly: lee,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: pista,
              suffixIcon: ctl.text.trim().isEmpty ? null : IconButton(tooltip: 'Abrir', onPressed: () => Abrir.enlace(ctl.text), icon: const Icon(Symbols.open_in_new_sharp)),
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${widget.proyecto.cliente} · ${widget.proyecto.nombre}', style: RkType.small.copyWith(color: c.texto2)),
      const SizedBox(height: 12),
      if ((p?.pidioCambio ?? false) && (p?.notaCliente ?? '').isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: RkColors.rosa)),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'El cliente pidió un cambio: ', style: TextStyle(color: c.texto, fontWeight: FontWeight.w500)),
              TextSpan(text: '“${p!.notaCliente}”'),
            ]),
            style: RkType.small.copyWith(color: c.texto2),
          ),
        ),
      campo('Título interno *', TextField(controller: _titulo, readOnly: lee, maxLength: 160, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(counterText: ''))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: campo(
            'Formato',
            RkCampoElegible(
              texto: nombreFormato(_formato),
              onTap: lee
                  ? null
                  : () async {
                      final x = await elegirEnHoja<String>(context, titulo: 'Formato', opciones: formatosWeb, actual: _formato);
                      if (x != null) setState(() => _formato = x);
                    },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            'Estado',
            RkCampoElegible(
              texto: estadoCorto(_estado),
              onTap: lee
                  ? null
                  : () async {
                      final x = await elegirEnHoja<String>(
                        context,
                        titulo: 'Estado',
                        ayuda: 'El cliente ve la pieza desde «Por aprobar».',
                        opciones: [for (final e in estadosPiezaWeb) (e.$1, e.$2)],
                        actual: _estado,
                      );
                      if (x != null) setState(() => _estado = x);
                    },
            ),
          ),
        ),
      ]),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: campo(
            'Fecha',
            RkCampoElegible(
              texto: _dia.year == reloj().year ? diaCorto(_dia) : '${diaCorto(_dia)} ${_dia.year}',
              onTap: lee
                  ? null
                  : () async {
                      final d = await showDatePicker(context: context, initialDate: _dia, firstDate: DateTime(_dia.year - 2), lastDate: DateTime(_dia.year + 3), helpText: 'FECHA');
                      if (d != null) setState(() => _dia = d);
                    },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            'Hora',
            RkCampoElegible(
              texto: horaCorta(DateTime(2000, 1, 1, _hora.hour, _hora.minute)),
              onTap: lee
                  ? null
                  : () async {
                      final t = await showTimePicker(context: context, initialTime: _hora, helpText: 'HORA');
                      if (t != null) setState(() => _hora = t);
                    },
            ),
          ),
        ),
      ]),
      campo(
        'Dónde se publica',
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (k, nombre) in redesWeb)
            Semantics(
              label: nombre,
              selected: _redes.contains(k),
              button: true,
              excludeSemantics: true,
              child: InkWell(
                onTap: lee ? null : () => setState(() => _redes.contains(k) ? _redes.remove(k) : _redes.add(k)),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(color: _redes.contains(k) ? c.texto : Colors.transparent, border: Border.all(color: _redes.contains(k) ? c.texto : c.linea2)),
                  child: Text(k, textAlign: TextAlign.center, style: RkType.mono12.copyWith(color: _redes.contains(k) ? c.fondo : c.texto2)),
                ),
              ),
            ),
        ]),
      ),
      campo('Texto (copy)', TextField(controller: _texto, readOnly: lee, maxLines: 5, minLines: 3, textCapitalization: TextCapitalization.sentences)),
      campo('Texto distinto para TikTok / YouTube · opcional', TextField(controller: _alterno, readOnly: lee, maxLines: 3, minLines: 2, textCapitalization: TextCapitalization.sentences)),
      enlace('Video o diseño (enlace)', _medio, 'drive.google.com/…'),
      enlace('Guion (enlace)', _guion, 'docs.google.com/…'),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: campo(
            'A cargo',
            RkCampoElegible(
              texto: equipo.where((x) => x.id == _aCargo).firstOrNull?.primerNombre ?? 'Sin asignar',
              vacio: _aCargo == null,
              onTap: lee
                  ? null
                  : () async {
                      final r = await elegirPersona(context, titulo: 'A cargo', equipo: equipo, actual: _aCargo, vacio: 'Sin asignar');
                      if (r != null) setState(() => _aCargo = r.id);
                    },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _pauta,
              onChanged: lee ? null : (v) => setState(() => _pauta = v ?? false),
              title: Text('Lleva pauta', style: RkType.body.copyWith(color: c.texto)),
            ),
          ),
        ),
      ]),
      enlace('Enlace del post publicado (cuando salga)', _publicada, 'instagram.com/p/…'),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 8), Expanded(child: Text(_error!, style: RkType.small.copyWith(color: c.texto)))]),
        ),
      if (!lee)
        Row(children: [
          if (p != null) ...[
            TextButton(onPressed: _guardando ? null : _eliminar, child: Text('ELIMINAR', style: TextStyle(color: c.rosaTexto))),
            const SizedBox(width: 8),
          ],
          Expanded(child: FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'GUARDANDO…' : p == null ? 'CREAR PIEZA' : 'GUARDAR'))),
        ]),
    ]);
  }
}
