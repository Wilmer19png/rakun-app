import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/datos/ubicacion.dart';
import '../../../core/errores/errores.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/clientes_repo.dart';
import '../domain/cliente.dart';
import 'acceso_hoja.dart';

/// "Nuevo cliente" (newClientForm de admin.js): nombre, empresa, correo, WhatsApp y departamento → ciudad.
/// Al guardar se abre "Crear acceso", igual que en la web.
Future<void> mostrarNuevoCliente(BuildContext context) async {
  final creado = await mostrarHoja<Cliente>(context, titulo: 'Nuevo cliente', cuerpo: const _Nuevo());
  if (creado != null && context.mounted) {
    await mostrarAcceso(context, PersonaAcceso(nombre: creado.nombre, correo: creado.correo, telefono: creado.telefono, clienteId: creado.id));
  }
}

class _Nuevo extends ConsumerStatefulWidget {
  const _Nuevo();

  @override
  ConsumerState<_Nuevo> createState() => _NuevoState();
}

class _NuevoState extends ConsumerState<_Nuevo> {
  final _nombre = TextEditingController();
  final _empresa = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  String? _dep, _ciudad, _error;
  bool _guardando = false;

  @override
  void dispose() {
    for (final t in [_nombre, _empresa, _correo, _telefono]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final error = errorNuevoCliente(nombre: _nombre.text, correo: _correo.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final x = await ref.read(clientesRepoProvider).crear(
            nombre: _nombre.text,
            empresa: _empresa.text,
            correo: _correo.text,
            telefono: _telefono.text,
            ciudad: escribirUbicacion(_dep, _ciudad),
          );
      ref.invalidate(clientesProvider);
      if (mounted) Navigator.pop(context, x);
    } on CorreoRepetido catch (e) {
      setState(() => _error = '$e');
    } catch (e) {
      setState(() => _error = textoDeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _elegir({required bool departamento}) async {
    final opciones = departamento ? departamentos : opcionesDe(_dep);
    final titulo = departamento ? 'Departamento' : (_dep == fueraDeColombia ? 'País' : 'Ciudad');
    final r = await elegirEnHoja<String>(context, titulo: titulo, opciones: [for (final o in opciones) (o, o)], actual: departamento ? _dep : _ciudad);
    if (r == null) return;
    setState(() {
      if (departamento) {
        if (r != _dep) _ciudad = ciudadUnica(r);
        _dep = r;
      } else {
        _ciudad = r;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    Widget campo(String rotulo, Widget hijo) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(rotulo, style: RkType.small.copyWith(color: c.texto2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            hijo,
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      campo(
        'Nombre *',
        TextField(controller: _nombre, autofocus: true, maxLength: 160, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.name], textInputAction: TextInputAction.next, decoration: const InputDecoration(counterText: '')),
      ),
      campo('Empresa o marca', TextField(controller: _empresa, maxLength: 160, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, decoration: const InputDecoration(counterText: ''))),
      campo(
        'Correo * · con este entra al portal',
        TextField(controller: _correo, keyboardType: TextInputType.emailAddress, autocorrect: false, autofillHints: const [AutofillHints.email], textInputAction: TextInputAction.next),
      ),
      campo(
        'WhatsApp',
        TextField(
          controller: _telefono,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(hintText: '3001234567'),
        ),
      ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: campo('Departamento', RkCampoElegible(texto: _dep ?? 'Elegir', vacio: _dep == null, onTap: () => _elegir(departamento: true)))),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            _dep == fueraDeColombia ? 'País' : 'Ciudad',
            RkCampoElegible(texto: _ciudad ?? (_dep == null ? 'Primero el depto.' : 'Elegir'), vacio: _ciudad == null, onTap: _dep == null ? null : () => _elegir(departamento: false)),
          ),
        ),
      ]),
      if (_error != null) ...[Text(_error!, style: RkType.small.copyWith(color: c.texto)), const SizedBox(height: 12)],
      const SizedBox(height: 4),
      FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'GUARDANDO…' : 'GUARDAR Y CREAR ACCESO')),
    ]);
  }
}
