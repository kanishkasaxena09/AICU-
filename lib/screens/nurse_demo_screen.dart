import 'package:flutter/material.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/vitals_entry_screen.dart';
import 'package:aicu/services/escalation_rule.dart';
import 'package:aicu/services/news2_engine.dart';
import 'package:aicu/services/sbar_builder.dart';

// Demo-only patient — no Firestore patients/{id} doc is required for this
// wiring, since only SbarBuilder needs a Patient and it only reads these
// fields. Wiring is not part of the 25-task plan; see plan ledger.
final demoPatient = Patient(
  patientId: 'demo-patient',
  wardId: 'demo-ward',
  fullName: 'Jane Doe (Demo)',
  dob: DateTime(1980, 1, 1),
  allergies: const ['penicillin'],
  diagnosis: 'pneumonia',
  lines: const [],
  intakeOutputMl: const {'intake': 0, 'output': 0},
);

class NurseDemoScreen extends StatelessWidget {
  final VitalsRepository vitalsRepository;
  final EscalationRepository escalationRepository;
  const NurseDemoScreen({super.key, required this.vitalsRepository, required this.escalationRepository});

  Future<void> _handleReading(BuildContext context, VitalsReading reading, News2Result result) async {
    final messenger = ScaffoldMessenger.of(context);
    if (EscalationRule.shouldEscalate(result)) {
      final sbar = SbarBuilder.build(demoPatient, reading, result);
      await escalationRepository.raiseEscalation(
        patientId: demoPatient.patientId,
        wardId: demoPatient.wardId,
        triggeredByVitalId: 'demo-vital-latest',
        news2Score: result.aggregate,
        news2Band: result.band.name,
        raisedBy: 'demo-nurse',
        sbarSummary: sbar,
      );
      messenger.showSnackBar(SnackBar(
        content: Text('Escalation raised — NEWS2 ${result.aggregate} (${result.band.name})'),
        backgroundColor: Colors.red,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text('Vitals recorded — NEWS2 ${result.aggregate} (${result.band.name})'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return VitalsEntryScreen(
      patientId: demoPatient.patientId,
      wardId: demoPatient.wardId,
      recordedBy: 'demo-nurse',
      vitalsRepository: vitalsRepository,
      onRecorded: (_) {},
      onReadingRecorded: (reading, result) => _handleReading(context, reading, result),
    );
  }
}
