import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

class FcmBroadcastService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String target, // 'all_users'|'all_providers'|'approved_providers'|'specific'
    String? specificUid,
  }) async {
    // This assumes a Firebase Cloud Function is listening to 'broadcast_jobs'
    // collection to fan-out FCM notifications. Or it serves as an audit log.
    await _db.collection(FirestorePaths.broadcastJobs).add({
      'title': title,
      'body': body,
      'target': target,
      'specificUid': specificUid,
      'status': 'pending', // 'pending', 'processing', 'completed', 'failed'
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
}
