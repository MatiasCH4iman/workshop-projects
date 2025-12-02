import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loginhome1/entities/bandas.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_provider.dart';

final bandasProvider = StateNotifierProvider<BandasNotifier, List<Banda>>(
  (ref) => BandasNotifier(ref),
);

class BandasNotifier extends StateNotifier<List<Banda>> {
  final Ref _ref;
  final CollectionReference<Banda> _bandasRef =
      FirebaseFirestore.instance
          .collection('bandas')
          .withConverter<Banda>(
            fromFirestore: (snapshot, options) {
              final banda = Banda.fromFirestore(snapshot, options);
              return banda.copyWith(id: snapshot.id);
            },
            toFirestore: (banda, _) => banda.toFirestore(),
          );

  StreamSubscription<QuerySnapshot<Banda>>? _subscription;
  bool _isDisposed = false;

  BandasNotifier(this._ref) : super([]) {
    // rearmar listener cuando cambia auth
    _ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      next.whenData((u) => _onAuthChanged(u));
    });

    // iniciar según sesión actual
    _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  void _onAuthChanged(User? user) {
    _subscription?.cancel();
    state = [];

    if (user == null) {
      // sin usuario: dejamos lista vacía
      return;
    }

    _initializeListener();
  }

  void _initializeListener() {
    if (_isDisposed) return;

    try {
      _subscription = _bandasRef.snapshots().listen(
        (snapshot) {
          if (_isDisposed) return;

          state = snapshot.docs.map((doc) {
            final banda = doc.data();
            return banda.copyWith(id: doc.id);
          }).toList();
        },
        onError: (e) {
          if (!_isDisposed) {
            // en producción usar logger
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      // logger
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }

  /// Agregar banda a Firestore
  Future<void> addBanda(Banda banda) async {
    if (_isDisposed) return;
    await _bandasRef.add(banda);
  }

  /// Eliminar banda de Firestore
  Future<void> removeBanda(String id) async {
    if (_isDisposed) return;
    await _bandasRef.doc(id).delete();
  }

  /// Actualizar banda en Firestore
  Future<void> updateBanda(Banda banda) async {
    if (_isDisposed) return;
    if (banda.id == null) return;
    await _bandasRef.doc(banda.id).set(banda);
  }

  /// Banda favorita por usuario
  Future<void> toggleFavorite(String bandaId) async {
    if (_isDisposed || bandaId.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final uid = currentUser.uid;

    final bandaDoc = await _bandasRef.doc(bandaId).get();
    final banda = bandaDoc.data();
    if (banda == null) return;

    final favoritedBy = List<String>.from(banda.favoritedBy);
    if (favoritedBy.contains(uid)) {
      favoritedBy.remove(uid);
    } else {
      favoritedBy.add(uid);
    }

    final updatedBanda = banda.copyWith(favoritedBy: favoritedBy);
    await _bandasRef.doc(bandaId).set(updatedBanda);
  }

  Future<void> subirTodasBandas(List<Banda> bandasLocales) async {
    if (_isDisposed) return;
    final snapshot = await _bandasRef.get();
    if (snapshot.docs.isEmpty) {
      for (final banda in bandasLocales) {
        await _bandasRef.add(banda);
      }
    }
  }
}