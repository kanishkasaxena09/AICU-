import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:aicu/repositories/patient_repository.dart';
import 'package:aicu/screens/patient_card_screen.dart';

class QrScanScreen extends StatelessWidget {
  final PatientRepository patientRepository;
  const QrScanScreen({super.key, required this.patientRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan patient QR')),
      body: MobileScanner(
        onDetect: (capture) async {
          final code = capture.barcodes.first.rawValue;
          if (code == null) return;
          final patient = await patientRepository.lookupByQr(code);
          if (patient != null && context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PatientCardScreen(patient: patient, patientRepository: patientRepository),
              ),
            );
          }
        },
      ),
    );
  }
}
