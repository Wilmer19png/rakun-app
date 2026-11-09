import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/sync/en_vivo.dart';
import '../../../core/utils/fechas.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

/// Diagnóstico de los cambios en vivo (solo admin): estado del canal y cada aviso con
/// cuánto tardó desde que la base de datos lo guardó. No muestra el contenido del aviso.
String _hms(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}.${d.millisecond.toString().padLeft(3, '0')}';

class EnVivoPage extends ConsumerWidget {
  const EnVivoPage({super.key});

  static const _nombre = {
    EstadoEnVivo.sinSesion: 'Sin sesión',
    EstadoEnVivo.conectando: 'Conectando…',
    EstadoEnVivo.enVivo: 'En vivo',
    EstadoEnVivo.reconectando: 'Reconectando…',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final s = ref.watch(enVivoProvider);
    final enVivo = s.estado == EstadoEnVivo.enVivo;
    return CustomScrollView(slivers: [
      RkBarraGrande(
        titulo: 'En vivo',
        atras: true,
        acciones: [IconButton(tooltip: 'Reconectar', icon: const Icon(Symbols.sync_sharp), onPressed: () => ref.read(enVivoProvider.notifier).reconectar())],
      ),
      SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RkFila(
            titulo: _nombre[s.estado]!,
            subtitulo: Text('${tablasEnVivo.length} tablas · desde ${s.desde == null ? '—' : horaCorta(s.desde!)}'),
            inicio: Container(width: 12, height: 12, color: enVivo ? c.ok : RkColors.rosa),
          ),
          RkGrupo('Últimos avisos', cuenta: s.avisos.length),
          if (s.avisos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(RkSpace.g),
              child: Text('Aún no llega ningún aviso. Cambia algo en el gestor web y aparece aquí.', style: RkType.body.copyWith(color: c.texto2)),
            ),
          for (final a in s.avisos)
            RkFila(
              titulo: '${a.tabla} · ${a.tipo}',
              // hora de llegada con milisegundos (reloj del teléfono). La demora real se mide contra
              // la hora en que se creó el cambio, corrigiendo la diferencia entre relojes (ver README).
              subtitulo: Text('llegó ${_hms(a.recibido)}'),
            ),
        ]),
      ),
    ]);
  }
}
