import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/equipo.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/proyectos_repo.dart';
import '../domain/proyecto.dart';
import 'ficha_proyecto_page.dart';

/// "Nuevo proyecto" (newProject de la web): cliente, tipo, nombre, plan, fechas y a cargo.
/// Arranca en la primera etapa de su mundo y abre su ficha.
Future<void> mostrarNuevoProyecto(BuildContext context) async {
  final id = await mostrarHoja<String>(context, titulo: 'Nuevo proyecto', cuerpo: const _Nuevo());
  if (id != null && context.mounted) context.push('/proyectos/$id');
}

class _Nuevo extends ConsumerStatefulWidget {
  const _Nuevo();

  @override
  ConsumerState<_Nuevo> createState() => _NuevoState();
}

class _NuevoState extends ConsumerState<_Nuevo> {
  final _nombre = TextEditingController();
  final _plan = TextEditingController();
  String? _cliente, _aCargo, _error;
  Mundo _mundo = Mundo.marca;
  DateTime? _inicio, _fin;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _plan.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_cliente == null) return setState(() => _error = 'Elige el cliente.');
    // la base pide de 2 a 160 letras; la web solo avisa si está vacío
    if (_nombre.text.trim().length < 2) return setState(() => _error = 'Ponle un nombre al proyecto (mínimo 2 letras).');
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final id = await ref.read(proyectosRepoProvider).crear(
            clienteId: _cliente!,
            mundo: claveMundo(_mundo),
            nombre: _nombre.text,
            plan: _plan.text,
            inicio: _inicio,
            fin: _fin,
            aCargo: _aCargo,
          );
      ref.invalidate(proyectosProvider);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      setState(() => _error = textoDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<DateTime?> _fecha(DateTime? actual, String ayuda) {
    final hoy = DateTime.now();
    return showDatePicker(context: context, initialDate: actual ?? hoy, firstDate: DateTime(hoy.year - 2), lastDate: DateTime(hoy.year + 3), helpText: ayuda);
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final clientes = ref.watch(clientesParaProyectoProvider);
    final equipo = ref.watch(equipoProvider).value ?? const <Perfil>[];
    final lista = clientes.value ?? const <(String, String)>[];

    if (clientes.hasValue && lista.isEmpty) {
      return Text('Para crear un proyecto necesitas al menos un cliente. Créalo en Clientes o convierte una solicitud.', style: RkType.body.copyWith(color: c.texto2));
    }

    Widget campo(String rotulo, Widget hijo) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(rotulo, style: RkType.small.copyWith(color: c.texto2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            hijo,
          ]),
        );
    final nombreCliente = lista.where((x) => x.$1 == _cliente).firstOrNull?.$2 ?? (clientes.isLoading ? 'Cargando…' : 'Elegir');

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      campo(
        'Cliente *',
        RkCampoElegible(
          texto: nombreCliente,
          vacio: _cliente == null,
          onTap: lista.isEmpty
              ? null
              : () async {
                  final r = await elegirEnHoja<String>(context, titulo: 'Cliente', opciones: lista, actual: _cliente);
                  if (r != null) setState(() => _cliente = r);
                },
        ),
      ),
      campo(
        'Tipo *',
        Row(children: [
          for (final m in Mundo.values)
            Expanded(
              child: Semantics(
                selected: m == _mundo,
                button: true,
                child: InkWell(
                  onTap: () => setState(() => _mundo = m),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(color: m == _mundo ? c.texto : Colors.transparent, border: Border.all(color: m == _mundo ? c.texto : c.linea2)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      RkMundo(m, conNombre: false),
                      const SizedBox(width: 6),
                      Text(m.nombre, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: m == _mundo ? c.fondo : c.texto2)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
      campo(
        'Nombre del proyecto *',
        TextField(controller: _nombre, maxLength: 160, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Redes · noviembre', counterText: '')),
      ),
      campo('Plan', TextField(controller: _plan, maxLength: 160, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Agenda llena', counterText: ''))),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: campo(
            'Inicio',
            RkCampoElegible(
              texto: _inicio == null ? 'Sin fecha' : fechaLarga(_inicio!),
              vacio: _inicio == null,
              onTap: () async {
                final r = await _fecha(_inicio, 'INICIO');
                if (r != null) setState(() => _inicio = r);
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            'Entrega / cierre',
            RkCampoElegible(
              texto: _fin == null ? 'Sin fecha' : fechaLarga(_fin!),
              vacio: _fin == null,
              onTap: () async {
                final r = await _fecha(_fin ?? _inicio, 'ENTREGA / CIERRE');
                if (r != null) setState(() => _fin = r);
              },
            ),
          ),
        ),
      ]),
      campo(
        'A cargo',
        RkCampoElegible(
          texto: equipo.where((x) => x.id == _aCargo).firstOrNull?.nombre ?? 'Sin asignar',
          vacio: _aCargo == null,
          onTap: () async {
            final r = await elegirPersona(context, titulo: 'A cargo', equipo: equipo, actual: _aCargo, vacio: 'Sin asignar');
            if (r != null) setState(() => _aCargo = r.id);
          },
        ),
      ),
      if (_error != null) ...[Text(_error!, style: RkType.small.copyWith(color: c.texto)), const SizedBox(height: 12)],
      const SizedBox(height: 4),
      FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'CREANDO…' : 'CREAR PROYECTO')),
    ]);
  }
}
