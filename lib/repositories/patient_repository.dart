import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aicu/models/patient.dart';

class PatientRepository {
  final FirebaseFirestore firestore;
  PatientRepository({required this.firestore});

  Future<Patient?> lookupByQr(String qrPayload) async {
    final doc = await firestore.collection('patients').doc(qrPayload).get();
    if (!doc.exists) return null;
    return Patient.fromMap(doc.id, doc.data()!);
  }

  Stream<Patient> watchPatient(String patientId) {
    return firestore
        .collection('patients')
        .doc(patientId)
        .snapshots()
        .map((doc) => Patient.fromMap(doc.id, doc.data()!));
  }
}
