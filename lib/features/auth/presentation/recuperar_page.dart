import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/supabase/sesion.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

/// "Olvidé mi contraseña": el enlace llega al correo y abre cuenta.html en la web.
class RecuperarPage extends ConsumerStatefulWidget {
  const RecuperarPage({super.key});

  @override
  ConsumerState<RecuperarPage> createState() => _RecuperarPageState();
}

class _RecuperarPageState extends ConsumerState<RecuperarPage> {
  final _correo = TextEditingController();
  bool _enviando = false, _listo = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_correo.text.trim())) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(cuentaProvider).recuperar(_correo.text);
      if (mounted) setState(() => _listo = true);
    } catch (e) {
      if (mounted) setState(() => _error = textoDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return Scaffold(
      appBar: AppBar(shape: const Border(), leading: const BackButton()),
      body: ListView(padding: const EdgeInsets.fromLTRB(RkSpace.g, 8, RkSpace.g, 24), children: [
        Text.rich(
          const TextSpan(children: [TextSpan(text: 'TE MANDAMOS '), TextSpan(text: 'UN ENLACE.', style: TextStyle(color: RkColors.rosa))]),
          style: RkType.display(44, height: .86).copyWith(color: c.texto),
        ),
        const SizedBox(height: 16),
        Text(
          'Escribe tu correo. Te llega un enlace para crear una contraseña nueva; se abre en la página de RAKÜN.',
          style: RkType.body.copyWith(color: c.texto2),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _correo,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _enviar(),
          decoration: const InputDecoration(labelText: 'CORREO', hintText: 'tu@correo.com'),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: RkType.small.copyWith(color: c.texto))),
        if (_listo)
          Semantics(
            liveRegion: true,
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.linea)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Symbols.mark_email_read_sharp, color: c.ok),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Listo. Si ese correo tiene cuenta, el enlace llega en un par de minutos. Revisa también Spam.',
                    style: RkType.small.copyWith(color: c.texto2),
                  ),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 32),
        FilledButton(onPressed: _enviando ? null : _enviar, child: Text(_enviando ? 'ENVIANDO…' : 'ENVIAR ENLACE')),
      ]),
    );
  }
}
