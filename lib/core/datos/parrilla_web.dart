// GENERADO por tool/generar_parrilla.mjs desde app/content.js de la web. No editar a mano.

/// Redes: (clave, nombre). NETWORKS de la web (en el mismo orden).
const redesWeb = <(String, String)>[
  ('IG', 'Instagram'),
  ('FB', 'Facebook'),
  ('TT', 'TikTok'),
  ('YT', 'YouTube'),
  ('IN', 'LinkedIn'),
  ('X', 'X'),
  ('PI', 'Pinterest'),
  ('TH', 'Threads'),
];

/// Formatos de pieza: (clave, nombre). FORMATS de la web.
const formatosWeb = <(String, String)>[
  ('reel', 'Reel'),
  ('carrusel', 'Carrusel'),
  ('historias', 'Historias'),
  ('anuncio', 'Anuncio'),
  ('video_largo', 'Video largo'),
  ('post', 'Post'),
];

/// Estados de pieza: (clave, nombre, ¿el cliente la ve?). POST_STATUS de la web.
const estadosPiezaWeb = <(String, String, bool)>[
  ('borrador', 'Borrador', false),
  ('lista', 'Lista · sin enviar', false),
  ('por_aprobar', 'Por aprobar', true),
  ('cambios', 'Cambios pedidos', true),
  ('aprobada', 'Aprobada', true),
  ('programada', 'Programada', true),
  ('publicada', 'Publicada', true),
];
