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

  String _consciousnessCode(Consciousness c) => switch (c) {
        Consciousness.alert => 'A',
        Consciousness.confusionNew => 'C',
        Consciousness.voice => 'V',
        Consciousness.pain => 'P',
        Consciousness.unresponsive => 'U',
      };
}
