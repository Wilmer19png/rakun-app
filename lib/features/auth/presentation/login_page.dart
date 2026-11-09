import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/supabase/sesion.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _ver = false, _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (_correo.text.trim().isEmpty || _clave.text.isEmpty) {
      setState(() => _error = 'Escribe tu correo y tu contraseña.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(cuentaProvider).entrar(_correo.text, _clave.text);
      // la navegación sigue sola cuando cambia la sesión
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
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(padding: const EdgeInsets.fromLTRB(RkSpace.g, 32, RkSpace.g, 24), children: [
            Align(alignment: Alignment.centerLeft, child: SvgPicture.asset('assets/brand/rakun-isotipo.svg', width: 120, height: 120, semanticsLabel: 'RAKÜN')),
            const SizedBox(height: 28),
            Text.rich(
              const TextSpan(children: [TextSpan(text: 'ENTRA AL '), TextSpan(text: 'ESTUDIO.', style: TextStyle(color: RkColors.rosa))]),
              style: RkType.display(44, height: .86).copyWith(color: c.texto),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              decoration: const InputDecoration(labelText: 'CORREO'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clave,
              obscureText: !_ver,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _entrar(),
              decoration: InputDecoration(
                labelText: 'CONTRASEÑA',
                suffixIcon: IconButton(
                  tooltip: _ver ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  icon: Icon(_ver ? Symbols.visibility_off_sharp : Symbols.visibility_sharp),
                  onPressed: () => setState(() => _ver = !_ver),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.push('/recuperar'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, textStyle: RkType.small),
                child: Text(
                  'Olvidé mi contraseña',
                  style: RkType.small.copyWith(color: c.texto, decoration: TextDecoration.underline, decorationColor: RkColors.rosa, decorationThickness: 2),
                ),
              ),
            ),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: RkColors.rosa)),
                  child: Text(_error!, style: RkType.small.copyWith(color: c.texto)),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _enviando ? null : _entrar,
              child: _enviando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: RkColors.navy))
                  : const Text('ENTRAR'),
            ),
          ]),
        ),
      ),
    );
  }
}
