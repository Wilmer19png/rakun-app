import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/permisos/permisos.dart';
import '../../../core/supabase/sesion.dart';
import '../../../design_system/componentes.dart';

/// Datos de cada sección: índice, título, prioridad aprobada y quién la puede ver.
class InfoSeccion {
  const InfoSeccion(this.indice, this.titulo, this.prioridad, this.puedeVer);
  final String indice;
  final String titulo;
  final String prioridad;
  final bool Function(Perfil? p) puedeVer;
}

/// Secciones que ya funcionan en la app (Fase 6); las demás muestran "Llega con P1/P2".
const seccionesListas = {'solicitudes', 'clientes', 'proyectos'};

final infoSecciones = <String, InfoSeccion>{
  'solicitudes': InfoSeccion('01', 'Solicitudes', 'P1', (p) => puede(p, 'solicitudes')),
  'clientes': InfoSeccion('02', 'Clientes', 'P1', (p) => puede(p, 'clientes')),
  'proyectos': InfoSeccion('03', 'Proyectos', 'P1', (p) => puede(p, 'proyectos')),
  'cotizaciones': InfoSeccion('03', 'Cotizaciones', 'P2', (p) => puede(p, 'proyectos') && veDinero(p)),
  'parrillas': InfoSeccion('04', 'Parrillas', 'P1', (p) => puede(p, 'parrillas')),
  'agenda': InfoSeccion('05·06', 'Agenda', 'P1', (p) => puede(p, 'grabaciones') || puede(p, 'reuniones')),
  'documentos': InfoSeccion('07', 'Documentos', 'P2', (p) => puede(p, 'documentos')),
  'trabajo': InfoSeccion('08', 'Nuestro trabajo', 'P3', (p) => puede(p, 'trabajo')),
  'planes': InfoSeccion('09', 'Planes y precios', 'P3', (p) => puede(p, 'planes')),
  'mensajes': InfoSeccion('10', 'Mensajes', 'P1', (p) => puede(p, 'equipo')),
  'equipo': InfoSeccion('10', 'Equipo', 'P2', (p) => puede(p, 'equipo')),
  'metricas': InfoSeccion('11', 'Métricas', 'P2', (p) => puede(p, 'metricas')),
  'tarifario': InfoSeccion('12', 'Tarifario', 'P2', (p) => puede(p, 'tarifario')),
};

/// Una sección que se monta en la Fase 6. Respeta los permisos: si no le toca, lo dice.
class SeccionPendientePage extends ConsumerWidget {
  const SeccionPendientePage({super.key, required this.seccion, this.desdeMas = false});
  final String seccion;
  final bool desdeMas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider).value;
    final info = infoSecciones[seccion];
    final permitido = info != null && info.puedeVer(perfil);
    return CustomScrollView(slivers: [
      RkBarraGrande(titulo: info?.titulo ?? 'Sección', indice: info?.indice, atras: desdeMas),
      SliverToBoxAdapter(
        child: permitido
            ? RkVacio(
                antes: 'Muy',
                rosa: 'pronto.',
                texto: '${info.titulo} se conecta a los datos reales en la Fase 6 (prioridad ${info.prioridad}). Mientras tanto sigue en el gestor web.',
              )
            : RkSinPermiso(onIrAHoy: () => context.go('/hoy')),
      ),
    ]);
  }
}
