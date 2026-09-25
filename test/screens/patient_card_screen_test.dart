import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/repositories/patient_repository.dart';
import 'package:aicu/screens/patient_card_screen.dart';

void main() {
  testWidgets('patient card shows name, diagnosis, and allergies', (tester) async {
    final patient = Patient(
      patientId: 'p1', wardId: 'w1', fullName: 'Jane Doe',
      dob: DateTime(1980, 1, 1), allergies: const ['penicillin'],
      diagnosis: 'pneumonia', lines: const [], intakeOutputMl: const {'intake': 0, 'output': 0},
    );
    await tester.pumpWidget(MaterialApp(
      home: PatientCardScreen(
        patient: patient,
        patientRepository: PatientRepository(firestore: FakeFirebaseFirestore()),
      ),
    ));

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('pneumonia'), findsOneWidget);
    expect(find.textContaining('penicillin'), findsOneWidget);
  });
}
