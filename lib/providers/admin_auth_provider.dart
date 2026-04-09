import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/admin_auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _authService = AdminAuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  AdminAuthProvider() {
    _init();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _authService.signInAdmin(email, password);
      // Optional: Delay slightly to allow auth state listener to catch up if needed
      if (credential != null) {
        _user = credential.user;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? err) {
    _error = err;
    notifyListeners();
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
