import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loginhome1/entities/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final userProvider = StateNotifierProvider<UserNotifier, List<UserLogin>>(
  (ref) => UserNotifier(ref),
);

class UserNotifier extends StateNotifier<List<UserLogin>> {
  final Ref _ref;
  final CollectionReference<UserLogin> _usersRef =
      FirebaseFirestore.instance
          .collection('users')
          .withConverter<UserLogin>(
            fromFirestore: (snapshot, options) {
              final user = UserLogin.fromMap(snapshot.data()!);
              return user.copyWith(uid: snapshot.id);
            },
            toFirestore: (user, _) => user.toMap(),
          );

  StreamSubscription<QuerySnapshot<UserLogin>>? _subscription;
  bool _isDisposed = false;

  UserNotifier(this._ref) : super([]) {
    // Auth changes listener
    _ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      next.whenData((user) {
        _onAuthChanged(user);
      });
    });

    // Iniciar si hay sesion actual
    final currentUser = FirebaseAuth.instance.currentUser;
    _onAuthChanged(currentUser);
  }

  void _onAuthChanged(User? user) {
    // cancelar listener previo
    _subscription?.cancel();
    state = [];

    if (user == null) {
      // Sin usuario se limpia el user
      return;
    }

    // iniciar listener que solo vigila la colección users (puede quedarse)
    _initializeListener();
  }

  void _initializeListener() {
    if (_isDisposed) return;

    try {
      _subscription = _usersRef.snapshots().listen(
        (snapshot) {
          if (_isDisposed) return;

          state = snapshot.docs.map((doc) {
            final user = doc.data();
            return user.copyWith(uid: doc.id);
          }).toList();
        },
        onError: (e) {
          if (!_isDisposed) {
            // manejar error
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      // manejar error
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }

  /// Agregar usuario a Firestore
  Future<void> addUser(UserLogin user) async {
    if (_isDisposed || user.uid == null) return;
    try {
      await _usersRef.doc(user.uid!).set(user);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar usuario en Firestore
  Future<void> updateUser(UserLogin user) async {
    if (_isDisposed) return;
    try {
      if (user.uid != null) {
        await _usersRef.doc(user.uid!).set(user);
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Provider usuario actual
final currentUserNameProvider = StateProvider<String>((ref) => 'Invitado');
