import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loginhome1/entities/user.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  /// -------------------
  /// LOGIN con Google
  /// -------------------
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final cred = await _auth.signInWithPopup(provider);
      await _ensureUserDocument(cred.user!);
      return cred;
    }

    String? idToken;
    String? accessToken;
    dynamic googleUser;

    try {
      googleUser = await (_googleSignIn as dynamic).signIn();
      if (googleUser != null) {
        final googleAuth = await (googleUser as dynamic).authentication;
        idToken = googleAuth.idToken as String?;
        accessToken = googleAuth.accessToken as String?;
      }
    } catch (_) {}

    if (idToken == null && accessToken == null) {
      throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'No se obtuvo idToken ni accessToken de Google Sign-In');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(cred.user!);
    return cred;
  }

  /// -------------------
  /// LOGIN con Email
  /// -------------------
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _ensureUserDocument(cred.user!);
    return cred;
  }

  /// -------------------
  /// REGISTRO con Email
  /// -------------------
  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // crear perfil inicial en Firestore
    await _ensureUserDocument(cred.user!, isNew: true);
    return cred;
  }

  /// -------------------
  /// Cerrar sesión
  /// -------------------
  Future<void> signOut() async {
    try {
      // Desconectar Google
      try {
        await (_googleSignIn as dynamic).disconnect();
      } catch (_) {
        try {
          await (_googleSignIn as dynamic).signOut();
        } catch (_) {}
      }
      
      // Cerrar sesión en Firebase
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// -------------------
  /// Crear usuario en Firestore
  /// -------------------
  Future<void> _ensureUserDocument(User user, {bool isNew = false}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists || isNew) {
      final newUser = UserLogin.fromFirebaseUser(user);
      await docRef.set(newUser.toMap());
    }
  }
}
