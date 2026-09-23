import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String patientId;
  final String wardId;
  final String fullName;
  final DateTime dob;
  final List<String> allergies;
  final String diagnosis;
  final List<Map<String, dynamic>> lines;
  final Map<String, dynamic> intakeOutputMl;

  const Patient({
    required this.patientId,
    required this.wardId,
    required this.fullName,
    required this.dob,
    required this.allergies,
    required this.diagnosis,
    required this.lines,
    required this.intakeOutputMl,
  });

  factory Patient.fromMap(String id, Map<String, dynamic> map) => Patient(
        patientId: id,
        wardId: map['wardId'] as String,
        fullName: map['fullName'] as String,
        dob: (map['dob'] as Timestamp).toDate(),
        allergies: List<String>.from(map['allergies'] as List),
        diagnosis: map['diagnosis'] as String,
        lines: List<Map<String, dynamic>>.from(map['lines'] as List),
        intakeOutputMl: Map<String, dynamic>.from(map['intakeOutputMl'] as Map),
      );
}
