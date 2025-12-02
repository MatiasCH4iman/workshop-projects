import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

class PermissionScreen extends StatefulWidget {
  static const String name = 'permission_screen';

  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  String status = 'Verificando permisos...';
  bool isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      if (kIsWeb) {
        // En Web: no necesita permisos, ir directo a conexión
        setState(() {
          status = '✅ Web Browser - Sin permisos requeridos';
          isChecking = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/connection');
        }
      } else if (Platform.isAndroid) {
        // Android: pedir permisos
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();
        final location = await Permission.location.request();

        if (bluetoothScan.isGranted && bluetoothConnect.isGranted && location.isGranted) {
          setState(() {
            status = '✅ Permisos concedidos';
            isChecking = false;
          });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            context.go('/connection');
          }
        } else {
          setState(() {
            status = '❌ Permisos denegados';
            isChecking = false;
          });
        }
      } else {
        // iOS y otros
        setState(() {
          status = '✅ Plataforma compatible';
          isChecking = false;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/connection');
        }
      }
    } catch (e) {
      setState(() {
        status = 'Error: $e';
        isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isChecking)
              const CircularProgressIndicator()
            else
              Text(
                status,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            if (!isChecking)
              ElevatedButton(
                onPressed: () => context.go('/connection'),
                child: const Text('Continuar'),
              ),
          ],
        ),
      ),
    );
  }
}
