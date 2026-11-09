/// Fechas cortas en español de Colombia, sin paquetes extra ("dom 9 nov", "9:41 a. m.").
const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];

String diaCorto(DateTime d) => '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]}';

String horaCorta(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'a. m.' : 'p. m.'}';
}
