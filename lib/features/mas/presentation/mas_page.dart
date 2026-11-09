import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../design_system/apariencia.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../seccion/presentation/seccion_pendiente_page.dart';

/// Más: perfil, el resto de infoSecciones según permisos, y la cuenta (apariencia, clave, salir).
class MasPage extends ConsumerWidget {
  const MasPage({super.key});

  static const _destinoDe = {
    Destino.solicitudes: 'solicitudes',
    Destino.clientes: 'clientes',
    Destino.agenda: 'agenda',
    Destino.proyectos: 'proyectos',
    Destino.parrillas: 'parrillas',
    Destino.mensajes: 'mensajes',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final perfil = ref.watch(perfilProvider).value;
    final enBarra = barraPara(perfil).map((d) => _destinoDe[d]).whereType<String>().toSet();
    final orden = ['clientes', 'parrillas', 'mensajes', 'documentos', 'cotizaciones', 'metricas', 'proyectos', 'agenda', 'solicitudes', 'tarifario', 'equipo', 'trabajo', 'planes'];
    final mostrar = [
      for (final k in orden)
        if (!enBarra.contains(k) && infoSecciones[k]!.puedeVer(perfil)) k,
    ];
    final ahora = mostrar.where((k) => infoSecciones[k]!.prioridad != 'P3').toList();
    final despues = mostrar.where((k) => infoSecciones[k]!.prioridad == 'P3').toList();

    return CustomScrollView(slivers: [
      const RkBarraGrande(titulo: 'Más'),
      SliverToBoxAdapter(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          RkFila(
            titulo: perfil?.nombre.isNotEmpty == true ? perfil!.nombre : (perfil?.email ?? ''),
            subtitulo: Text([perfil?.area ?? (perfil?.esAdmin == true ? 'Admin' : 'Equipo'), if (perfil?.perms == null) 'todo' else rolListoDe(perfil!.perms)].join(' · ')),
            inicio: _Avatar(perfil: perfil),
          ),
          if (ahora.isNotEmpty) _Rejilla(claves: ahora),
          if (despues.isNotEmpty)
            Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.linea))),
              padding: const EdgeInsets.all(RkSpace.g),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Más adelante (P3)', style: TextStyle(color: c.texto2, fontWeight: FontWeight.w500)),
                  TextSpan(text: ' · ${despues.map((k) => infoSecciones[k]!.titulo).join(', ')}. El editor del catálogo sigue en la web.'),
                ]),
                style: RkType.small.copyWith(color: c.texto3),
              ),
            ),
          const RkGrupo('Cuenta'),
          const _Apariencia(),
          RkFila(titulo: 'Cambiar contraseña', final_: Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Symbols.password_sharp, color: c.texto3)), onTap: () => _cambiarClave(context, ref)),
          RkFila(
            titulo: 'Abrir el gestor web',
            subtitulo: const Text('Para lo que solo vive en la web'),
            final_: Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Symbols.open_in_new_sharp, color: c.texto3)),
            onTap: () => launchUrl(Uri.parse('${Env.webUrl}/admin.html'), mode: LaunchMode.externalApplication),
          ),
          if (perfil?.esAdmin == true)
            RkFila(
              titulo: 'Galería de componentes',
              subtitulo: const Text('Para comparar con el diseño aprobado'),
              final_: Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Symbols.palette_sharp, color: c.texto3)),
              onTap: () => context.go('/mas/galeria'),
            ),
          RkFila(
            titulo: 'Salir',
            final_: Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Symbols.logout_sharp, color: c.esClaro ? c.texto : RkColors.rosa)),
            onTap: () => ref.read(cuentaProvider).salir(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(RkSpace.g, 20, RkSpace.g, 24),
            child: Text('RAKÜN Studio 0.2 · base', style: RkType.mono12.copyWith(color: c.texto3)),
          ),
        ]),
      ),
    ]);
  }

  Future<void> _cambiarClave(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    String? error;
    await mostrarHoja<void>(
      context,
      titulo: 'Cambiar contraseña',
      cuerpo: StatefulBuilder(builder: (ctx, set) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: ctrl, obscureText: true, autofillHints: const [AutofillHints.newPassword], decoration: const InputDecoration(labelText: 'CONTRASEÑA NUEVA · MÍNIMO 8')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: RkType.small)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.length < 8) return set(() => error = 'La contraseña es muy corta: usa al menos 8 caracteres.');
              try {
                await ref.read(cuentaProvider).cambiarClave(ctrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña cambiada')));
              } catch (e) {
                set(() => error = textoDeError(e));
              }
            },
            child: const Text('GUARDAR'),
          ),
        ]);
      }),
    );
    ctrl.dispose();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.perfil});
  final Perfil? perfil;

  @override
  Widget build(BuildContext context) {
    final iniciales = (perfil?.nombre.isNotEmpty == true ? perfil!.nombre : (perfil?.email ?? '?'))
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0])
        .join()
        .toUpperCase();
    final hex = perfil?.color;
    final color = hex != null && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex) ? Color(int.parse('FF${hex.substring(1)}', radix: 16)) : RkColors.rosa;
    return Container(width: 48, height: 48, color: color, alignment: Alignment.center, child: Text(iniciales, style: RkType.mono12.copyWith(fontSize: 16, color: RkColors.navy)));
  }
}

class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.claves});
  final List<String> claves;

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    return LayoutBuilder(builder: (context, box) {
      final ancho = box.maxWidth / 2;
      return Wrap(children: [
        for (var i = 0; i < claves.length; i++)
          SizedBox(
            width: ancho,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/mas/seccion/${claves[i]}'),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 104),
                  padding: const EdgeInsets.fromLTRB(RkSpace.g, 14, RkSpace.g, 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.linea), right: i.isEven ? BorderSide(color: c.linea) : BorderSide.none),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    RkIndice(infoSecciones[claves[i]]!.indice),
                    const SizedBox(height: 20),
                    Text(infoSecciones[claves[i]]!.titulo, style: RkType.bodyMedio.copyWith(fontSize: 18, color: c.texto)),
                    const SizedBox(height: 4),
                    Text(infoSecciones[claves[i]]!.prioridad == 'P1' ? 'Llega con P1' : 'Llega con P2', style: RkType.small.copyWith(fontSize: 13, color: c.texto3)),
                  ]),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

class _Apariencia extends ConsumerWidget {
  const _Apariencia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final actual = ref.watch(aparienciaProvider);
    const opciones = [(Apariencia.oscuro, 'Oscuro', Symbols.dark_mode_sharp), (Apariencia.claro, 'Claro', Symbols.light_mode_sharp), (Apariencia.telefono, 'Teléfono', Symbols.smartphone_sharp)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(RkSpace.g, 12, RkSpace.g, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('APARIENCIA', style: RkType.mono12.copyWith(color: c.texto2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(border: Border.all(color: c.linea2)),
          child: Row(children: [
            for (final (valor, nombre, icono) in opciones)
              Expanded(
                child: Semantics(
                  selected: actual == valor,
                  button: true,
                  child: Material(
                    color: actual == valor ? c.texto : Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.read(aparienciaProvider.notifier).elegir(valor),
                      child: SizedBox(
                        height: 48,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(icono, size: 20, color: actual == valor ? c.fondo : c.texto2),
                          const SizedBox(width: 6),
                          Text(nombre, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: actual == valor ? c.fondo : c.texto2)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
