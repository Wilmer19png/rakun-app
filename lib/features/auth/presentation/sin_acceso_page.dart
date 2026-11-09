import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/sesion.dart';
import '../../../design_system/ojo/ojo.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

/// Cuenta de cliente en v1: la app es del equipo; su portal sigue en la web.
class SinAccesoPage extends ConsumerWidget {
  const SinAccesoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 56, RkSpace.g, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Align(alignment: Alignment.centerLeft, child: RakunOjo(ancho: 132)),
            const SizedBox(height: 28),
            Text.rich(
              const TextSpan(children: [TextSpan(text: 'ESTA APP ES '), TextSpan(text: 'DEL EQUIPO.', style: TextStyle(color: RkColors.rosa))]),
              style: RkType.display(44, height: .86).copyWith(color: c.texto),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu cuenta es de cliente. Tu portal sigue en la página de RAKÜN: ahí ves tus proyectos, tu parrilla y tus documentos.',
              style: RkType.body.copyWith(color: c.texto2),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => launchUrl(Uri.parse('${Env.webUrl}/portal.html'), mode: LaunchMode.externalApplication),
              child: const Text('ABRIR MI PORTAL'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => ref.read(cuentaProvider).salir(), child: const Text('SALIR')),
          ]),
        ),
      ),
    );
  }
}
