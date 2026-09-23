import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/repositories/patient_repository.dart';

void main() {
  test('lookupByQr resolves a patientId to the Patient doc', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('patients').doc('p1').set({
      'wardId': 'w1',
      'fullName': 'Jane Doe',
      'dob': DateTime(1980, 1, 1),
      'allergies': ['penicillin'],
      'diagnosis': 'pneumonia',
      'lines': [],
      'intakeOutputMl': {'intake': 0, 'output': 0},
    });
    final repo = PatientRepository(firestore: firestore);

    final patient = await repo.lookupByQr('p1');

    expect(patient, isNotNull);
    expect(patient!.fullName, 'Jane Doe');
    expect(patient.allergies, ['penicillin']);
  });

  test('lookupByQr returns null for an unknown patientId', () async {
    final repo = PatientRepository(firestore: FakeFirebaseFirestore());
    expect(await repo.lookupByQr('missing'), isNull);
  });
}
