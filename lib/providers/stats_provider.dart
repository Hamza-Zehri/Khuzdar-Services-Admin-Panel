import 'package:flutter/material.dart';
import '../core/services/admin_firestore_service.dart';

class StatsProvider extends ChangeNotifier {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  Map<String, int> _stats = {
    'totalUsers': 0,
    'totalProviders': 0,
    'pendingApprovals': 0,
    'activeChats': 0,
  };
  
  Map<String, int> get stats => _stats;

  StatsProvider() {
    _init();
  }

  void _init() {
    _firestoreService.streamDashboardStats().listen((newStats) {
      _stats = newStats;
      notifyListeners();
    });
  }
}
