import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginhome1/presentation/providers/auth_service.dart';
import 'package:loginhome1/presentation/providers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String name = 'login';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  bool _isLogin = true; // alterna entre login y registro
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _auth = AuthService();

  // --- Google Sign-In ---
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();

      final user = FirebaseAuth.instance.currentUser;
      final userName =
          user?.displayName ?? user?.email?.split('@').first ?? 'Usuario';
      ref.read(currentUserNameProvider.notifier).state = userName;

      if (!mounted) return;
      GoRouter.of(context).go('/home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Google Sign-In: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Google Sign-In: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- Email/Password Sign-In o Register ---
  Future<void> _signInOrRegisterEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      UserCredential cred;
      if (_isLogin) {
        cred = await _auth.signInWithEmail(email, password);
      } else {
        cred = await _auth.registerWithEmail(email, password);
      }

      final user = cred.user;
      if (user != null) {
        final userName = user.email?.split('@').first ?? 'Usuario';
        final direction = _isLogin ? 'login' : 'register';
        ref.read(currentUserNameProvider.notifier).state = userName;

        if (!mounted) return;
        GoRouter.of(context).go('/home', extra: {
          'username': userName,
          'direction': direction,
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con ese correo.';
          break;
        case 'wrong-password':
          errorMessage = 'La contraseña es incorrecta.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con ese correo.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo electrónico no es válido.';
          break;
        case 'weak-password':
          errorMessage = 'La contraseña es demasiado débil.';
          break;
        default:
          errorMessage = 'Error: ${e.message ?? e.code}';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Avatar circular ---
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // --- Campos de email y contraseña ---
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // --- Botón de login / registro ---
              SizedBox(
                width: buttonWidth > 500 ? 500 : buttonWidth,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInOrRegisterEmail,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isLogin
                              ? 'Iniciar sesión con Email'
                              : 'Registrarse con Email',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? '¿No tienes cuenta? Crear una nueva'
                      : '¿Ya tienes cuenta? Iniciar sesión',
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // --- Botón de Google Sign-In ---
              SizedBox(
                width: buttonWidth > 500 ? 500 : buttonWidth,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _loading ? null : _signInWithGoogle,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata,
                                size: 28, color: Color(0xFF4285F4)),
                            SizedBox(width: 20),
                            Text('Continuar con Google'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
