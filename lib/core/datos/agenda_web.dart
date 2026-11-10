// GENERADO por tool/generar_agenda.mjs desde app/content.js de la web. No editar a mano.

/// Tipos de reunión: (clave, nombre). MEET_KIND de la web (en el mismo orden).
const tiposReunionWeb = <(String, String)>[
  ('arranque', 'Arranque'),
  ('revision', 'Revisión'),
  ('dudas', 'Dudas'),
  ('entrega', 'Entrega'),
  ('reporte', 'Reporte del mes'),
];

/// Estados de reunión: (clave, nombre). MEET_STATUS de la web.
const estadosReunionWeb = <(String, String)>[
  ('solicitada', 'Solicitada'),
  ('confirmada', 'Confirmada'),
  ('realizada', 'Realizada'),
  ('cancelada', 'Cancelada'),
];

/// Estados de grabación: (clave, nombre). SHOOT_STATUS de la web.
const estadosGrabacionWeb = <(String, String)>[
  ('programada', 'Programada'),
  ('realizada', 'Realizada'),
  ('cancelada', 'Cancelada'),
];
