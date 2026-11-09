import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    final r = await mostrarHoja<String>(context, titulo: titulo, cuerpo: _Lista(opciones: opciones, actual: departamento ? _dep : _ciudad));
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
        Expanded(child: campo('Departamento', _Selector(valor: _dep, vacio: 'Elegir', onTap: () => _elegir(departamento: true)))),
        const SizedBox(width: 10),
        Expanded(
          child: campo(
            _dep == fueraDeColombia ? 'País' : 'Ciudad',
            _Selector(valor: _ciudad, vacio: _dep == null ? 'Primero el depto.' : 'Elegir', onTap: _dep == null ? null : () => _elegir(departamento: false)),
          ),
        ),
      ]),
      if (_error != null) ...[Text(_error!, style: RkType.small.copyWith(color: c.texto)), const SizedBox(height: 12)],
      const SizedBox(height: 4),
      FilledButton(onPressed: _guardando ? null : _guardar, child: Text(_guardando ? 'GUARDANDO…' : 'GUARDAR Y CREAR ACCESO')),
    ]);
  }
}

/// Parece un campo; al tocarlo abre la lista (nadie escribe la ciudad a mano).
class _Selector extends StatelessWidget {
  const _Selector({required this.valor, required this.vacio, this.onTap});
  final String? valor;
  final String vacio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: onTap == null ? c.linea : c.linea2)),
          child: Row(children: [
            Expanded(
              child: Text(valor ?? vacio, maxLines: 1, overflow: TextOverflow.ellipsis, style: RkType.body.copyWith(color: valor == null ? c.texto3 : c.texto)),
            ),
            Icon(Symbols.expand_more_sharp, size: 20, color: onTap == null ? c.texto3 : c.texto2),
          ]),
        ),
      ),
    );
  }
}

/// Lista para elegir, con buscador (Antioquia tiene 125 municipios).
class _Lista extends StatefulWidget {
  const _Lista({required this.opciones, this.actual});
  final List<String> opciones;
  final String? actual;

  @override
  State<_Lista> createState() => _ListaState();
}

class _ListaState extends State<_Lista> {
  String _q = '';

  static String _sinTildes(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .replaceAll('ñ', 'n');

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final q = _sinTildes(_q.trim());
    final lista = widget.opciones.where((o) => q.isEmpty || _sinTildes(o).contains(q)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.opciones.length > 8)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(hintText: 'Buscar…', prefixIcon: Icon(Symbols.search_sharp)),
          ),
        ),
      for (final o in lista)
        InkWell(
          onTap: () => Navigator.pop(context, o),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
            child: Row(children: [
              Expanded(child: Text(o, style: RkType.body.copyWith(color: c.texto))),
              if (o == widget.actual) Icon(Symbols.check_sharp, size: 20, color: c.rosaTexto),
            ]),
          ),
        ),
      if (lista.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text('Nada con «$_q».', style: RkType.body.copyWith(color: c.texto2))),
    ]);
  }
}
