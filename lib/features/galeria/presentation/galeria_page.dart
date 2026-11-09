import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../design_system/apariencia.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/ojo/ojo.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';

/// Galería interna de componentes: para comparar con el prototipo aprobado (design/).
/// Los textos son de ejemplo y lo dicen.
class GaleriaPage extends ConsumerWidget {
  const GaleriaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = RkColors.of(context);
    final ap = ref.watch(aparienciaProvider);
    Widget titulo(String t) => RkGrupo(t);
    return CustomScrollView(slivers: [
      RkBarraGrande(
        titulo: 'Galería',
        atras: true,
        acciones: [
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(ap == Apariencia.claro ? Symbols.dark_mode : Symbols.light_mode),
            onPressed: () => ref.read(aparienciaProvider.notifier).elegir(ap == Apariencia.claro ? Apariencia.oscuro : Apariencia.claro),
          ),
        ],
      ),
      SliverList.list(children: [
        Padding(
          padding: const EdgeInsets.all(RkSpace.g),
          child: Text('Todo lo de esta pantalla es de ejemplo.', style: RkType.small.copyWith(color: c.texto3)),
        ),
        titulo('Color'),
        Padding(
          padding: const EdgeInsets.all(RkSpace.g),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (n, col) in [
              ('rosa', RkColors.rosa),
              ('amarillo', RkColors.amarillo),
              ('azul', RkColors.azul),
              ('navy', RkColors.navy),
              ('fondo', c.fondo),
              ('s1', c.s1),
              ('s2', c.s2),
              ('texto', c.texto),
              ('texto2', c.texto2),
              ('texto3', c.texto3),
              ('ok', c.ok),
            ])
              Column(children: [
                Container(width: 56, height: 40, decoration: BoxDecoration(color: col, border: Border.all(color: c.linea2))),
                const SizedBox(height: 4),
                Text(n, style: RkType.mono11.copyWith(color: c.texto2)),
              ]),
          ]),
        ),
        titulo('Tipografía'),
        Padding(
          padding: const EdgeInsets.all(RkSpace.g),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('HOLA, EJEMPLO.', style: RkType.saludo.copyWith(color: c.texto)),
            Text('SECCIÓN', style: RkType.seccion.copyWith(color: c.texto)),
            Text('NOMBRE DE FICHA', style: RkType.ficha.copyWith(color: c.texto)),
            const SizedBox(height: 8),
            Text('Jost 400 · texto de lectura a 16, así se ve un párrafo normal.', style: RkType.body.copyWith(color: c.texto)),
            Text('Jost 400 · segunda línea a 14', style: RkType.small.copyWith(color: c.texto2)),
            Text('MONO 12 · 9 NOV · \$1.990.000', style: RkType.mono12.copyWith(color: c.texto2)),
          ]),
        ),
        titulo('Mundos y etiquetas'),
        Padding(
          padding: const EdgeInsets.all(RkSpace.g),
          child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final m in Mundo.values) RkMundo(m),
            const RkEtiqueta('Nueva', tono: RkTono.accion),
            const RkEtiqueta('En curso'),
            const RkEtiqueta('Por hacer', tono: RkTono.apagada),
            const RkEtiqueta('Ganado', tono: RkTono.ok),
            const RkIndice('01'),
          ]),
        ),
        const RkGrupo('Vencido (ejemplo)', cuenta: 2, urgente: true),
        RkFila(
          titulo: 'Guiones del mes',
          subtitulo: const Row(children: [RkMundo(Mundo.marca), SizedBox(width: 6), Flexible(child: Text('Marca Ejemplo'))]),
          final_: IconButton(onPressed: () {}, tooltip: 'Entregar', icon: const Icon(Symbols.upload)),
          onTap: () {},
        ),
        RkFila(titulo: 'Fila nueva', nueva: true, subtitulo: const Text('Con punto rosa'), onTap: () {}),
        titulo('Botones'),
        Padding(
          padding: const EdgeInsets.all(RkSpace.g),
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton(onPressed: () {}, child: const Text('ENTREGAR')),
            OutlinedButton(onPressed: () {}, child: const Text('DEVOLVER')),
            const FilledButton(onPressed: null, child: Text('SIN CONEXIÓN')),
            RkFab(onPressed: () {}, etiqueta: 'Nuevo (ejemplo)'),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 0, RkSpace.g, RkSpace.g),
          child: OutlinedButton(
            onPressed: () => mostrarHoja<void>(
              context,
              titulo: 'Hoja de ejemplo',
              cuerpo: const TextField(decoration: InputDecoration(labelText: 'CAMPO')),
              pie: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('GUARDAR')),
            ),
            child: const Text('ABRIR HOJA INFERIOR'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(RkSpace.g, 0, RkSpace.g, RkSpace.g),
          child: OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Guardado (ejemplo)'), action: SnackBarAction(label: 'DESHACER', onPressed: () {}))),
            child: const Text('MOSTRAR AVISO'),
          ),
        ),
        titulo('El ojo'),
        const Padding(padding: EdgeInsets.all(RkSpace.g), child: Row(children: [RakunOjo(ancho: 160), SizedBox(width: 16), RakunOjo(ancho: 64, explora: false)])),
        titulo('Estados'),
        const RkEsqueleto(filas: 2),
        const RkSinConexion(desde: '9:12 a. m.'),
        RkError(mensaje: 'No hubo respuesta del servidor (ejemplo).', onReintentar: () {}),
        Padding(padding: const EdgeInsets.all(RkSpace.g), child: Align(alignment: Alignment.centerLeft, child: RkEnVivo(texto: '1 solicitud nueva (ejemplo)', onTap: () {}))),
        const RkVacio(antes: 'Todo', rosa: 'al día.', texto: 'Estado vacío de ejemplo.'),
        const RkSinPermiso(),
        const SizedBox(height: 48),
      ]),
    ]);
  }
}
