import 'package:flutter/material.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/services/escalation_rule.dart';
import 'package:aicu/services/news2_engine.dart';
import 'package:aicu/services/sbar_builder.dart';

/// Shared escalation-decision logic for any screen that has just recorded a
/// [VitalsReading] and scored it (NurseDemoScreen's manual entry form,
/// VoiceAiScreen's voice-extracted vitals): same NEWS2-driven decision either
/// caller uses — raise an escalation via SBAR if warranted, else just confirm
/// the recording. Takes an already-scored [result] rather than calling
/// VitalsRepository.recordVitals itself, since the nurse-entry path already
/// records via VitalsEntryScreen before this runs; the voice path records
/// directly then calls this with the same result shape.
Future<void> handleVitalsSubmission({
  required BuildContext context,
  required EscalationRepository escalationRepository,
  required Patient patient,
  required VitalsReading reading,
  required News2Result result,
  required String recordedBy,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (EscalationRule.shouldEscalate(result)) {
    final sbar = SbarBuilder.build(patient, reading, result);
    await escalationRepository.raiseEscalation(
      patientId: patient.patientId,
      wardId: patient.wardId,
      triggeredByVitalId: 'demo-vital-latest',
      news2Score: result.aggregate,
      news2Band: result.band.name,
      raisedBy: recordedBy,
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
