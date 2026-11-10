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
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../hoy/data/hoy_repo.dart' show mensajesSinVerProvider;
import '../data/mensajes_repo.dart';
import '../domain/mensaje.dart';

/// Mensajes del equipo (en la web, dentro de 10 Equipo): a todos, a una persona o al equipo de
/// un proyecto; fijar; visto por; borrar. Se escribe abajo, como en el prototipo.
class MensajesPage extends ConsumerStatefulWidget {
  const MensajesPage({super.key});

  @override
  ConsumerState<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends ConsumerState<MensajesPage> {
  FiltroMensajes _filtro = FiltroMensajes.todos;
  final _texto = TextEditingController();
  final _foco = FocusNode();
  String _para = 'todos';
  String? _persona, _proyecto;
  bool _fijar = false;
  bool _enviando = false;

  @override
  void dispose() {
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _refrescar() {
    ref.invalidate(mensajesProvider);
    ref.invalidate(mensajesSinVerProvider);
  }

  Future<void> _accion(Future<void> Function() f, String ok) async {
    _foco.unfocus();
    final m = ScaffoldMessenger.of(context);
    try {
      await f();
      _refrescar();
      if (ok.isNotEmpty) m.showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      m.showSnackBar(SnackBar(content: Text(textoDeError(e))));
    }
  }

  Future<void> _publicar(String yo) async {
    final fila = filaNueva(yo: yo, para: _para, persona: _persona, proyecto: _proyecto, texto: _texto.text, fijar: _fijar);
    if (fila == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_texto.text.trim().isEmpty ? 'Escribe el mensaje.' : _para == 'persona' ? 'Elige a quién va.' : 'Elige el proyecto.')));
      return;
    }
    setState(() => _enviando = true);
    await _accion(() => ref.read(mensajesRepoProvider).publicar(fila), '✓ Mensaje publicado');
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _texto.clear();
      _fijar = false;
    });
    _foco.unfocus();
  }

  Future<void> _elegirPara(List<Perfil> equipo, List<(String, String)> proyectos, String yo) async {
    _foco.unfocus();
    final c = RkColors.of(context);
    final r = await elegirEnHoja<String>(
      context,
      titulo: 'Para',
      opciones: const [('todos', 'Todo el equipo'), ('persona', 'Una persona…'), ('proyecto', 'El equipo de un proyecto…'), ('fijar', 'Fijar arriba')],
      actual: _para,
      dibujar: (v, n) => Row(children: [
        Icon(
          switch (v) { 'todos' => Symbols.groups_sharp, 'persona' => Symbols.person_sharp, 'proyecto' => Symbols.folder_open_sharp, _ => _fijar ? Symbols.check_box_sharp : Symbols.check_box_outline_blank_sharp },
          color: c.texto2,
        ),
        const SizedBox(width: 12),
        Text(n, style: RkType.body.copyWith(color: c.texto)),
      ]),
    );
    if (r == null || !mounted) return;
    if (r == 'fijar') return setState(() => _fijar = !_fijar);
    if (r == 'persona') {
      final p = await elegirEnHoja<String>(context, titulo: 'Persona', opciones: [for (final p in equipo) if (p.id != yo) (p.id, nombreDe(p))], actual: _persona);
      if (p != null) {
        setState(() {
          _para = 'persona';
          _persona = p;
        });
      }
      return;
    }
    if (r == 'proyecto') {
      final p = await elegirEnHoja<String>(context, titulo: 'Proyecto', opciones: proyectos, actual: _proyecto);
      if (p != null) {
        setState(() {
          _para = 'proyecto';
          _proyecto = p;
        });
      }
      return;
    }
    setState(() => _para = 'todos');
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final yo = perfil?.id ?? '';
    final admin = perfil?.rol == 'admin';
    final async = ref.watch(mensajesProvider);
    final datos = async.value;
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final sinRed = ref.watch(sinConexionProvider) || (datos?.desdeCache ?? false);
    Perfil? persona(String? id) => equipo.where((p) => p.id == id).firstOrNull;

    final barra = RkBarraGrande(titulo: 'Mensajes', indice: '10', atras: Navigator.canPop(context));

    if (datos == null) {
      final cuerpo = async.hasError
          ? (async.error is SinPermiso ? RkSinPermiso(onIrAHoy: () => context.go('/hoy')) : RkError(mensaje: textoDeError(async.error), onReintentar: _refrescar))
          : const RkEsqueleto();
      return CustomScrollView(slivers: [barra, SliverToBoxAdapter(child: cuerpo)]);
    }

    final d = datos.valor;
    final todos = ordenar(d.mensajes);
    final cuenta = {for (final f in FiltroMensajes.values) f: todos.where((m) => pasaFiltro(m, f, yo: yo)).length};
    final paraMiNuevos = todos.where((m) => pasaFiltro(m, FiltroMensajes.paraMi, yo: yo) && !(d.leidos[m.id] ?? const []).contains(yo)).length;
    final lista = todos.where((m) => pasaFiltro(m, _filtro, yo: yo)).toList();
    final paraTexto = switch (_para) {
      'persona' => persona(_persona)?.primerNombre ?? 'una persona',
      'proyecto' => 'equipo de ${d.proyectos.where((p) => p.$1 == _proyecto).firstOrNull?.$2 ?? 'un proyecto'}',
      _ => 'todo el equipo',
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () async {
          _refrescar();
          await ref.read(mensajesProvider.future);
        },
        child: CustomScrollView(slivers: [
          barra,
          if (datos.desdeCache) SliverToBoxAdapter(child: RkSinConexion(desde: horaCorta(datos.guardadoA!))),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 6), children: [
                for (final (f, n) in [(FiltroMensajes.todos, 'Todos'), (FiltroMensajes.paraMi, 'Para mí'), (FiltroMensajes.fijados, 'Fijados')])
                  _Chip(
                    texto: n,
                    cuenta: f == FiltroMensajes.paraMi ? paraMiNuevos : null,
                    on: _filtro == f,
                    onTap: () => setState(() => _filtro = f),
                  ),
              ]),
            ),
          ),
          if (todos.isEmpty)
            const SliverToBoxAdapter(child: RkVacio(antes: 'Silencio', rosa: 'total.', texto: 'Aún no hay mensajes. Deja el primero para el equipo.'))
          else if (lista.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(RkSpace.g),
                child: Text(cuenta[_filtro] == 0 && _filtro == FiltroMensajes.fijados ? 'No hay mensajes fijados.' : 'Nada para ti por ahora.', style: RkType.body.copyWith(color: c.texto2)),
              ),
            )
          else
            SliverList.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final m = lista[i];
                final e = estadoMensaje(m, yo: yo, admin: admin, leidoPor: d.leidos[m.id] ?? const []);
                return _Tarjeta(
                  m: m,
                  autor: persona(m.autor),
                  destino: m.destino((id) => persona(id)?.primerNombre),
                  e: e,
                  sinRed: sinRed,
                  onVisto: () => _accion(() => ref.read(mensajesRepoProvider).marcarVisto(m.id, yo), ''),
                  onFijar: () => _accion(() => ref.read(mensajesRepoProvider).fijar(m.id, !m.fijado), m.fijado ? '✓ Desfijado' : '✓ Fijado arriba'),
                  onBorrar: () async {
                    final ok = await mostrarHoja<bool>(
                      context,
                      titulo: 'Borrar mensaje',
                      cuerpo: Text('¿Borrar este mensaje? Nadie lo volverá a ver.', style: RkType.body.copyWith(color: c.texto2)),
                      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('BORRAR'))),
                    );
                    if (ok == true) await _accion(() => ref.read(mensajesRepoProvider).borrar(m.id), '✓ Mensaje borrado');
                  },
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ]),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 10),
          decoration: BoxDecoration(color: c.s2, border: Border(top: BorderSide(color: c.linea2))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextButton.icon(
              onPressed: sinRed ? null : () => _elegirPara(equipo, d.proyectos, yo),
              icon: Icon(_para == 'persona' ? Symbols.person_sharp : _para == 'proyecto' ? Symbols.folder_open_sharp : Symbols.groups_sharp, size: 18),
              label: Text('Para: $paraTexto${_fijar ? ' · fijado' : ''}', style: RkType.small.copyWith(color: c.texto)),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _texto,
                  focusNode: _foco,
                  enabled: !sinRed,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: sinRed ? 'Sin conexión' : 'Escribe al equipo…', counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: sinRed || _enviando ? null : () => _publicar(yo),
                  child: Icon(Symbols.send_sharp, semanticLabel: 'Publicar mensaje', color: sinRed ? null : RkColors.navy),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.on, required this.onTap, this.cuenta});
  final String texto;
  final bool on;
  final int? cuenta;
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
                Text(texto, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: on ? c.fondo : c.texto2)),
                if ((cuenta ?? 0) > 0) ...[const SizedBox(width: 8), Text('$cuenta', style: RkType.mono11.copyWith(color: on ? c.fondo : c.rosaTexto))],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.m,
    required this.destino,
    required this.e,
    required this.sinRed,
    required this.onVisto,
    required this.onFijar,
    required this.onBorrar,
    this.autor,
  });
  final Mensaje m;
  final Perfil? autor;
  final String destino;
  final ({bool mio, bool nuevo, bool puedeGestionar, int vistos, bool vistoPorDestino}) e;
  final bool sinRed;
  final VoidCallback onVisto, onFijar, onBorrar;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    // en claro el amarillo casi no se ve sobre crema: el fijado lleva borde de tinta y una marca amarilla
    final borde = e.nuevo ? RkColors.rosa : m.fijado ? (c.esClaro ? c.texto2 : RkColors.amarillo) : c.linea2;
    Widget marca(Color color) => Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), color: color);
    final visto = !e.puedeGestionar ? null : m.para == 'persona' ? (e.vistoPorDestino ? 'VISTO' : 'SIN VER') : 'VISTO POR ${e.vistos}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (autor != null) avatarDe(autor!) else const RkAvatar(iniciales: 'EQ'),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
            decoration: BoxDecoration(color: c.s1, border: Border.all(color: borde)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(mayus('${autor?.primerNombre ?? 'Equipo'} · $destino'), style: RkType.mono11.copyWith(color: c.texto2))),
                if (e.nuevo)
                  Padding(padding: const EdgeInsets.only(right: 8), child: Row(children: [if (c.esClaro) marca(RkColors.rosa), Text('NUEVO', style: RkType.mono11.copyWith(color: c.rosaTexto))]))
                else if (m.fijado)
                  Padding(padding: const EdgeInsets.only(right: 8), child: Row(children: [if (c.esClaro) marca(RkColors.amarillo), Text('FIJADO', style: RkType.mono11.copyWith(color: c.texto2))])),
              ]),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(right: 8), child: Text(m.texto, style: RkType.body.copyWith(color: c.texto))),
              const SizedBox(height: 4),
              Row(children: [
                if (e.nuevo)
                  OutlinedButton(onPressed: sinRed ? null : onVisto, child: const Text('MARCAR VISTO'))
                else if (visto != null)
                  Text(visto, style: RkType.mono11.copyWith(color: c.texto3)),
                const Spacer(),
                Text(hace(m.creado, ahora: reloj()).toUpperCase(), style: RkType.mono11.copyWith(color: c.texto3)),
                if (e.puedeGestionar && !sinRed)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    icon: Icon(Symbols.more_vert_sharp, size: 20, color: c.texto2),
                    onOpened: () => FocusManager.instance.primaryFocus?.unfocus(),
                    onSelected: (v) => v == 'fijar' ? onFijar() : onBorrar(),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'fijar', child: Text(m.fijado ? 'Desfijar' : 'Fijar arriba')),
                      const PopupMenuItem(value: 'borrar', child: Text('Borrar')),
                    ],
                  )
                else
                  const SizedBox(width: 8, height: 40),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
