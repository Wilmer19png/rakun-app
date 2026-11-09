import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'design_system/apariencia.dart';

/// Arranque. Compilar SIEMPRE con:  flutter run --dart-define-from-file=env.json
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final faltan = Env.faltantes();
  if (faltan.isNotEmpty || !Env.llaveSegura) {
    runApp(_ConfigFaltante(Env.llaveSegura ? 'Falta en env.json: ${faltan.join(', ')}' : 'La llave de env.json es secreta: usa la publicable.'));
    return;
  }

  await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseKey);
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: const RakunApp(),
  ));
}

/// Se ve solo si la app se compiló sin env.json (error de quien la compila, no del usuario).
class _ConfigFaltante extends StatelessWidget {
  const _ConfigFaltante(this.mensaje);
  final String mensaje;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF010221),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$mensaje\nCompila con --dart-define-from-file=env.json', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      );
}
