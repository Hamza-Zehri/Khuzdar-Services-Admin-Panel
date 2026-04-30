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
    final doc = await _db.collection(FirestorePaths.providers).doc(providerId).get();
    if (!doc.exists) return;

    final provider = ProviderModel.fromFirestore(doc);
    final batch = _db.batch();

    // 1. Update provider verification status
    batch.update(_db.collection(FirestorePaths.providers).doc(providerId), {
      'verificationStatus': VerificationStatus.approved.name,
      'isAvailable': true,
    });

    // 2. Update associated user's role to 'provider'
    batch.update(_db.collection(FirestorePaths.users).doc(provider.userId), {
      'role': UserRole.provider.name,
    });

    await batch.commit();
  }

  Future<UserModel?> fetchUserInfo(String userId) async {
    final doc = await _db.collection(FirestorePaths.users).doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
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

  /// Delete a user and their associated provider profile atomically
  Future<void> deleteUser(String userId) async {
    final batch = _db.batch();
    // Delete user document
    batch.delete(_db.collection(FirestorePaths.users).doc(userId));
    // Delete provider document if it exists (provider ID == userId by design)
    batch.delete(_db.collection(FirestorePaths.providers).doc(userId));
    await batch.commit();
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

  // Categories
  Stream<List<CategoryModel>> streamCategories() {
    return _db.collection(FirestorePaths.categories)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.collection(FirestorePaths.categories).add(category.toFirestore());
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _db.collection(FirestorePaths.categories).doc(category.id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection(FirestorePaths.categories).doc(categoryId).delete();
  }
}
