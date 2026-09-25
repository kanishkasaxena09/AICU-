import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/services/news2_engine.dart';

void main() {
  test('recordVitals writes computed NEWS2 fields and returns them', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = VitalsRepository(firestore: firestore);
    final reading = const VitalsReading(
      respirationRate: 26,
      spo2: 98,
      spo2Scale: SpoScale.scale1,
      onSupplementalOxygen: false,
      systolicBp: 120,
      pulse: 75,
      consciousness: Consciousness.alert,
      temperature: 36.5,
    );

    final result = await repo.recordVitals(
      patientId: 'p1',
      wardId: 'w1',
      recordedBy: 'nurse-u1',
      reading: reading,
    );

    expect(result.band, News2Band.low);
    expect(result.redFlag, true);

    final docs = await firestore.collection('vitals').get();
    expect(docs.docs.length, 1);
    final data = docs.docs.first.data();
    expect(data['patientId'], 'p1');
    expect(data['news2Score'], result.aggregate);
    expect(data['news2RedFlag'], true);
  });
}
