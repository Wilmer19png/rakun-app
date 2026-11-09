/// Cambios en vivo (Fase 5). Un solo canal de Supabase Realtime escucha las 17 tablas que
/// publicó rakun-web/supabase/fase18.sql.
///
/// Regla del encargo: **no confiar en el contenido del aviso**. De cada evento solo se usa
/// qué tabla cambió; esa tabla sube su "revisión" y los datos se vuelven a pedir con RLS
/// y permisos de dinero de por medio. Los proveedores de datos de la Fase 6 hacen:
///   ref.watch(revisionesProvider.select((r) => r['leads'] ?? 0));
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/sesion.dart';

/// Las tablas publicadas en fase18.sql (sin meta_tokens, page_events ni app_settings).
const tablasEnVivo = [
  'leads', 'clients', 'projects', 'posts', 'shoots', 'meetings', 'documents',
  'quotes', 'quote_payments', 'deliverables', 'team_messages', 'message_reads',
  'followups', 'commissions', 'works', 'plan_catalog', 'profiles',
];

enum EstadoEnVivo { sinSesion, conectando, enVivo, reconectando }

/// Un aviso recibido (solo lo necesario para el diagnóstico; nunca se muestran sus datos).
class AvisoEnVivo {
  const AvisoEnVivo({required this.tabla, required this.tipo, required this.recibido, this.confirmado});
  final String tabla;
  final String tipo; // INSERT · UPDATE · DELETE
  final DateTime recibido;
  final DateTime? confirmado; // commit en la base de datos (reloj del servidor)

  /// Lo que tardó desde que la base de datos guardó el cambio hasta que llegó al teléfono.
  Duration? get demora => confirmado == null ? null : recibido.difference(confirmado!);
}

class EstadoSync {
  const EstadoSync({this.estado = EstadoEnVivo.sinSesion, this.avisos = const [], this.desde, this.cortado = false});
  final EstadoEnVivo estado;
  final List<AvisoEnVivo> avisos; // los últimos 30, el más nuevo primero
  final DateTime? desde; // desde cuándo está en este estado
  final bool cortado; // lleva más de 4 s sin conexión: se muestra la franja

  EstadoSync con({EstadoEnVivo? estado, List<AvisoEnVivo>? avisos, bool? cortado}) => EstadoSync(
        estado: estado ?? this.estado,
        avisos: avisos ?? this.avisos,
        desde: estado != null && estado != this.estado ? DateTime.now() : desde,
        cortado: cortado ?? (estado == EstadoEnVivo.enVivo ? false : this.cortado),
      );
}

/// Revisión por tabla: sube cada vez que esa tabla cambia (o al volver a la app).
class RevisionesNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void subir(Iterable<String> tablas) {
    final m = {...state};
    for (final t in tablas) {
      m[t] = (m[t] ?? 0) + 1;
    }
    state = m;
  }
}

final revisionesProvider = NotifierProvider<RevisionesNotifier, Map<String, int>>(RevisionesNotifier.new);

/// El canal en vivo. Se conecta con sesión y se cierra al salir.
class EnVivoNotifier extends Notifier<EstadoSync> {
  RealtimeChannel? _canal;
  Timer? _rafaga;
  final _pendientes = <String>{};
  AppLifecycleListener? _ciclo;
  int _intento = 0;
  Timer? _reintento;
  Timer? _corte;

  @override
  EstadoSync build() {
    final usuario = ref.watch(sesionProvider.select((s) => s.value?.user.id));
    ref.onDispose(_cerrar);
    if (usuario == null) return const EstadoSync();
    _ciclo = AppLifecycleListener(onResume: alVolver);
    Future.microtask(_abrir);
    return EstadoSync(estado: EstadoEnVivo.conectando, desde: DateTime.now());
  }

  void _abrir() {
    final sb = ref.read(supabaseProvider);
    var canal = sb.channel('rakun-en-vivo');
    for (final t in tablasEnVivo) {
      canal = canal.onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: t, callback: _alAviso);
    }
    _canal = canal.subscribe((estado, error) {
      switch (estado) {
        case RealtimeSubscribeStatus.subscribed:
          final veniaDeCorte = state.estado == EstadoEnVivo.reconectando;
          _intento = 0;
          _corte?.cancel();
          _corte = null;
          state = state.con(estado: EstadoEnVivo.enVivo);
          // si estuvo cortado pudo perder avisos: se vuelve a consultar todo
          if (veniaDeCorte) ref.read(revisionesProvider.notifier).subir(tablasEnVivo);
        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
        case RealtimeSubscribeStatus.closed:
          if (state.estado != EstadoEnVivo.sinSesion) {
            state = state.con(estado: EstadoEnVivo.reconectando);
            _corte ??= Timer(const Duration(seconds: 4), () {
              _corte = null;
              if (state.estado == EstadoEnVivo.reconectando) state = state.con(cortado: true);
            });
            _programarReintento();
          }
      }
    });
  }

  /// Reconexión con espera creciente (1, 2, 4… hasta 30 s).
  void _programarReintento() {
    _reintento?.cancel();
    final espera = Duration(seconds: [1, 2, 4, 8, 16, 30][_intento.clamp(0, 5)]);
    _intento++;
    _reintento = Timer(espera, reconectar);
  }

  void _alAviso(PostgresChangePayload p) {
    final aviso = AvisoEnVivo(tabla: p.table, tipo: p.eventType.name.toUpperCase(), recibido: DateTime.now(), confirmado: p.commitTimestamp);
    state = state.con(avisos: [aviso, ...state.avisos].take(30).toList());
    // se agrupan las ráfagas: varios avisos seguidos = una sola consulta por tabla
    _pendientes.add(p.table);
    _rafaga ??= Timer(const Duration(milliseconds: 250), () {
      ref.read(revisionesProvider.notifier).subir(_pendientes.toList());
      _pendientes.clear();
      _rafaga = null;
    });
  }

  /// Al volver a la app: se reconecta si hace falta y se vuelve a consultar todo.
  void alVolver() {
    ref.read(revisionesProvider.notifier).subir(tablasEnVivo);
    if (state.estado != EstadoEnVivo.enVivo) reconectar();
  }

  Future<void> reconectar() async {
    final c = _canal;
    _canal = null;
    if (c != null) await ref.read(supabaseProvider).removeChannel(c);
    if (ref.read(sesionProvider).value != null) _abrir();
  }

  void _cerrar() {
    _rafaga?.cancel();
    _reintento?.cancel();
    _corte?.cancel();
    _ciclo?.dispose();
    final c = _canal;
    _canal = null;
    if (c != null) ref.read(supabaseProvider).removeChannel(c);
  }
}

final enVivoProvider = NotifierProvider<EnVivoNotifier, EstadoSync>(EnVivoNotifier.new);

/// ¿Mostrar la franja "Sin conexión"? Solo si el corte dura más de 4 s (evita parpadeos).
final sinConexionProvider = Provider<bool>((ref) => ref.watch(enVivoProvider.select((s) => s.cortado)));
