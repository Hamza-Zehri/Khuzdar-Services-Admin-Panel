import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/admin_firestore_service.dart';

class StatsProvider extends ChangeNotifier {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  StreamSubscription<Map<String, int>>? _statsSub;

  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalProviders': 0,
    'pendingApprovals': 0,
    'activeChats': 0,
  };

  Map<String, int> get stats => _stats;

  bool _enabled = false;
  bool get enabled => _enabled;

  // Called from main.dart's ProxyProvider whenever auth state changes.
  // Stats are only streamed once the admin is fully signed in (claim synced),
  // which prevents unauthenticated Firestore queries (403 errors).
  void updateAuth(bool authenticated) {
    if (authenticated == _enabled) return;
    _enabled = authenticated;
    if (authenticated) {
      _startStreaming();
    } else {
      _stopStreaming();
      _stats = {
        'totalUsers': 0,
        'totalProviders': 0,
        'pendingApprovals': 0,
        'activeChats': 0,
      };
      notifyListeners();
    }
  }

  void _startStreaming() {
    _stopStreaming();
    _statsSub = _firestoreService.streamDashboardStats().listen((newStats) {
      _stats = newStats;
      notifyListeners();
    });
  }

  void _stopStreaming() {
    _statsSub?.cancel();
    _statsSub = null;
  }

  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }
}