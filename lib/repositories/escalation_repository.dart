import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aicu/models/escalation.dart';
import 'package:aicu/models/sbar_summary.dart';

class EscalationRepository {
  final FirebaseFirestore firestore;
  EscalationRepository({required this.firestore});

  Future<String> raiseEscalation({
    required String patientId,
    required String wardId,
    required String triggeredByVitalId,
    required int news2Score,
    required String news2Band,
    required String raisedBy,
    required SbarSummary sbarSummary,
  }) async {
    final doc = await firestore.collection('escalations').add({
      'patientId': patientId,
      'wardId': wardId,
      'triggeredByVitalId': triggeredByVitalId,
      'news2Score': news2Score,
      'news2Band': news2Band,
      'raisedBy': raisedBy,
      'raisedAt': FieldValue.serverTimestamp(),
      'sbarSummary': sbarSummary.toMap(),
      'acknowledgedBy': null,
      'acknowledgedAt': null,
      'responseTimeSeconds': null,
    });
    return doc.id;
  }

  // Realtime, in-app delivery — replaces FCM push per spec §3.1.
  Stream<List<Escalation>> watchOpenEscalations(String wardId) {
    return firestore
        .collection('escalations')
        .where('wardId', isEqualTo: wardId)
        .where('acknowledgedAt', isNull: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Escalation.fromMap(d.id, d.data())).toList());
  }
}
