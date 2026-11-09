import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/errores/errores.dart';
import '../../../core/supabase/sesion.dart';
import '../../../core/utils/abrir.dart';
import '../../../design_system/componentes.dart';
import '../../../design_system/tipografia.dart';
import '../../../design_system/tokens.dart';
import '../data/clientes_repo.dart';

/// Datos mínimos de a quién se le crea el acceso.
class PersonaAcceso {
  const PersonaAcceso({required this.nombre, required this.correo, this.telefono, this.clienteId, this.rol = 'cliente'});
  final String nombre, correo;
  final String? telefono, clienteId;
  final String rol; // cliente | equipo (equipo: solo admin; lo vuelve a revisar la función)
}

/// `openInvite` de admin.js: llama a la Edge Function `invitar` (la misma de la web) y el enlace
/// pasa por cuenta.html (así las vistas previas de WhatsApp no gastan el enlace de un solo uso).
Future<void> mostrarAcceso(BuildContext context, PersonaAcceso p) => mostrarHoja<void>(
      context,
      titulo: p.rol == 'cliente' ? 'Acceso al portal' : 'Acceso al gestor',
      cuerpo: _Acceso(p),
    );

class _Acceso extends ConsumerStatefulWidget {
  const _Acceso(this.p);
  final PersonaAcceso p;

  @override
  ConsumerState<_Acceso> createState() => _AccesoState();
}

class _AccesoState extends ConsumerState<_Acceso> {
  bool _porCorreo = false, _enviando = false, _existia = false, _correoEnviado = false;
  String? _error, _enlace;

  Future<void> _crear() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final r = await ref.read(supabaseProvider).functions.invoke('invitar', body: {
        'email': widget.p.correo,
        'full_name': widget.p.nombre,
        'role': widget.p.rol,
        'client_id': widget.p.rol == 'cliente' ? widget.p.clienteId : null,
        'mode': _porCorreo ? 'email' : 'link',
        'redirect_to': Env.cuentaUrl,
      });
      final data = (r.data as Map?) ?? const {};
      if (data['ok'] != true) throw Exception(data['error'] ?? 'No se pudo crear el acceso.');
      if (widget.p.rol == 'cliente') ref.invalidate(clientesProvider); // la lista pasa a «Con acceso»
      setState(() {
        _existia = data['existed'] == true;
        final link = data['link'] as String?;
        if (link == null) {
          _correoEnviado = true;
        } else {
          _enlace = '${Env.cuentaUrl}?activar=${Uri.encodeComponent(link)}';
        }
      });
    } on FunctionException catch (e) {
      final d = e.details;
      setState(() => _error = d is Map && d['error'] != null ? '${d['error']}' : textoDeError(e.reasonPhrase ?? e));
    } catch (e) {
      setState(() => _error = textoDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String get _mensaje {
    final primero = widget.p.nombre.trim().split(RegExp(r'\s+')).first;
    final que = widget.p.rol == 'cliente' ? 'portal de clientes' : 'gestor';
    return 'Hola $primero, este es tu acceso al $que de RAKÜN. Entra aquí para crear tu contraseña: $_enlace';
  }

  @override
  Widget build(BuildContext context) {
    final c = RkColors.of(context);
    final p = widget.p;
    if (_correoEnviado) {
      return Text('✓ Le enviamos el correo de invitación a ${p.correo}.', style: RkType.body.copyWith(color: c.texto));
    }
    if (_enlace != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('✓ Acceso creado${_existia ? ' (ya tenía cuenta: este enlace le permite crear una contraseña nueva)' : ''}.', style: RkType.body.copyWith(color: c.texto)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: RkColors.rosa)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('UN SOLO USO · MÁNDALO PRONTO, CADUCA', style: RkType.mono11.copyWith(color: c.rosaTexto)),
            const SizedBox(height: 6),
            Text(_enlace!, maxLines: 2, overflow: TextOverflow.ellipsis, style: RkType.mono12.copyWith(color: c.texto)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          if ((p.telefono ?? '').isNotEmpty) ...[
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: c.ok, foregroundColor: c.okSobre),
                onPressed: () => Abrir.whatsapp(p.telefono!, texto: _mensaje),
                icon: const Icon(Symbols.chat_sharp, size: 20),
                label: const Text('WHATSAPP'),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _enlace!));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
              },
              icon: const Icon(Symbols.content_copy_sharp, size: 20),
              label: const Text('COPIAR'),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => Abrir.correo(p.correo, asunto: 'Tu acceso a RAKÜN', cuerpo: _mensaje),
          icon: const Icon(Symbols.mail_sharp, size: 20),
          label: const Text('ENVIAR POR CORREO'),
        ),
        TextButton.icon(
          onPressed: () => SharePlus.instance.share(ShareParams(text: _mensaje, subject: 'Tu acceso a RAKÜN')),
          icon: const Icon(Symbols.share_sharp, size: 20),
          label: const Text('OTRA APP…'),
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'Se crea la cuenta de '),
          TextSpan(text: p.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
          const TextSpan(text: ' con '),
          TextSpan(text: p.correo, style: const TextStyle(fontWeight: FontWeight.w500)),
          const TextSpan(text: '. Con el enlace crea su propia contraseña y desde ahí entra cuando quiera.'),
        ]),
        style: RkType.body.copyWith(color: c.texto2),
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(border: Border.all(color: c.linea2)),
        child: Row(children: [
          for (final (correo, nombre, icono) in [(false, 'Enlace', Symbols.link_sharp), (true, 'Correo', Symbols.mail_sharp)])
            Expanded(
              child: Material(
                color: _porCorreo == correo ? c.texto : Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _porCorreo = correo),
                  child: SizedBox(
                    height: 48,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(icono, size: 20, color: _porCorreo == correo ? c.fondo : c.texto2),
                      const SizedBox(width: 6),
                      Text(nombre, style: RkType.small.copyWith(fontWeight: FontWeight.w500, color: _porCorreo == correo ? c.fondo : c.texto2)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      Text(_porCorreo ? 'Le llega un correo de invitación (requiere el correo configurado en Supabase).' : 'Lo copias o lo mandas por WhatsApp.', style: RkType.small.copyWith(color: c.texto3)),
      if (_error != null) ...[const SizedBox(height: 12), RkError(titulo: 'No se pudo crear el acceso.', mensaje: _error!)],
      const SizedBox(height: 16),
      FilledButton(onPressed: _enviando ? null : _crear, child: Text(_enviando ? 'CREANDO…' : 'CREAR ACCESO')),
    ]);
  }
}
