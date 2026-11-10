import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/datos/agenda_web.dart';
import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/avatar.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../proyectos/presentation/ficha_proyecto_page.dart' show elegirPersona;
import '../data/agenda_repo.dart';
import '../data/lugares.dart';
import '../domain/agenda.dart';

/// Programar o editar una grabación o una reunión (shootForm / meetForm de la web), o confirmar
/// una reunión pedida por un cliente ("Ponle fecha"). Devuelve 'guardado', 'eliminado' o null.
Future<String?> mostrarProgramar(BuildContext context, {Grabacion? grabacion, Reunion? reunion, bool reunionPrimero = false}) async {
  final confirmar = reunion?.pedida ?? false;
  final titulo = grabacion != null
      ? 'Editar grabación'
      : confirmar
          ? 'Ponle fecha'
          : reunion != null
              ? 'Editar reunión'
              : 'Programar';
  return mostrarHoja<String>(context, titulo: titulo, cuerpo: _Programar(g: grabacion, r: reunion, reunionPrimero: reunionPrimero));
}

class _Programar extends ConsumerStatefulWidget {
  const _Programar({this.g, this.r, this.reunionPrimero = false});
  final Grabacion? g;
  final Reunion? r;
  final bool reunionPrimero;

  @override
  ConsumerState<_Programar> createState() => _ProgramarState();
}

class _ProgramarState extends ConsumerState<_Programar> {
  Grabacion? get g => widget.g;
  Reunion? get r => widget.r;
  bool get _nuevo => g == null && r == null;
  bool get _confirmar => r?.pedida ?? false;

