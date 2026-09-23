import 'package:aicu/models/patient.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/models/sbar_summary.dart';
import 'package:aicu/services/news2_engine.dart';

class SbarBuilder {
  static SbarSummary build(Patient patient, VitalsReading reading, News2Result result) {
    final abnormal = <String>[];
    if (reading.respirationRate >= 21 || reading.respirationRate <= 11) {
      abnormal.add('respiration rate ${reading.respirationRate}/min');
    }
    if (reading.spo2 <= 93) abnormal.add('SpO2 ${reading.spo2}%');
    if (reading.systolicBp >= 181 || reading.systolicBp <= 100) {
      abnormal.add('systolic BP ${reading.systolicBp} mmHg');
    }
    if (reading.pulse >= 91 || reading.pulse <= 50) abnormal.add('pulse ${reading.pulse}/min');
    if (reading.consciousness != Consciousness.alert) abnormal.add('altered consciousness');
    if (reading.temperature >= 38.1 || reading.temperature <= 36.0) {
      abnormal.add('temperature ${reading.temperature}°C');
    }

    final recommendation = switch (result.band) {
      News2Band.high => 'Requires emergency assessment by a critical care team now.',
      News2Band.medium => 'Requires urgent clinician review within the hour.',
      News2Band.low => result.redFlag
          ? 'Single-parameter red score — requires urgent review regardless of aggregate.'
          : 'Continue routine monitoring per ward protocol.',
      News2Band.none => 'Continue routine monitoring.',
    };

    return SbarSummary(
      situation: '${patient.fullName}, NEWS2 score ${result.aggregate} (${result.band.name}).',
      background: 'Diagnosis: ${patient.diagnosis}. Allergies: ${patient.allergies.join(', ')}.',
      assessment: abnormal.isEmpty ? 'No individually abnormal parameters.' : 'Abnormal: ${abnormal.join(', ')}.',
      recommendation: recommendation,
    );
  }
}
