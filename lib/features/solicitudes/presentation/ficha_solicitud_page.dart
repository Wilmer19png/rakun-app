import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/avatar.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/abrir.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../clientes/presentation/acceso_hoja.dart';
import '../data/solicitudes_repo.dart';
import '../domain/solicitud.dart';

/// Ficha de una solicitud (openLead de admin.js) con llamar y WhatsApp a un toque.
class FichaSolicitudPage extends ConsumerStatefulWidget {
  const FichaSolicitudPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<FichaSolicitudPage> createState() => _FichaState();
}

class _FichaState extends ConsumerState<FichaSolicitudPage> {
  final _notas = TextEditingController();
  Timer? _espera;
  String _guardado = '';
  bool _notasCargadas = false;

  @override
  void dispose() {
    _espera?.cancel();
    _notas.dispose();
    super.dispose();
  }

  void _aviso(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<bool> _cambiar(Solicitud s, Map<String, Object?> campos, String listo) async {
    try {
      await ref.read(solicitudesRepoProvider).cambiar(s.id, campos);
      ref.read(revisionesProvider.notifier).subir(['leads']); // el aviso en vivo también llega; esto no espera por él
      if (listo.isNotEmpty && mounted) _aviso(listo);
      return true;
    } catch (e) {
      if (mounted) _aviso(textoDeError(e));
      return false;
    }
  }

  void _notasCambiaron(Solicitud s, String v) {
    _espera?.cancel();
    setState(() => _guardado = 'Guardando…');
    _espera = Timer(const Duration(milliseconds: 700), () async {
      final ok = await _cambiar(s, {'notes': v}, '');
      if (mounted) setState(() => _guardado = ok ? '✓ Notas guardadas' : '');
    });
  }

  Future<void> _elegirEstado(Solicitud s) => mostrarHoja<void>(
        context,
        titulo: 'Estado',
        cuerpo: Column(children: [
          for (final e in EstadoSolicitud.values)
            RkOpcion(
              marcada: e == s.estado,
              onTap: () async {
                Navigator.pop(context);
                if (e != s.estado) await _cambiar(s, {'status': e.name}, 'Estado: ${e.nombre}');
              },
              child: RkEtiqueta(e.nombre, tono: e.tono),
            ),
        ]),
      );

  Future<void> _elegirResponsable(Solicitud s, List<Perfil> equipo) => mostrarHoja<void>(
        context,
        titulo: 'A cargo',
        cuerpo: Column(children: [
          RkOpcion(
            marcada: s.aCargo == null,
            onTap: () async {
              Navigator.pop(context);
              if (s.aCargo != null) await _cambiar(s, {'assigned_to': null}, 'Sin responsable');
            },
            child: Text('Sin asignar', style: RkType.body.copyWith(color: RkColors.of(context).texto)),
          ),
          for (final p in equipo)
            RkOpcion(
              marcada: p.id == s.aCargo,
              onTap: () async {
                Navigator.pop(context);
                if (p.id != s.aCargo) await _cambiar(s, {'assigned_to': p.id}, 'A cargo: ${p.primerNombre}');
              },
              child: Row(children: [avatarDe(p), const SizedBox(width: 12), Text(p.nombre.isEmpty ? (p.email ?? '') : p.nombre, style: RkType.body.copyWith(color: RkColors.of(context).texto))]),
            ),
        ]),
      );

  Future<void> _hacerCliente(Solicitud s) async {
    final seguir = await mostrarHoja<bool>(
      context,
      titulo: 'Hacer cliente',
      cuerpo: Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'Se crea '),
          TextSpan(text: s.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
          const TextSpan(text: ' en Clientes (si ya existe con ese correo, se usa ese) y la solicitud pasa a Ganado. Luego creas su acceso al portal.'),
        ]),
        style: RkType.body.copyWith(color: RkColors.of(context).texto2),
      ),
      pie: Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CREAR CLIENTE Y SU ACCESO'))),
    );
    if (seguir != true || !mounted) return;
    try {
      final cliente = await ref.read(solicitudesRepoProvider).asegurarCliente(s);
      await ref.read(solicitudesRepoProvider).cambiar(s.id, {'status': 'ganado'});
      ref.read(revisionesProvider.notifier).subir(['leads', 'clients']);
      if (!mounted) return;
      await mostrarAcceso(
        context,
        PersonaAcceso(nombre: '${cliente['name']}', correo: '${cliente['email']}', telefono: cliente['phone'] as String?, clienteId: '${cliente['id']}'),
      );
    } catch (e) {
      if (mounted) _aviso(textoDeError(e));
    }
  }

  Future<void> _eliminar(Solicitud s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar la solicitud de ${s.nombre}?'),
        content: const Text('No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(solicitudesRepoProvider).eliminar(s.id);
      ref.read(revisionesProvider.notifier).subir(['leads']);
      if (mounted) context.canPop() ? context.pop() : context.go('/solicitudes');
    } catch (e) {
      if (mounted) _aviso(textoDeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final datos = ref.watch(solicitudesProvider).value;
    final perfil = ref.watch(perfilProvider).value;
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final sinRed = ref.watch(sinConexionProvider) || (datos?.desdeCache ?? false);
    final s = datos?.valor.where((x) => x.id == widget.id).firstOrNull;

    if (datos == null) return const Scaffold(body: SafeArea(child: RkEsqueleto()));
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solicitud')),
        body: RkVacio(antes: 'Ya no', rosa: 'está.', texto: 'Esta solicitud se eliminó o ya no está en tus permisos.', accion: OutlinedButton(onPressed: () => context.canPop() ? context.pop() : context.go('/solicitudes'), child: const Text('VOLVER'))),
      );
    }
    if (!_notasCargadas) {
      _notas.text = s.notas ?? '';
      _notasCargadas = true;
    }
    final editar = puede(perfil, 'solicitudes', editar: true) && !sinRed;
    final hacerCliente = puede(perfil, 'clientes', editar: true) && !sinRed;
    final responsable = equipo.where((p) => p.id == s.aCargo).firstOrNull;
    final mensaje = 'Hola ${s.primerNombre}, te escribimos de RAKÜN por tu solicitud del plan ${s.plan ?? ''}.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud'),
        actions: [
          if (perfil?.esAdmin == true)
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              icon: const Icon(Symbols.more_vert_sharp),
              enabled: !sinRed,
              onSelected: (_) => _eliminar(s),
              itemBuilder: (_) => const [PopupMenuItem(value: 'borrar', child: Text('Eliminar solicitud'))],
            ),
        ],
      ),
      body: ListView(padding: EdgeInsets.zero, children: [
        if (datos.desdeCache) RkSinConexion(desde: '${datos.guardadoA!.hour}:${datos.guardadoA!.minute.toString().padLeft(2, '0')}'),
        Padding(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 20, RkSpace.g, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [if (s.mundo != null) ...[RkMundo(s.mundo!), const SizedBox(width: 8)], Text('· ${hace(s.creada)}', style: RkType.mono12.copyWith(color: c.texto2))]),
            const SizedBox(height: 10),
            Text(s.nombre.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: RkType.ficha.copyWith(color: c.texto)),
            if ((s.ocupacion ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text(s.ocupacion!, style: RkType.body.copyWith(color: c.texto2))],
          ]),
        ),
        _Acciones(s: s, mensaje: mensaje),
        Container(
          margin: const EdgeInsets.all(RkSpace.g),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.linea)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PLAN ELEGIDO', style: RkType.mono11.copyWith(color: c.texto2)),
            const SizedBox(height: 6),
            Text(s.plan ?? s.mundo?.nombre ?? '—', style: RkType.bodyMedio.copyWith(fontSize: 17, color: c.texto)),
            if ((s.planDetalle ?? '').isNotEmpty) Text(s.planDetalle!, style: RkType.small.copyWith(color: c.texto2)),
            if ((s.precio ?? '').isNotEmpty) Text(s.precio!, style: RkType.mono12.copyWith(color: c.texto)),
          ]),
        ),
        if (s.vinoDeAnuncio)
          Padding(
            padding: const EdgeInsets.fromLTRB(RkSpace.g, 0, RkSpace.g, 16),
            child: Text('Vino de un anuncio · ${[s.anuncio, s.campana].map(textoPlano).where((x) => x.isNotEmpty).join(' · ')}', style: RkType.small.copyWith(color: c.texto2)),
          ),
        _Control(etiqueta: 'Estado', habilitado: editar, onTap: () => _elegirEstado(s), child: RkEtiqueta(s.estado.nombre, tono: s.estado.tono)),
        _Control(
          etiqueta: 'A cargo',
          habilitado: editar,
          onTap: () => _elegirResponsable(s, equipo),
          child: responsable == null
              ? Text('Sin asignar', style: RkType.bodyMedio.copyWith(color: c.texto2))
              : Row(children: [avatarDe(responsable, chico: true), const SizedBox(width: 8), Text(responsable.primerNombre, style: RkType.bodyMedio.copyWith(color: c.texto))]),
        ),
        _Dato('WhatsApp', Text(telefonoLegible(s.telefono), style: RkType.mono12.copyWith(fontSize: 14, color: c.texto))),
        _Dato('Correo', Text(s.correo)),
        _Dato('Ubicación', Text(s.ciudad ?? '—')),
        _Dato(
          'Perfiles',
          s.enlaces.isEmpty
              ? const Text('—')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final e in s.enlaces)
                    if (enlaceSeguro(e).isNotEmpty)
                      InkWell(
                        onTap: () => Abrir.enlace(e),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 40),
                          alignment: Alignment.centerLeft,
                          child: Text('${e.replaceFirst(RegExp(r'^https?://(www\.)?'), '')} ↗',
                              style: RkType.body.copyWith(color: c.texto, decoration: TextDecoration.underline, decorationColor: RkColors.rosa)),
                        ),
                      ),
                ]),
        ),
        _Dato('Quiere', Text((s.quiere ?? '').isEmpty ? '—' : '“${s.quiere}”')),
        _Dato('Contactar', Text([s.contactarPor, s.contactarCuando].whereType<String>().where((x) => x.isNotEmpty).join(' · ').ifEmpty('—'))),
        Padding(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 20, RkSpace.g, 8),
          child: TextField(
            controller: _notas,
            enabled: editar,
            minLines: 3,
            maxLines: 8,
            onChanged: (v) => _notasCambiaron(s, v),
            decoration: const InputDecoration(labelText: 'NOTAS INTERNAS · SOLO EL EQUIPO', alignLabelWithHint: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: RkSpace.g),
          child: Semantics(liveRegion: true, child: Text(_guardado.isEmpty ? 'Se guardan solas.' : _guardado, style: RkType.mono11.copyWith(color: c.texto3))),
        ),
        const SizedBox(height: 32),
      ]),
      bottomNavigationBar: hacerCliente || puede(perfil, 'clientes', editar: true)
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, RkSpace.g, 10),
                decoration: BoxDecoration(color: c.s2, border: Border(top: BorderSide(color: c.linea2))),
                child: FilledButton(onPressed: hacerCliente ? () => _hacerCliente(s) : null, child: Text(sinRed ? 'SIN CONEXIÓN' : 'HACER CLIENTE')),
              ),
            )
          : null,
    );
  }
}