  late bool _esReunion = r != null || (g == null && widget.reunionPrimero);
  late String? _cliente = g?.clienteId ?? r?.clienteId;
  // fecha y hora
  late DateTime? _dia = g?.inicio ?? r?.inicio;
  late TimeOfDay _hora = (g?.inicio ?? r?.inicio) == null
      ? (r != null || widget.reunionPrimero ? const TimeOfDay(hour: 10, minute: 0) : const TimeOfDay(hour: 9, minute: 0))
      : TimeOfDay.fromDateTime((g?.inicio ?? r?.inicio)!);
  // grabación
  late String? _proyecto = g?.proyectoId;
  late double _horas = g?.horas ?? 3;
  late String _estadoG = g?.estado ?? 'programada';
  late final _lugar = TextEditingController(text: g?.lugar ?? '');
  late final _direccion = TextEditingController(text: g?.direccion ?? '');
  late final Set<String> _equipo = {...?g?.equipo};
  late final _prepara = TextEditingController(text: (g?.prepara ?? const []).join('\n'));
  bool _yaAcordamos = false;
  // reunión
  late final _tema = TextEditingController(text: r?.titulo ?? '');
  late String _tipo = r?.tipo ?? 'revision';
  late int _minutos = r?.minutos ?? 20;
  late final _meet = TextEditingController(text: r?.enlace ?? '');
  late String? _conQuien = r == null ? ref.read(perfilProvider).value?.id : (r!.conQuien ?? ref.read(perfilProvider).value?.id);
  late String _estadoR = _confirmar ? 'confirmada' : (r?.estado ?? 'confirmada');
  late final _acuerdos = TextEditingController(text: r?.acuerdos ?? '');

  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_lugar, _direccion, _prepara, _tema, _meet, _acuerdos]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime? get _inicio => _dia == null ? null : aInstante(_dia!, _hora.hour, _hora.minute);

  Future<void> _guardar() async {
    final repo = ref.read(agendaRepoProvider);
    setState(() => _error = null);
    if (_cliente == null) return setState(() => _error = 'Elige el cliente.');
    try {
      if (_esReunion) {
        final enlace = _meet.text.trim();
        final err = errorReunion(tema: _tema.text, dia: _dia, enlace: enlace, enlaceSeguro: enlaceSeguro(enlace));
        if (err != null) return setState(() => _error = err);
        setState(() => _guardando = true);
        await repo.guardarReunion(r?.id, {
          'client_id': _cliente,
          'title': _tema.text.trim(),
          'kind': _tipo,
          'duration_min': _minutos,
          'starts_at': _inicio!.toUtc().toIso8601String(),
          'link': enlace.isEmpty ? null : enlaceSeguro(enlace),
          'owner_id': _conQuien,
          'status': _estadoR,
          'summary': _acuerdos.text.trim().isEmpty ? null : _acuerdos.text.trim(),
        });
        ref.invalidate(reunionesProvider);
      } else {
        final err = errorGrabacion(dia: _dia, equipo: _equipo.toList(), estado: _estadoG);
        if (err != null) return setState(() => _error = err);
        setState(() => _guardando = true);
        final inicio = _inicio!;
        await repo.guardarGrabacion(g?.id, {
          'client_id': _cliente,
          'project_id': _proyecto,
          'starts_at': inicio.toUtc().toIso8601String(),
          'duration_hours': _horas,
          'status': _estadoG,
          'location': _lugar.text.trim().isEmpty ? null : _lugar.text.trim(),
          'address': _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
          'crew': _equipo.toList(),
          'prep': lineas(_prepara.text),
          if (reiniciaRespuesta(antes: g, nuevoInicio: inicio, yaAcordamos: _yaAcordamos)) ...{'client_response': null, 'client_note': null},
        });
        ref.invalidate(grabacionesProvider);
        if (g != null) ref.invalidate(grabacionProvider(g!.id));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_esReunion ? (_confirmar ? '✓ Reunión confirmada' : _nuevo ? '✓ Reunión agendada' : '✓ Reunión guardada') : (_nuevo ? '✓ Grabación programada' : '✓ Grabación guardada'))));
      Navigator.pop(context, 'guardado');
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
      titulo: _esReunion ? 'Eliminar reunión' : 'Eliminar grabación',
      cuerpo: Text(_esReunion ? '¿Eliminar esta reunión? No se puede deshacer.' : '¿Eliminar esta grabación? No se puede deshacer.',
          style: RkType.body.copyWith(color: RkColors.of(context).texto2)),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR'))),
    );
    if (ok != true || !mounted) return;
    setState(() => _guardando = true);
    try {
      final repo = ref.read(agendaRepoProvider);
      if (_esReunion) {
        await repo.eliminarReunion(r!.id);
        ref.invalidate(reunionesProvider);
      } else {
        await repo.eliminarGrabacion(g!.id);
        ref.invalidate(grabacionesProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Eliminada')));
      Navigator.pop(context, 'eliminado');
    } catch (e) {
      setState(() {
        _guardando = false;
        _error = textoDeError(e);
      });
    }
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _dia ?? hoy, firstDate: DateTime(hoy.year - 2), lastDate: DateTime(hoy.year + 3), helpText: 'FECHA');
    if (d != null) setState(() => _dia = d);
  }

  Future<void> _elegirHora() async {
    final t = await showTimePicker(context: context, initialTime: _hora, helpText: 'HORA');
    if (t != null) setState(() => _hora = t);
  }

  Future<void> _elegirLugar() async {
    final previos = lugaresAnteriores(await ref.read(agendaRepoProvider).lugaresUsados().catchError((_) => <Map<String, dynamic>>[]));
    if (!mounted) return;
    final l = await mostrarHoja<Lugar>(context, titulo: 'Lugar', cuerpo: _BuscarLugar(inicial: _lugar.text, anteriores: previos));
    if (l != null) {
      setState(() {
        _lugar.text = l.nombre;
        if (l.direccion.isNotEmpty) _direccion.text = l.direccion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final refs = ref.watch(referenciasAgendaProvider).value ?? const Referencias();
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final puedeG = puede(perfil, 'grabaciones', editar: true);
    final puedeR = puede(perfil, 'reuniones', editar: true);

    if (ref.watch(referenciasAgendaProvider).hasValue && refs.clientes.isEmpty) {
      return Text('Primero un cliente: créalo en Clientes.', style: RkType.body.copyWith(color: c.texto2));
    }

    Widget campo(String rotulo, Widget hijo) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)),
            const SizedBox(height: 6),
            hijo,
          ]),
        );
    final proyectos = refs.proyectos.where((p) => p.clienteId == _cliente).toList();
    final cliente = refs.cliente(_cliente);

    final fechaHora = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: campo('Fecha *', RkCampoElegible(texto: _dia == null ? 'Elegir' : '${diaCorto(_dia!)} ${_dia!.year}', vacio: _dia == null, onTap: _elegirFecha))),
      const SizedBox(width: 10),
      Expanded(child: campo('Hora *', RkCampoElegible(texto: horaCorta(DateTime(2000, 1, 1, _hora.hour, _hora.minute)), onTap: _elegirHora))),
    ]);
    final elegirCliente = campo(
      'Cliente *',
      RkCampoElegible(
        texto: cliente?.nombre ?? 'Elegir',
        vacio: cliente == null,
        onTap: () async {
          final x = await elegirEnHoja<String>(context, titulo: 'Cliente', opciones: [for (final c in refs.clientes) (c.id, c.nombre)], actual: _cliente);
          if (x != null && x != _cliente) {
            setState(() {
              _cliente = x;
              _proyecto = null;
            });
          }
        },
      ),
    );

    final hijos = <Widget>[];
    if (_nuevo && puedeG && puedeR) {
      hijos.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(shape: const RoundedRectangleBorder(), minimumSize: const Size(0, 48)),
          segments: const [
            ButtonSegment(value: false, label: Text('Grabación'), icon: Icon(Symbols.videocam_sharp)),
            ButtonSegment(value: true, label: Text('Reunión'), icon: Icon(Symbols.groups_sharp)),
          ],
          selected: {_esReunion},
          onSelectionChanged: (s) => setState(() {
            _esReunion = s.first;
            _error = null;
            _hora = _esReunion ? const TimeOfDay(hour: 10, minute: 0) : const TimeOfDay(hour: 9, minute: 0);
          }),
        ),
      ));
    }

    if (_esReunion) {
      if (_confirmar) {
        hijos.add(Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: c.linea2)),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '${cliente?.nombre ?? 'El cliente'} escribió: ', style: TextStyle(color: c.texto, fontWeight: FontWeight.w500)),
              TextSpan(text: (r!.notaCliente ?? '').isEmpty ? '“${r!.titulo}”' : '“${r!.notaCliente}”'),
            ]),
            style: RkType.small.copyWith(color: c.texto2),
          ),
        ));
      } else {
        hijos
          ..add(elegirCliente)
          ..add(campo('Tema *', TextField(controller: _tema, maxLength: 160, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Revisión del mes', counterText: ''))))
          ..add(campo(
            'Tipo',
            RkCampoElegible(
              texto: nombreTipoReunion(_tipo),
              onTap: () async {
                final x = await elegirEnHoja<String>(context, titulo: 'Tipo', opciones: tiposReunionWeb, actual: _tipo);
                if (x != null) setState(() => _tipo = x);
              },
            ),
          ));
      }
      hijos
        ..add(fechaHora)
        ..add(campo('Enlace de Meet', TextField(controller: _meet, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://meet.google.com/…'))))
        ..add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: campo(
              'Con quién',
              RkCampoElegible(
                texto: equipo.where((p) => p.id == _conQuien).firstOrNull?.primerNombre ?? '—',
                vacio: _conQuien == null,
                onTap: () async {
                  final x = await elegirPersona(context, titulo: 'Con quién', equipo: equipo, actual: _conQuien, vacio: '—');
                  if (x != null) setState(() => _conQuien = x.id);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: campo(
              'Duración',
              RkCampoElegible(
                texto: '$_minutos min',
                onTap: () async {
                  final opciones = {15, 20, 30, 45, 60, 90, 120, _minutos}.toList()..sort();
                  final x = await elegirEnHoja<int>(context, titulo: 'Duración', opciones: [for (final m in opciones) (m, '$m min')], actual: _minutos);
                  if (x != null) setState(() => _minutos = x);
                },
              ),
            ),
          ),
        ]));
      if (!_confirmar) {
        hijos
          ..add(campo(
            'Estado',
            RkCampoElegible(
              texto: nombreEstadoReunion(_estadoR),
              onTap: () async {
                final x = await elegirEnHoja<String>(context, titulo: 'Estado', opciones: [for (final e in estadosReunionWeb) if (e.$1 != 'solicitada') e], actual: _estadoR);
                if (x != null) setState(() => _estadoR = x);
              },
            ),
          ))
          ..add(campo('Acuerdos de la reunión · los ve el cliente', TextField(controller: _acuerdos, maxLines: 3, textCapitalization: TextCapitalization.sentences)));
      }
    } else {
      hijos
        ..add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: elegirCliente),
          const SizedBox(width: 10),
          Expanded(
            child: campo(
              'Proyecto',
              RkCampoElegible(
                texto: refs.proyecto(_proyecto)?.nombre ?? 'Sin proyecto',
                vacio: _proyecto == null,
                onTap: _cliente == null
                    ? null
                    : () async {
                        final x = await elegirEnHoja<String>(context, titulo: 'Proyecto', opciones: [('', 'Sin proyecto'), for (final p in proyectos) (p.id, p.nombre)], actual: _proyecto ?? '');
                        if (x != null) setState(() => _proyecto = x.isEmpty ? null : x);
                      },
              ),
            ),
          ),
        ]))
        ..add(fechaHora)
        ..add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: campo(
              'Duración',
              RkCampoElegible(
                texto: Grabacion(id: '', clienteId: '', inicio: DateTime(2000), horas: _horas).duracion,
                onTap: () async {
                  final opciones = {1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, _horas}.toList()..sort();
                  final x = await elegirEnHoja<double>(context, titulo: 'Duración', opciones: [
                    for (final h in opciones) (h, Grabacion(id: '', clienteId: '', inicio: DateTime(2000), horas: h).duracion),
                  ], actual: _horas);
                  if (x != null) setState(() => _horas = x);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: campo(
              'Estado',
              RkCampoElegible(
                texto: nombreEstadoGrabacion(_estadoG),
                onTap: () async {
                  final x = await elegirEnHoja<String>(context, titulo: 'Estado', opciones: estadosGrabacionWeb, actual: _estadoG);
                  if (x != null) setState(() => _estadoG = x);
                },
              ),
            ),
          ),
        ]))
        ..add(campo('Lugar', RkCampoElegible(texto: _lugar.text.isEmpty ? 'Busca: estudio, consultorio…' : _lugar.text, vacio: _lugar.text.isEmpty, onTap: _elegirLugar)))
        ..add(campo('Dirección', TextField(controller: _direccion, maxLength: 300, decoration: const InputDecoration(hintText: 'Cra. 43A #1-50, Medellín', counterText: ''))))
        ..add(campo(
          'Quién va del equipo *',
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in equipo)
              FilterChip(
                showCheckmark: false,
                shape: const RoundedRectangleBorder(),
                backgroundColor: Colors.transparent,
                selectedColor: c.texto,
                side: BorderSide(color: _equipo.contains(p.id) ? c.texto : c.linea2),
                labelStyle: RkType.small.copyWith(fontWeight: FontWeight.w500, color: _equipo.contains(p.id) ? c.fondo : c.texto),
                avatar: avatarDe(p, chico: true),
                label: Text(p.primerNombre),
                selected: _equipo.contains(p.id),
                onSelected: (v) => setState(() => v ? _equipo.add(p.id) : _equipo.remove(p.id)),
              ),
          ]),
        ))
        ..add(campo(
          'Qué prepara el cliente · uno por línea',
          TextField(controller: _prepara, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: '3 cambios de ropa en colores lisos')),
        ));
      if (g?.pideOtraFecha ?? false) {
        hijos.add(CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _yaAcordamos,
          onChanged: (v) => setState(() => _yaAcordamos = v ?? false),
          title: Text('Ya acordamos la nueva fecha (borrar la solicitud del cliente)', style: RkType.small.copyWith(color: c.texto)),
        ));
      }
    }

    if (_error != null) {
      hijos.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 8), Expanded(child: Text(_error!, style: RkType.small.copyWith(color: c.texto)))]),
      ));
    }
    final texto = _guardando
        ? 'GUARDANDO…'
        : _esReunion
            ? (_confirmar ? 'CONFIRMAR REUNIÓN' : _nuevo ? 'AGENDAR' : 'GUARDAR')
            : (_nuevo ? 'PROGRAMAR' : 'GUARDAR');
    hijos.add(Row(children: [
      if (!_nuevo) ...[
        TextButton(onPressed: _guardando ? null : _eliminar, child: Text('ELIMINAR', style: TextStyle(color: c.rosaTexto))),
        const SizedBox(width: 8),
      ],
      Expanded(child: FilledButton(onPressed: _guardando ? null : _guardar, child: Text(texto))),
    ]));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: hijos);
  }
}

