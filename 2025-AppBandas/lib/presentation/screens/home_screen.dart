import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loginhome1/presentation/providers/auth_service.dart';
import 'package:loginhome1/entities/user.dart';
import 'package:loginhome1/presentation/providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const String name = 'home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool showProfile = false;
  bool editing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Obtenemos el usuario actual desde Firestore si existe
    final userList = ref.watch(userProvider);
    final currentUser =
        userList.firstWhere((u) => u.uid == user?.uid, orElse: () {
      return UserLogin(
        user?.displayName ?? user?.email?.split('@').first ?? 'Invitado',
        '',
        uid: user?.uid,
      );
    });

    // Usa el nombre de currentUser (desde Firestore) en lugar de displayName
    final userName = currentUser.userName;
    final photoUrl = user?.photoURL;

    // Actualizamos los controladores al entrar en perfil
    if (showProfile && !editing) {
      _nameController.text = currentUser.userName;
      _detailsController.text = currentUser.details;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton<String>(
              child: CircleAvatar(
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.person) : null,
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'profile',
                  child: const Text('Perfil'),
                  onTap: () => setState(() => showProfile = true),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: const Text('Cerrar sesión'),
                  onTap: () async {
                    try {
                      await AuthService().signOut();
                      if (mounted) {
                        // Pequeño delay
                        await Future.delayed(const Duration(milliseconds: 500));
                        GoRouter.of(context).go('/login');
                      }
                    } catch (e) {
                      print('Error logging out: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al cerrar sesión'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: showProfile
              ? _buildProfileView(currentUser, user)
              : _buildMainView(userName, context),
        ),
      ),
    );
  }

  Widget _buildMainView(String userName, BuildContext context) {
    return Column(
      key: const ValueKey('main'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Bienvenido $userName',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            GoRouter.of(context).go('/bandas');
          },
          child: const Text(
            'Ver Bandas',
            style: TextStyle(fontSize: 30, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView(UserLogin currentUser, User? authUser) {
    return SingleChildScrollView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                authUser?.photoURL != null ? NetworkImage(authUser!.photoURL!) : null,
            child: authUser?.photoURL == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre de usuario'),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _detailsController,
            decoration: const InputDecoration(labelText: 'Detalles'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = UserLogin(
                _nameController.text,
                _detailsController.text,
                uid: currentUser.uid,
              );
              await ref.read(userProvider.notifier).updateUser(updatedUser);
              setState(() {
                showProfile = false;
              });
            },
            child: const Text('Guardar cambios'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => showProfile = false),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
