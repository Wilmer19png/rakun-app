import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/sesion.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/ojo/ojo.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

/// 00 · Hoy. En la Fase 4 solo existe el saludo real; las listas (vencido, te toca
/// revisar, hoy, solicitudes, agenda, mensajes, lo que ganas) se conectan en la Fase 6.
class HoyPage extends ConsumerWidget {
  const HoyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final nombre = perfil?.primerNombre ?? 'equipo';
    final ahora = reloj();
    return SafeArea(
      bottom: false,
      child: ListView(padding: EdgeInsets.zero, children: [
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 16, RkSpace.g, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${diaCorto(ahora).toUpperCase()} · '),
                      TextSpan(text: '00', style: TextStyle(color: c.rosaTexto)),
                      const TextSpan(text: ' HOY'),
                    ]),
                    style: RkType.mono12.copyWith(letterSpacing: 12 * .06, color: c.texto2),
                  ),
                ),
              ),
              const RakunOjo(ancho: 88),
            ]),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [const TextSpan(text: 'HOLA, '), TextSpan(text: '${mayus(nombre)}.', style: const TextStyle(color: RkColors.rosa))]),
              style: RkType.saludo.copyWith(color: c.texto),
            ),
          ]),
        ),
        const RkVacio(
          antes: 'La base',
          rosa: 'está lista.',
          texto: 'Tus pendientes, lo que te toca revisar, las solicitudes nuevas y la agenda de hoy aparecen aquí cuando conectemos esta sección (Fase 6).',
        ),
      ]),
    );
  }
}
