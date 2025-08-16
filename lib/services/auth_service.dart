// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final lowercaseEmail = email.toLowerCase().trim();
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: lowercaseEmail,
        password: password,
      );
      final userId = userCredential.user?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).set({
          ...userData,
          'email': lowercaseEmail,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final lowercaseEmail = email.toLowerCase().trim();
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: lowercaseEmail,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }
  
  // This new method is the most reliable way to fetch user data.
  Future<DocumentSnapshot> getUserDataByUid(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc;
    }
    throw Exception('User data not found in Firestore');
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

}