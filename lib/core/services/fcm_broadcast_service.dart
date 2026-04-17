import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

class FcmBroadcastService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String target, // 'all_users'|'all_clients'|'all_providers'|'approved_providers'|'specific'
    required String method, // 'notification'|'in_app'|'both'
    String? specificUid,
  }) async {
    await _db.collection(FirestorePaths.broadcastJobs).add({
      'title': title,
      'body': body,
      'target': target,
      'method': method,
      'specificUid': specificUid,
      'status': 'completed', 
      'createdAt': FieldValue.serverTimestamp(),
      'sentBy': 'admin_panel',
    });
  }

  Stream<List<Map<String, dynamic>>> streamBroadcastHistory() {
    return _db.collection(FirestorePaths.broadcastJobs)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Future<void> deleteBroadcast(String id) async {
    await _db.collection(FirestorePaths.broadcastJobs).doc(id).delete();
  }
}
