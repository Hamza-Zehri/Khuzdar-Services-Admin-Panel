import 'package:cloud_firestore/cloud_firestore.dart';
// Note: Adapting imports to point directly to models
import '../models/all_models.dart';
import '../constants/firestore_paths.dart';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stats
  Stream<Map<String, int>> streamDashboardStats() {
    // Note: In a real advanced app this should be aggregated via Cloud Functions.
    // We are streaming raw counts since this is a UI admin dashboard demo.
    // For large collections, this approach (count() from client) works well now in Firestore!
    
    return Stream.multi((controller) async {
      void fetchStats() async {
        try {
          final usersCount = await _db.collection(FirestorePaths.users).count().get();
          final providersCount = await _db.collection(FirestorePaths.providers).count().get();
          final pendingCount = await _db.collection(FirestorePaths.providers)
              .where('verificationStatus', isEqualTo: 'pending')
              .count().get();
          final chatsCount = await _db.collection(FirestorePaths.chats)
              .where('status', isEqualTo: 'CHATTING')
              .count().get();
              
          if (!controller.isClosed) {
            controller.add({
              'totalUsers': usersCount.count ?? 0,
              'totalProviders': providersCount.count ?? 0,
              'pendingApprovals': pendingCount.count ?? 0,
              'activeChats': chatsCount.count ?? 0,
            });
          }
        } catch (e) {
          // Ignore
        }
      }
      
      fetchStats();
      // Polling could be added here or just return a future-like stream.
      // Alternatively, listening to snapshots for small collections, but count is cheaper.
      // We will re-fetch every 30 seconds
      final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) => fetchStats());
      controller.onCancel = () => timer.cancel();
    });
  }

  // Providers
  Stream<List<ProviderModel>> streamPendingProviders() {
    return _db.collection(FirestorePaths.providers)
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => ProviderModel.fromFirestore(d)).toList());
  }

  Stream<List<ProviderModel>> streamAllProviders() {
    return _db.collection(FirestorePaths.providers)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ProviderModel.fromFirestore(d)).toList());
  }

  Future<void> approveProvider(String providerId) async {
    await _db.collection(FirestorePaths.providers).doc(providerId).update({
      'verificationStatus': 'approved',
    });
  }

  Future<void> rejectProvider(String providerId, String reason) async {
    await _db.collection(FirestorePaths.providers).doc(providerId).update({
      'verificationStatus': 'rejected',
      'rejectionReason': reason,
    });
  }

  Future<void> blockProvider(String providerId) async {
    // Note: If ProviderModel has no isBlocked, we might need to block the User ID associated
    final doc = await _db.collection(FirestorePaths.providers).doc(providerId).get();
    if (doc.exists) {
      final p = ProviderModel.fromFirestore(doc);
      await blockUser(p.userId);
    }
  }

  Future<void> unblockProvider(String providerId) async {
    final doc = await _db.collection(FirestorePaths.providers).doc(providerId).get();
    if (doc.exists) {
      final p = ProviderModel.fromFirestore(doc);
      await unblockUser(p.userId);
    }
  }

  // Users
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection(FirestorePaths.users)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  Future<void> blockUser(String userId) async {
    await _db.collection(FirestorePaths.users).doc(userId).update({
      'isBlocked': true,
    });
  }

  Future<void> unblockUser(String userId) async {
    await _db.collection(FirestorePaths.users).doc(userId).update({
      'isBlocked': false,
    });
  }

  Future<String> revealPhone(String userId) async {
    final doc = await _db.collection(FirestorePaths.users).doc(userId).get();
    if (doc.exists) {
      final u = UserModel.fromFirestore(doc);
      return u.phone;
    }
    return 'Unknown';
  }

  // Chats
  Stream<List<ChatModel>> streamAllChats() {
    return _db.collection(FirestorePaths.chats)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromFirestore(d)).toList());
  }

  Stream<List<MessageModel>> streamChatMessages(String chatId) {
    return _db.collection(FirestorePaths.chats).doc(chatId).collection(FirestorePaths.messages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  // Reports
  Stream<List<Map<String, dynamic>>> streamReports() {
    return _db.collection(FirestorePaths.reports)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> resolveReport(String reportId) async {
    await _db.collection(FirestorePaths.reports).doc(reportId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
