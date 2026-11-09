import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/datos/ubicacion.dart';
import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/sync/datos.dart';
import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/abrir.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/clientes_repo.dart';
import '../domain/cliente.dart';
import 'acceso_hoja.dart';
import 'nuevo_cliente_hoja.dart';

enum _Filtro { todos, conAcceso, sinAcceso }

/// 02 · Clientes: lista con búsqueda y filtro por acceso al portal, llamar a un toque,
/// ficha con contacto y acceso, y "+" para un cliente nuevo (como viewClients de admin.js).
class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  _Filtro _filtro = _Filtro.todos;
  bool _buscando = false;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final async = ref.watch(clientesProvider);
    final mundos = ref.watch(mundosPorClienteProvider).value ?? const {};
    final perfil = ref.watch(perfilProvider).value;
    final datos = async.value;
    final sinRed = ref.watch(sinConexionProvider) || (datos?.desdeCache ?? false);
    final editar = puede(perfil, 'clientes', editar: true) && !sinRed;

    final barra = RkBarraGrande(
      titulo: 'Clientes',
      indice: '02',
      atras: Navigator.canPop(context),
      acciones: [
        IconButton(
          tooltip: _buscando ? 'Cerrar búsqueda' : 'Buscar',
          icon: Icon(_buscando ? Symbols.close_sharp : Symbols.search_sharp),
          onPressed: () => setState(() {
            _buscando = !_buscando;
            if (!_buscando) _q = '';
          }),
        ),
        IconButton(tooltip: 'Actualizar', icon: const Icon(Symbols.refresh_sharp), onPressed: () => ref.invalidate(clientesProvider)),
      ],
    );

    if (datos == null) {
      final cuerpo = async.hasError
          ? (async.error is SinPermiso
              ? RkSinPermiso(onIrAHoy: () => context.go('/hoy'))
              : RkError(mensaje: textoDeError(async.error), onReintentar: () => ref.invalidate(clientesProvider)))
          : const RkEsqueleto();
      return CustomScrollView(slivers: [barra, SliverToBoxAdapter(child: cuerpo)]);
    }

    final buscados = datos.valor.where((x) => x.coincide(_q)).toList();
    final cuenta = {
      _Filtro.todos: buscados.length,
      _Filtro.conAcceso: buscados.where((x) => x.conAcceso).length,
      _Filtro.sinAcceso: buscados.where((x) => !x.conAcceso).length,
    };
    final lista = buscados
        .where((x) => switch (_filtro) {
              _Filtro.todos => true,
              _Filtro.conAcceso => x.conAcceso,
              _Filtro.sinAcceso => !x.conAcceso,
            })
        .toList();

    return Stack(children: [
      RefreshIndicator(
        color: RkColors.rosa,
        onRefresh: () => ref.refresh(clientesProvider.future),
        child: CustomScrollView(slivers: [
          barra,
          if (datos.desdeCache) SliverToBoxAdapter(child: RkSinConexion(desde: horaCorta(datos.guardadoA!))),
          if (_buscando)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 0),
                child: TextField(
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(hintText: 'Nombre, marca, correo, ciudad…', prefixIcon: Icon(Symbols.search_sharp)),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _Filtros(actual: _filtro, cuenta: cuenta, onElegir: (f) => setState(() => _filtro = f))),
          if (datos.valor.isEmpty)
            const SliverToBoxAdapter(
              child: RkVacio(antes: 'Aún sin', rosa: 'clientes.', texto: 'Convierte una solicitud o crea uno con el botón +.'),
            )
          else if (lista.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(RkSpace.g),
                child: Text(_q.isNotEmpty ? 'Nadie con «$_q».' : 'Nadie en este filtro.', style: RkType.body.copyWith(color: c.texto2)),
              ),
            )
          else
            SliverList.builder(
              itemCount: lista.length,
              itemBuilder: (_, i) => _Fila(x: lista[i], mundos: mundos[lista[i].id] ?? const {}, editar: editar),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ]),
      ),
      if (editar)
        Positioned(
          right: RkSpace.g,
          bottom: 16,
          child: RkFab(etiqueta: 'Nuevo cliente', onPressed: () => mostrarNuevoCliente(context)),
        ),
    ]);
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.actual, required this.cuenta, required this.onElegir});
  final _Filtro actual;
  final Map<_Filtro, int> cuenta;
  final ValueChanged<_Filtro> onElegir;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    Widget chip(_Filtro f, String nombre) {
      final on = f == actual;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          selected: on,
          button: true,
          child: InkWell(
            onTap: () => onElegir(f),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.center,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: on ? c.texto : Colors.transparent, border: Border.all(color: on ? c.texto : c.linea2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(nombre, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: on ? c.fondo : c.texto2)),
                  const SizedBox(width: 8),
                  Text('${cuenta[f] ?? 0}', style: RkType.mono11.copyWith(color: on ? c.fondo : c.texto3)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: RkSpace.g, vertical: 6), children: [
        chip(_Filtro.todos, 'Todos'),
        chip(_Filtro.conAcceso, 'Con acceso'),
        chip(_Filtro.sinAcceso, 'Sin acceso'),
      ]),
    );
  }
}

