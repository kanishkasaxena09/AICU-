import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/services/news2_engine.dart';
import 'package:aicu/services/sbar_builder.dart';

void main() {
  test('build fills all four SBAR fields from patient + vitals + NEWS2 result', () {
    final patient = Patient(
      patientId: 'p1', wardId: 'w1', fullName: 'Jane Doe', dob: DateTime(1980, 1, 1),
      allergies: const ['penicillin'], diagnosis: 'pneumonia', lines: const [],
      intakeOutputMl: const {'intake': 0, 'output': 0},
    );
    const reading = VitalsReading(
      respirationRate: 26, spo2: 90, spo2Scale: SpoScale.scale1, onSupplementalOxygen: false,
      systolicBp: 120, pulse: 75, consciousness: Consciousness.alert, temperature: 36.5,
    );
    final result = News2Engine.score(reading);

    final sbar = SbarBuilder.build(patient, reading, result);

    expect(sbar.situation, contains('Jane Doe'));
    expect(sbar.situation, contains('NEWS2'));
    expect(sbar.background, contains('pneumonia'));
    expect(sbar.background, contains('penicillin'));
    expect(sbar.assessment, contains('respiration rate'));
    expect(sbar.assessment, contains('SpO2'));
    expect(sbar.recommendation, isNotEmpty);
  });
}