/// Buscar un lugar: Photon + "lugares anteriores" (attachPlacePicker de la web).
class _BuscarLugar extends StatefulWidget {
  const _BuscarLugar({required this.inicial, required this.anteriores});
  final String inicial;
  final List<({String nombre, String direccion})> anteriores;

  @override
  State<_BuscarLugar> createState() => _BuscarLugarState();
}

class _BuscarLugarState extends State<_BuscarLugar> {
  late final _q = TextEditingController(text: widget.inicial);
  Timer? _espera;
  List<Lugar> _resultados = const [];
  bool _buscando = false;
  String? _error;

  @override
  void dispose() {
    _espera?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _cambio(String v) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () async {
      if (v.trim().length < 3) return setState(() => _resultados = const []);
      setState(() {
        _buscando = true;
        _error = null;
      });
      try {
        final r = await buscarLugares(v);
        if (mounted && _q.text == v) setState(() => _resultados = r);
      } catch (_) {
        if (mounted) setState(() => _error = 'No se pudo buscar. Escribe el lugar a mano y usa «Usar lo escrito».');
      } finally {
        if (mounted) setState(() => _buscando = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    Widget fila(Lugar l) => InkWell(
          onTap: () => Navigator.pop(context, l),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.nombre.isEmpty ? l.direccion : l.nombre, style: RkType.bodyMedio.copyWith(color: c.texto)),
              if (l.direccion.isNotEmpty && l.nombre.isNotEmpty) Text(l.direccion, style: RkType.small.copyWith(color: c.texto2)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _q,
        autofocus: true,
        onChanged: _cambio,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Estudio, consultorio, barrio…',
          prefixIcon: const Icon(Symbols.search_sharp),
          suffixIcon: _buscando ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : null,
        ),
      ),
      const SizedBox(height: 8),
      if (_q.text.trim().isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: () => Navigator.pop(context, (nombre: _q.text.trim(), direccion: '')), child: Text('USAR «${_q.text.trim()}»')),
        ),
      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: RkType.small.copyWith(color: c.texto2))),
      for (final l in _resultados) fila(l),
      if (_resultados.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Datos © OpenStreetMap', style: RkType.mono11.copyWith(color: c.texto3))),
      if (widget.anteriores.isNotEmpty && _resultados.isEmpty) ...[
        const SizedBox(height: 12),
        Text('LUGARES ANTERIORES', style: RkType.mono11.copyWith(color: c.texto3)),
        for (final l in widget.anteriores.take(8)) fila((nombre: l.nombre, direccion: l.direccion)),
      ],
    ]);
  }
}
