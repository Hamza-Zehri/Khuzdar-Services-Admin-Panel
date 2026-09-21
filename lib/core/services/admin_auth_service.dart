import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
          // Sync the `admin` custom claim (authorizes admin Firestore queries)
          // and refresh the ID token so the claim is included immediately.
          try {
            await FirebaseFunctions.instance
                .httpsCallable('ensureAdminClaim')
                .call()
                .timeout(const Duration(seconds: 20));
            await credential.user!
                .getIdTokenResult(true)
                .timeout(const Duration(seconds: 20));
          } on TimeoutException {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'functions-unavailable',
              message: 'Admin verification timed out. Check your internet connection and try again.',
            );
          } catch (e) {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'functions-unavailable',
              message: _friendlyFunctionsMessage(e),
            );
          }
          return credential;
        } else {
          // Not an admin
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'access-denied',
            message: 'Access denied: your account is not registered as an admin.',
          );
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Preserve our own user-friendly codes; map the rest to clear messages.
      if (e.code == 'access-denied' || e.code == 'functions-unavailable') {
        rethrow;
      }
      throw FirebaseAuthException(
        code: e.code,
        message: _friendlyAuthMessage(e),
      );
    } catch (e) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Login failed. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address. Please check it and try again.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  String _friendlyFunctionsMessage(Object e) {
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'unauthenticated':
          return 'Session expired. Please sign in again.';
        case 'permission-denied':
          return 'Access denied: your account is not registered as an admin.';
        case 'unavailable':
          return 'Admin service is temporarily unavailable. Please try again.';
        case 'deadline-exceeded':
          return 'Request timed out. Please try again.';
        default:
          return e.message ?? 'Could not verify admin access. Please try again.';
      }
    }
    return 'Could not sync admin access. Please try again in a moment.';
  }
}