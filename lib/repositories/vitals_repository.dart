import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/services/news2_engine.dart';

class VitalsRepository {
  final FirebaseFirestore firestore;
  VitalsRepository({required this.firestore});

  Future<News2Result> recordVitals({
    required String patientId,
    required String wardId,
    required String recordedBy,
    required VitalsReading reading,
  }) async {
    final result = News2Engine.score(reading);
    await firestore.collection('vitals').add({
      'patientId': patientId,
      'wardId': wardId,
      'recordedBy': recordedBy,
      'recordedAt': FieldValue.serverTimestamp(),
      'respirationRate': reading.respirationRate,
      'spo2': reading.spo2,
      'spo2Scale': reading.spo2Scale == SpoScale.scale1 ? 1 : 2,
      'onSupplementalOxygen': reading.onSupplementalOxygen,
      'systolicBp': reading.systolicBp,
      'pulse': reading.pulse,
      'consciousness': _consciousnessCode(reading.consciousness),
      'temperature': reading.temperature,
      'news2Score': result.aggregate,
      'news2Band': result.band.name,
      'news2RedFlag': result.redFlag,
    });
    return result;
  }

  // ponytail: sorted client-side (same precedent as patient_note_repository's
  // watchNotes) to avoid needing a composite Firestore index.
  Stream<Map<String, dynamic>?> watchLatestVitals(String patientId) {
    return firestore
        .collection('vitals')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final sorted = snap.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['recordedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = (b.data()['recordedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
      return sorted.first.data();
    });
  }

  String _consciousnessCode(Consciousness c) => switch (c) {
        Consciousness.alert => 'A',
        Consciousness.confusionNew => 'C',
        Consciousness.voice => 'V',
        Consciousness.pain => 'P',
        Consciousness.unresponsive => 'U',
      };
}
