import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/errores/errores.dart';
import '../../../core/supabase/sesion.dart';
import '../../../design_system/ojo/ojo.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

/// Entrada (splash): siempre en noche, el ojo se abre, RAKÜN + STUDIO y la onda.
/// Dura menos de 1,5 s; si el perfil no carga, lo dice claro y deja reintentar.
class EntradaPage extends ConsumerWidget {
  const EntradaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider);
    final haySesion = ref.watch(sesionProvider).value != null;
    final fallo = haySesion && (perfil.hasError || (perfil.hasValue && perfil.value == null));
    return Scaffold(
      backgroundColor: RkColors.noche,
      body: Stack(children: [
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const RakunOjo(ancho: 220, abreAlEntrar: true),
            const SizedBox(height: 28),
            Semantics(
              label: 'RAKÜN Studio',
              excludeSemantics: true,
              child: Column(children: [
                Text.rich(
                  const TextSpan(children: [TextSpan(text: 'RAK'), TextSpan(text: 'Ü', style: TextStyle(color: RkColors.rosa)), TextSpan(text: 'N')]),
                  style: RkType.display(52, height: .86).copyWith(color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text('STUDIO', style: RkType.mono12.copyWith(letterSpacing: 12 * .3, color: RkColors.lila)),
              ]),
            ),
            if (fallo) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  perfil.hasError ? textoDeError(perfil.error) : 'No encontramos tu perfil en RAKÜN.',
                  textAlign: TextAlign.center,
                  style: RkType.small.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Row(mainAxisSize: MainAxisSize.min, children: [
                FilledButton(onPressed: () => ref.invalidate(perfilProvider), child: const Text('REINTENTAR')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref.read(cuentaProvider).salir(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('SALIR'),
                ),
              ]),
            ],
          ]),
        ),
        const Positioned(left: 0, right: 0, bottom: 0, height: 84, child: Onda()),
      ]),
    );
  }
}

/// La onda de la marca (assets/brand/pattern-wave.svg) repetida a lo ancho.
class Onda extends StatelessWidget {
  const Onda({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(builder: (context, c) {
        final ancho = c.maxHeight * 310 / 260;
        final n = (c.maxWidth / ancho).ceil() + 1;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: n * ancho,
            child: Row(children: List.generate(n, (_) => SvgPicture.asset('assets/brand/pattern-wave.svg', width: ancho, height: c.maxHeight, fit: BoxFit.fill))),
          ),
        );
      }),
    );
  }
}
