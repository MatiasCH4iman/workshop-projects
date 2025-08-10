import 'package:flutter/material.dart';
import 'package:neoposture/core/router/app_router.dart';
import 'package:neoposture/entities/notification.dart';
void main() {
  runApp(const MainApp());
  requestNotificationPermission().then((granted) {
    if (granted) {
      debugPrint('Notification permission granted');
    } else {
      debugPrint('Notification permission denied');
    }
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,  
    );
  }
}
