// GENERADO por tool/generar_proyectos.mjs desde app/content.js y app/quote-sources.js de la web. No editar a mano.

/// Etapas de cada tipo de proyecto (el cliente las ve en su portal). STAGES de la web.
const etapasWeb = <String, List<String>>{
  'marca': ['Estrategia', 'Guiones', 'Grabación', 'Edición', 'Revisión', 'Publicación'],
  'produccion': ['Preproducción', 'Rodaje', 'Postproducción'],
  'web': ['Brief', 'Wireframe', 'Diseño', 'Desarrollo', 'Pruebas', 'Lanzamiento'],
};

/// Plantilla de entregables por mundo: (título, tipo, días desde hoy). TEMPLATES de la web.
const plantillasWeb = <String, List<(String, String, int)>>{
  'marca': [
    ('Estrategia y parrilla del mes', 'estrategia', 5),
    ('Guiones del mes', 'guion', 9),
    ('Carruseles del mes', 'diseno', 12),
    ('Sesión de grabación', 'grabacion', 13),
    ('Ediciones del mes', 'edicion', 22),
    ('Publicación y reporte del mes', 'otro', 30),
  ],
  'web': [
    ('Estructura y textos', 'estrategia', 6),
    ('Wireframe', 'diseno', 10),
    ('Diseño de la página', 'diseno', 16),
    ('Desarrollo', 'desarrollo', 28),
    ('Pruebas y lanzamiento', 'desarrollo', 35),
  ],
  'produccion': [
    ('Guion', 'guion', 5),
    ('Preproducción (plan de rodaje)', 'estrategia', 12),
    ('Rodaje', 'grabacion', 20),
    ('Montaje', 'edicion', 30),
    ('Color y sonido', 'edicion', 36),
    ('Entrega final', 'otro', 40),
  ],
};

/// Tipos de entregable. KINDS de la web (en el mismo orden).
const tiposWeb = <String, String>{
  'estrategia': 'Estrategia',
  'guion': 'Guion',
  'grabacion': 'Grabación',
  'edicion': 'Edición',
  'diseno': 'Diseño',
  'desarrollo': 'Desarrollo',
  'revision': 'Revisión',
  'otro': 'Otro',
};

/// Estados de un entregable: (clave, nombre). DSTATUS de la web (en el mismo orden).
const estadosEntregableWeb = <(String, String)>[
  ('por_hacer', 'Por hacer'),
  ('en_curso', 'En curso'),
  ('en_revision', 'En revisión'),
  ('aprobado', 'Aprobado'),
];
