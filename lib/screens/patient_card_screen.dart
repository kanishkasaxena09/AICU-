import 'package:flutter/material.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/repositories/patient_repository.dart';

class PatientCardScreen extends StatelessWidget {
  final Patient patient;
  final PatientRepository patientRepository;
  const PatientCardScreen({super.key, required this.patient, required this.patientRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(patient.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Diagnosis: '),
            Text(patient.diagnosis),
          ]),
          Text('Allergies: ${patient.allergies.join(', ')}'),
        ]),
      ),
    );
  }
}