/// "Pereira, Risaralda" → "Pereira" para la lista (la ficha muestra el texto completo).
String _ciudadCorta(String? ciudad) => leerUbicacion(ciudad)?.ciudad ?? ciudad ?? '';

class _Fila extends StatelessWidget {
  const _Fila({required this.x, required this.mundos, required this.editar});
  final Cliente x;
  final Set<Mundo> mundos;
  final bool editar;

  @override
  Widget build(BuildContext context) {
    final linea = [if (x.empresa != null) x.nombre, _ciudadCorta(x.ciudad)].where((s) => s.isNotEmpty).join(' · ');
    return RkFila(
      titulo: x.titulo,
      onTap: () => mostrarFichaCliente(context, x),
      subtitulo: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (linea.isNotEmpty) Text(linea, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (mundos.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 10, runSpacing: 4, children: [for (final m in Mundo.values) if (mundos.contains(m)) RkMundo(m)]),
        ],
      ]),
      final_: Row(mainAxisSize: MainAxisSize.min, children: [
        if (x.conAcceso)
          const RkEtiqueta('Acceso', tono: RkTono.ok)
        else if (editar)
          OutlinedButton(
            // compacto (como el prototipo): no le quita espacio al nombre
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: RkType.mono11,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: () => mostrarAcceso(context, PersonaAcceso(nombre: x.nombre, correo: x.correo, telefono: x.telefono, clienteId: x.id)),
            child: const Text('CREAR ACCESO'),
          )
        else
          const RkEtiqueta('Sin acceso', tono: RkTono.apagada),
        if ((x.telefono ?? '').isNotEmpty)
          IconButton(tooltip: 'Llamar a ${x.titulo}', icon: const Icon(Symbols.call_sharp), onPressed: () => Abrir.llamar(x.telefono!))
        else
          const SizedBox(width: 48), // mismo hueco que el botón de llamar: las etiquetas quedan alineadas
      ]),
    );
  }
}

/// Ficha del cliente en una hoja: contacto a un toque y su acceso al portal.
/// Eliminar cliente es P3 (sigue en la web, con su confirmación fuerte).
Future<void> mostrarFichaCliente(BuildContext context, Cliente x) => mostrarHoja<void>(
      context,
      titulo: x.titulo,
      cuerpo: _Ficha(x),
    );

class _Ficha extends ConsumerWidget {
  const _Ficha(this.x);
  final Cliente x;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final sinRed = ref.watch(sinConexionProvider);
    final editar = puede(perfil, 'clientes', editar: true) && !sinRed;
    final mundos = ref.watch(mundosPorClienteProvider).value?[x.id] ?? const {};
    final tel = x.telefono ?? '';

    Widget dato(String rotulo, String valor) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mayus(rotulo), style: RkType.mono11.copyWith(color: c.texto3)),
            const SizedBox(height: 2),
            SelectableText(valor, style: RkType.body.copyWith(color: c.texto)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RkEtiqueta(x.conAcceso ? 'Con acceso' : 'Sin acceso', tono: x.conAcceso ? RkTono.ok : RkTono.apagada),
        for (final m in Mundo.values)
          if (mundos.contains(m)) RkMundo(m),
      ]),
      const SizedBox(height: 16),
      RkAcciones([
        if (tel.isNotEmpty) ...[
          RkAccion('Llamar', Symbols.call_sharp, () => Abrir.llamar(tel), principal: true),
          RkAccion('WhatsApp', Symbols.chat_sharp, () => Abrir.whatsapp(tel), colorIcono: c.ok),
        ],
        RkAccion('Correo', Symbols.mail_sharp, () => Abrir.correo(x.correo)),
      ]),
      const SizedBox(height: 20),
      if (x.empresa != null) dato('Persona', x.nombre),
      dato('Correo · con este entra al portal', x.correo),
      if (tel.isNotEmpty) dato('WhatsApp', tel),
      if (x.ciudad != null) dato('Ciudad', x.ciudad!),
      if (x.notas != null) dato('Notas', x.notas!),
      dato('Cliente desde', diaCorto(x.creado)),
      if (editar) ...[
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: () => mostrarAcceso(context, PersonaAcceso(nombre: x.nombre, correo: x.correo, telefono: x.telefono, clienteId: x.id)),
          icon: Icon(x.conAcceso ? Symbols.link_sharp : Symbols.key_sharp, size: 20),
          label: Text(x.conAcceso ? 'NUEVO ENLACE' : 'CREAR ACCESO'),
        ),
        if (x.conAcceso)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Ya tiene cuenta: el enlace nuevo le deja crear otra contraseña.', style: RkType.small.copyWith(color: c.texto3)),
          ),
      ] else if (sinRed)
        Text('Sin conexión: el acceso se crea cuando vuelva la red.', style: RkType.small.copyWith(color: c.texto3)),
    ]);
  }
}
