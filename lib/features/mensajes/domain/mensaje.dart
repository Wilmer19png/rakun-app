/// Mensajes del equipo (viewMessages de admin-equipo.js · fase10.sql).
library;

/// Una fila de `team_messages` con `projects(name)`.
class Mensaje {
  const Mensaje({
    required this.id,
    required this.autor,
    required this.texto,
    required this.creado,
    this.para = 'todos',
    this.persona,
    this.proyectoId,
    this.proyecto,
    this.fijado = false,
  });

  factory Mensaje.desdeFila(Map<String, dynamic> f) => Mensaje(
        id: f['id'] as String,
        autor: f['author_id'] as String,
        texto: (f['body'] as String?) ?? '',
        creado: DateTime.parse(f['created_at'] as String).toLocal(),
        para: (f['to_kind'] as String?) ?? 'todos',
        persona: f['to_user'] as String?,
        proyectoId: f['project_id'] as String?,
        proyecto: (f['projects'] as Map?)?['name'] as String?,
        fijado: (f['pinned'] as bool?) ?? false,
      );

  final String id, autor, texto, para;
  final String? persona, proyectoId, proyecto;
  final DateTime creado;
  final bool fijado;

  /// "todo el equipo", "para Sofía", "equipo de Videoclip" (target() de la web).
  String destino(String? Function(String id) nombre) => switch (para) {
        'persona' => 'para ${nombre(persona ?? '') ?? 'alguien'}',
        'proyecto' => 'equipo de ${proyecto ?? 'un proyecto'}',
        _ => 'todo el equipo',
      };
}

/// Cómo ve una persona un mensaje.
({bool mio, bool nuevo, bool puedeGestionar, int vistos, bool vistoPorDestino}) estadoMensaje(
  Mensaje m, {
  required String yo,
  required bool admin,
  required List<String> leidoPor,
}) =>
    (
      mio: m.autor == yo,
      nuevo: m.autor != yo && !leidoPor.contains(yo),
      puedeGestionar: m.autor == yo || admin,
      vistos: leidoPor.length,
      vistoPorDestino: leidoPor.isNotEmpty,
    );

/// Filtros de la pantalla.
enum FiltroMensajes { todos, paraMi, fijados }

bool pasaFiltro(Mensaje m, FiltroMensajes f, {required String yo}) => switch (f) {
      FiltroMensajes.todos => true,
      // a mí directamente o al equipo de un proyecto donde estoy (la base ya solo deja ver esos)
      FiltroMensajes.paraMi => m.autor != yo && (m.para == 'persona' || m.para == 'proyecto'),
      FiltroMensajes.fijados => m.fijado,
    };

/// Orden de la web: fijados arriba, luego lo más reciente.
List<Mensaje> ordenar(List<Mensaje> ms) => [...ms]
  ..sort((a, b) {
    if (a.fijado != b.fijado) return a.fijado ? -1 : 1;
    return b.creado.compareTo(a.creado);
  });

/// Fila para insertar (validada como la web: texto 1–2000).
Map<String, Object?>? filaNueva({required String yo, required String para, String? persona, String? proyecto, required String texto, bool fijar = false}) {
  final t = texto.trim();
  if (t.isEmpty || t.length > 2000) return null;
  if (para == 'persona' && persona == null) return null;
  if (para == 'proyecto' && proyecto == null) return null;
  return {
    'author_id': yo,
    'to_kind': para,
    'body': t,
    'pinned': fijar,
    'to_user': para == 'persona' ? persona : null,
    'project_id': para == 'proyecto' ? proyecto : null,
  };
}
