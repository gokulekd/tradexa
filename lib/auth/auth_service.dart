import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
    await _ensureUserDocument(credential.user);
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
    await _ensureUserDocument(credential.user);
    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> userHasPin() async {
    final user = currentUser;
    if (user == null) return false;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    final pinHash = data?['pinHash'];
    return pinHash is String && pinHash.isNotEmpty;
  }

  Future<void> savePin(String pin) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No signed-in user available.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'pinHash': _hashPin(pin),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
