import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_router.dart'; // o el archivo donde tengas tus rutas
import 'services/posture_persistence_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }
  runApp(const ProviderScope(child: NeoPostureApp()));
}

class NeoPostureApp extends ConsumerWidget {
  const NeoPostureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar el servicio de persistencia
    ref.watch(posturePersistenceProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NeoPosture',
      routerConfig: appRouter,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    );
  }
}