extension on String {
  String ifEmpty(String otro) => isEmpty ? otro : this;
}

class _Acciones extends StatelessWidget {
  const _Acciones({required this.s, required this.mensaje});
  final Solicitud s;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return RkAcciones([
      RkAccion('Llamar', Symbols.call_sharp, () => Abrir.llamar(s.telefono), principal: true),
      RkAccion('WhatsApp', Symbols.chat_sharp, () => Abrir.whatsapp(s.telefono, texto: mensaje), colorIcono: c.ok),
      RkAccion('Correo', Symbols.mail_sharp, () => Abrir.correo(s.correo, asunto: 'RAKÜN · tu solicitud')),
    ]);
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.etiqueta, required this.child, required this.onTap, required this.habilitado});
  final String etiqueta;
  final Widget child;
  final VoidCallback onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return InkWell(
      onTap: habilitado ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.fromLTRB(RkSpace.g, 10, 12, 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(etiqueta.toUpperCase(), style: RkType.mono11.copyWith(color: c.texto3)),
              const SizedBox(height: 6),
              child,
            ]),
          ),
          if (habilitado) Icon(Symbols.expand_more_sharp, color: c.texto3),
        ]),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor);
  final String etiqueta;
  final Widget valor;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 104, child: Text(etiqueta.toUpperCase(), style: RkType.mono11.copyWith(color: c.texto3, height: 1.6))),
        const SizedBox(width: 12),
        Expanded(child: DefaultTextStyle.merge(style: RkType.body.copyWith(color: c.texto), child: valor)),
      ]),
    );
  }
}
