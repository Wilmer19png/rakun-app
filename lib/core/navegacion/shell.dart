import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../design_system/tipografia.dart';
import '../../design_system/tokens.dart';
import '../permisos/permisos.dart';
import '../supabase/sesion.dart';
import 'rutas.dart';

const _info = <Destino, (String, IconData)>{
  Destino.hoy: ('Hoy', Symbols.today_sharp),
  Destino.solicitudes: ('Solicitudes', Symbols.inbox_sharp),
  Destino.clientes: ('Clientes', Symbols.groups_sharp),
  Destino.agenda: ('Agenda', Symbols.calendar_month_sharp),
  Destino.proyectos: ('Proyectos', Symbols.folder_open_sharp),
  Destino.parrillas: ('Parrillas', Symbols.grid_view_sharp),
  Destino.mensajes: ('Mensajes', Symbols.forum_sharp),
  Destino.mas: ('Más', Symbols.menu_sharp),
};

/// Pantallas con barra inferior. La barra se arma con los permisos de quien entra.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.ubicacion, required this.child});
  final String ubicacion;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider).value;
    final destinos = barraPara(perfil);
    var actual = destinos.firstWhere(
      (d) => ubicacion == rutaDe[d] || ubicacion.startsWith('${rutaDe[d]}/'),
      orElse: () => Destino.mas, // subpantalla que no está en la barra: se ilumina su padre
    );
    if (!destinos.contains(actual)) actual = Destino.mas;
    return Scaffold(
      body: child,
      bottomNavigationBar: RkBarraInferior(
        destinos: destinos,
        actual: actual,
        onElegir: (d) => context.go(rutaDe[d]!),
      ),
    );
  }
}

class RkBarraInferior extends StatelessWidget {
  const RkBarraInferior({super.key, required this.destinos, required this.actual, required this.onElegir, this.avisos = const {}});
  final List<Destino> destinos;
  final Destino actual;
  final ValueChanged<Destino> onElegir;
  final Map<Destino, int> avisos;

  @override
  Widget build(BuildContext context) {
    final abajo = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: RkColors.noche, // noche en los dos temas, como el menú del gestor web
      padding: EdgeInsets.only(bottom: abajo),
      child: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x24FFFFFF)))),
        child: SizedBox(
          height: RkSpace.barra,
          child: Row(
            children: [
              for (final d in destinos)
                Expanded(
                  child: _Item(
                    etiqueta: _info[d]!.$1,
                    icono: _info[d]!.$2,
                    activo: d == actual,
                    aviso: avisos[d] ?? 0,
                    onTap: () => onElegir(d),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.etiqueta, required this.icono, required this.activo, required this.aviso, required this.onTap});
  final String etiqueta;
  final IconData icono;
  final bool activo;
  final int aviso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const dim = Color(0xFF9A97BD);
    return Semantics(
      selected: activo,
      button: true,
      label: aviso > 0 ? '$etiqueta, $aviso nuevos' : etiqueta,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Stack(alignment: Alignment.center, children: [
          if (activo) const Positioned(top: 0, left: 18, right: 18, child: SizedBox(height: 3, child: ColoredBox(color: RkColors.rosa))),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(icono, size: 24, fill: activo ? 1 : 0, weight: activo ? 400 : 300, color: activo ? RkColors.rosa : dim),
              if (aviso > 0)
                Positioned(
                  top: -6,
                  left: 18,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    color: RkColors.rosa,
                    alignment: Alignment.center,
                    child: Text('$aviso', style: RkType.mono11.copyWith(color: RkColors.navy, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RkType.small.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: activo ? Colors.white : dim),
            ),
          ]),
        ]),
      ),
    );
  }
}
