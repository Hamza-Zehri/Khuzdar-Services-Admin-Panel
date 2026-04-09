import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInAdmin(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Verify admin role
        final doc = await _firestore
            .collection(FirestorePaths.users)
            .doc(credential.user!.uid)
            .get();

        if (doc.exists && doc.data()?['role'] == 'admin') {
          return credential;
        } else {
          // Not an admin
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'access-denied',
            message: 'Access Denied: You do not have admin privileges.',
          );
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
