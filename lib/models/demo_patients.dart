import 'package:aicu/models/patient.dart';

final janeDoe = Patient(
  patientId: 'demo-patient',
  wardId: 'demo-ward',
  fullName: 'Jane Doe (Demo)',
  dob: DateTime(1980, 3, 12), // ~45y
  allergies: const ['Penicillin'],
  diagnosis: 'Pneumonia',
  lines: const [],
  intakeOutputMl: const {'intake': 0, 'output': 0},
);

final rohanMehta = Patient(
  patientId: 'demo-patient-2',
  wardId: 'demo-ward',
  fullName: 'Rohan Mehta (Demo)',
  dob: DateTime(1963, 7, 4), // ~62y
  allergies: const ['Sulfa drugs'],
  diagnosis: 'COPD exacerbation',
  lines: const [],
  intakeOutputMl: const {'intake': 0, 'output': 0},
);

final priyaNair = Patient(
  patientId: 'demo-patient-3',
  wardId: 'demo-ward',
  fullName: 'Priya Nair (Demo)',
  dob: DateTime(1991, 11, 20), // ~34y
  allergies: const [],
  diagnosis: 'Post-appendectomy recovery',
  lines: const [],
  intakeOutputMl: const {'intake': 0, 'output': 0},
);

final demoPatients = [janeDoe, rohanMehta, priyaNair];

// ponytail: cosmetic per-patient demo metadata that doesn't belong on the
// shared Patient model (avoids touching Patient.fromMap / repositories).
// Keyed by patientId; upgrade to real Firestore fields if this ever needs
// to be editable.
class DemoPatientInfo {
  final String bedLabel;
  final String attendingPhysician;
  final String sex;
  final String bloodGroup;
  final List<String> conditions;
  const DemoPatientInfo({
    required this.bedLabel,
    required this.attendingPhysician,
    required this.sex,
    required this.bloodGroup,
    required this.conditions,
  });
}

final demoPatientInfo = <String, DemoPatientInfo>{
  janeDoe.patientId: const DemoPatientInfo(
    bedLabel: 'Room 4B, Bed 2',
    attendingPhysician: 'Dr. Mehta',
    sex: 'F',
    bloodGroup: 'B+',
    conditions: ['Type 2 Diabetes (6 yrs)', 'Hypertension Stage 1'],
  ),
  rohanMehta.patientId: const DemoPatientInfo(
    bedLabel: 'Room 5A, Bed 1',
    attendingPhysician: 'Dr. Iyer',
    sex: 'M',
    bloodGroup: 'O+',
    conditions: ['COPD (12 yrs)', 'Ischemic Heart Disease'],
  ),
  priyaNair.patientId: const DemoPatientInfo(
    bedLabel: 'Room 3C, Bed 4',
    attendingPhysician: 'Dr. Rao',
    sex: 'F',
    bloodGroup: 'A-',
    conditions: ['No significant past medical history'],
  ),
};
