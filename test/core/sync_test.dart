import 'package:app/core/sync/cache_lectura.dart';
import 'package:app/core/sync/en_vivo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('caché de lectura', () {
    late CacheLectura cache;
    setUp(() async {
      SharedPreferences.setMockInitialValues({'rk-tema': 'claro'});
      cache = CacheLectura(await SharedPreferences.getInstance());
    });

    test('guarda y lee con la hora', () async {
      await cache.guardar('u1', 'leads', [
        {'id': 'x', 'name': 'Ejemplo'},
      ]);
      final g = cache.leer('u1', 'leads');
      expect(g, isNotNull);
      expect((g!.datos as List).first['name'], 'Ejemplo');
      expect(DateTime.now().difference(g.cuando).inSeconds, lessThan(5));
    });

    test('cada persona tiene su propia caché', () async {
      await cache.guardar('u1', 'leads', [1]);
      expect(cache.leer('u2', 'leads'), isNull);
    });

    test('al salir se borra la caché y no se toca el tema', () async {
      await cache.guardar('u1', 'leads', [1]);
      await cache.borrarTodo();
      expect(cache.leer('u1', 'leads'), isNull);
      expect((await SharedPreferences.getInstance()).getString('rk-tema'), 'claro');
    });
  });

  test('las revisiones suben por tabla', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(revisionesProvider.notifier);
    n.subir(['leads']);
    n.subir(['leads', 'projects']);
    expect(c.read(revisionesProvider), {'leads': 2, 'projects': 1});
  });

  test('las tablas en vivo no incluyen las privadas', () {
    expect(tablasEnVivo, hasLength(17));
    expect(tablasEnVivo, isNot(contains('meta_tokens')));
    expect(tablasEnVivo, isNot(contains('page_events')));
    expect(tablasEnVivo, isNot(contains('app_settings')));
  });
}
