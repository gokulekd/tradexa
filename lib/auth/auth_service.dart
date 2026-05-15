import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _pinKeyPrefix = 'pin_hash_';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _syncUserDocument(credential.user);
    return credential;
  }

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    _syncUserDocument(credential.user);
    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> userHasPin() async {
    final user = currentUser;
    if (user == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString('$_pinKeyPrefix${user.uid}');
    return hash != null && hash.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final user = currentUser;
    if (user == null) throw StateError('No signed-in user available.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_pinKeyPrefix${user.uid}', _hashPin(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final user = currentUser;
    if (user == null) throw StateError('No signed-in user available.');
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_pinKeyPrefix${user.uid}');
    if (saved == null || saved.isEmpty) return false;
    return saved == _hashPin(pin);
  }

  Future<void> clearPin() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pinKeyPrefix${user.uid}');
  }

  // Best-effort: syncs basic user metadata to Firestore. Failures are ignored
  // so they never block the auth flow.
  void _syncUserDocument(User? user) {
    if (user == null) return;
    _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {});
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
