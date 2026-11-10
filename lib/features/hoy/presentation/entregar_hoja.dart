import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errores/errores.dart';
import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/utils/texto.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../../proyectos/domain/proyecto.dart';
import '../data/hoy_repo.dart';
import '../domain/tarea.dart';

/// Entregar (el formulario de la web): pegar un enlace **o** subir un archivo de hasta 50 MB
/// (en el celular: cámara, galería o archivos) + nota. Devuelve true si se entregó.
Future<bool> mostrarEntregar(BuildContext context, Tarea t, {Perfil? revisa}) async =>
    await mostrarHoja<bool>(context, titulo: 'Entregar', cuerpo: _Entregar(t, revisa)) ?? false;

class _Entregar extends ConsumerStatefulWidget {
  const _Entregar(this.t, this.revisa);
  final Tarea t;
  final Perfil? revisa;

  @override
  ConsumerState<_Entregar> createState() => _EntregarState();
}

class _EntregarState extends ConsumerState<_Entregar> {
  late final _url = TextEditingController(text: (widget.t.d.entrega ?? '').startsWith('storage:') ? '' : widget.t.d.entrega ?? '');
  final _nota = TextEditingController();
  bool _conArchivo = false;
  File? _archivo;
  String? _nombre;
  int _peso = 0;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _nota.dispose();
    super.dispose();
  }

  Future<void> _elegir(String desde) async {
    setState(() => _error = null);
    try {
      String? ruta, nombre;
      if (desde == 'archivos') {
        final r = (await FilePicker.pickFiles()).firstOrNull;
        ruta = r?.path;
        nombre = r?.name;
      } else {
        final f = desde == 'camara'
            ? await ImagePicker().pickImage(source: ImageSource.camera)
            : await ImagePicker().pickMedia(); // galería: foto o video
        ruta = f?.path;
        nombre = f?.name;
      }
      if (ruta == null || !mounted) return;
      final archivo = File(ruta);
      final peso = await archivo.length();
      setState(() {
        _archivo = archivo;
        _nombre = nombre ?? ruta!.split(Platform.pathSeparator).last;
        _peso = peso;
        _error = peso > maxEntrega ? 'El archivo pesa más de 50 MB: súbelo a Drive y pega el enlace.' : null;
      });
    } catch (e) {
      setState(() => _error = textoDeError(e));
    }
  }

  Future<void> _enviar() async {
    final yo = ref.read(perfilProvider).value?.id;
    if (yo == null) return;
    final d = widget.t.d;
    String url;
    if (_conArchivo) {
      if (_archivo == null) return setState(() => _error = 'Elige el archivo que vas a entregar.');
      if (_peso > maxEntrega) return setState(() => _error = 'El archivo pesa más de 50 MB: súbelo a Drive y pega el enlace.');
    } else {
      final crudo = _url.text.trim();
      if (crudo.isEmpty) return setState(() => _error = 'Pega un enlace o sube un archivo.');
      if (enlaceSeguro(crudo).isEmpty) return setState(() => _error = 'Ese enlace no parece válido.');
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final repo = ref.read(hoyRepoProvider);
    try {
      url = _conArchivo ? await repo.subir(d, _archivo!, _nombre ?? 'entrega') : enlaceSeguro(_url.text);
      await repo.entregar(d, yo: yo, url: url, nota: _nota.text);
      ref.invalidate(tareasProvider);
      ref.invalidate(tareaProvider(d.id));
      if (!mounted) return;
      final quien = widget.revisa?.primerNombre;
      final enRevision = estadoAlEntregar(d, yo: yo) == EstadoEntregable.enRevision;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(enRevision ? '✓ Enviado a revisión de ${quien ?? 'quien revisa'}' : '✓ Entregado')));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _enviando = false;
        _error = textoDeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final d = widget.t.d;
    final yo = ref.watch(perfilProvider).value?.id ?? '';
    final quien = widget.revisa?.primerNombre;
    final aRevision = estadoAlEntregar(d, yo: yo) == EstadoEntregable.enRevision;
    Widget rotulo(String s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(mayus(s), style: RkType.mono11.copyWith(color: c.texto3)));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text.rich(
        TextSpan(children: [
          TextSpan(text: [d.titulo, ?widget.t.clienteNombre].join(' · ')),
          if (aRevision && quien != null) ...[const TextSpan(text: ' · lo revisa '), TextSpan(text: quien, style: TextStyle(color: c.texto, fontWeight: FontWeight.w500))],
        ]),
        style: RkType.body.copyWith(color: c.texto2),
      ),
      const SizedBox(height: 16),
      SegmentedButton<bool>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(shape: const RoundedRectangleBorder(), minimumSize: const Size(0, 48)),
        segments: const [
          ButtonSegment(value: false, label: Text('Enlace'), icon: Icon(Symbols.link_sharp)),
          ButtonSegment(value: true, label: Text('Archivo'), icon: Icon(Symbols.attach_file_sharp)),
        ],
        selected: {_conArchivo},
        onSelectionChanged: (s) => setState(() {
          _conArchivo = s.first;
          _error = null;
        }),
      ),
      const SizedBox(height: 16),
      if (!_conArchivo) ...[
        rotulo('Pega el enlace'),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Drive, Docs, Frame.io, Vimeo, Figma…'),
        ),
      ] else ...[
        if (_archivo == null)
          Row(children: [
            for (final (clave, texto, icono) in [
              ('camara', 'Cámara', Symbols.photo_camera_sharp),
              ('galeria', 'Galería', Symbols.photo_library_sharp),
              ('archivos', 'Archivos', Symbols.folder_sharp),
            ]) ...[
              if (clave != 'camara') const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 72), padding: EdgeInsets.zero),
                  onPressed: _enviando ? null : () => _elegir(clave),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icono), const SizedBox(height: 4), Text(texto.toUpperCase(), style: RkType.mono11)]),
                ),
              ),
            ],
          ])
        else
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(border: Border.all(color: c.linea2)),
            child: Row(children: [
              Icon(Symbols.description_sharp, color: c.texto2),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_nombre ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: RkType.bodyMedio.copyWith(color: c.texto)),
                  Text('${pesoLegible(_peso)} · ${_peso > maxEntrega ? 'muy pesado' : 'listo para subir'}', style: RkType.small.copyWith(color: c.texto2)),
                ]),
              ),
              IconButton(
                tooltip: 'Quitar archivo',
                onPressed: _enviando ? null : () => setState(() {
                  _archivo = null;
                  _error = null;
                }),
                icon: const Icon(Symbols.close_sharp),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        Text('Hasta 50 MB. Si pesa más, súbelo a Drive y pega el enlace.', style: RkType.small.copyWith(color: c.texto2)),
      ],
      const SizedBox(height: 16),
      rotulo(aRevision && quien != null ? 'Nota para $quien' : 'Nota para el equipo'),
      TextField(controller: _nota, maxLines: 3, maxLength: 1000, decoration: const InputDecoration(hintText: 'Qué cambió, qué falta…')),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Row(children: [Container(width: 6, height: 6, color: RkColors.rosa), const SizedBox(width: 8), Expanded(child: Text(_error!, style: RkType.small.copyWith(color: c.texto)))]),
      ],
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _enviando ? null : _enviar,
        child: Text(_enviando
            ? (_conArchivo ? 'SUBIENDO…' : 'ENTREGANDO…')
            : aRevision
                ? 'ENVIAR A REVISIÓN DE ${(quien ?? 'quien revisa').toUpperCase()}'
                : 'ENTREGAR'),
      ),
    ]);
  }
}

/// "2,4 MB" / "830 KB".
String pesoLegible(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  return '${(bytes / 1024).ceil()} KB';
}
