import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/doctor_demo_screen.dart';
import 'package:aicu/screens/nurse_demo_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AicuApp());
}

class AicuApp extends StatelessWidget {
  const AicuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'AICU', home: DemoHomeScreen());
  }
}

// Demo entry point: no real Firebase Auth sign-in, fixed demo ward/patient
// IDs. Wiring for the escalation demo only — not part of the 25-task plan.
class DemoHomeScreen extends StatelessWidget {
  DemoHomeScreen({super.key});

  final _vitalsRepository = VitalsRepository(firestore: FirebaseFirestore.instance);
  final _escalationRepository = EscalationRepository(firestore: FirebaseFirestore.instance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AICU — demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              key: const Key('nurseDemoButton'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NurseDemoScreen(
                  vitalsRepository: _vitalsRepository,
                  escalationRepository: _escalationRepository,
                ),
              )),
              child: const Text('Nurse view (demo)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('doctorDemoButton'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DoctorDemoScreen(escalationRepository: _escalationRepository),
              )),
              child: const Text('Doctor view (demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
