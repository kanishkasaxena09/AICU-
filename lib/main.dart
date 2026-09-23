import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/clinical_dashboard_screen.dart';
import 'package:aicu/screens/clinical_insights_screen.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
import 'package:aicu/screens/nurse_demo_screen.dart';
import 'package:aicu/screens/patient_file_screen.dart';
import 'package:aicu/screens/voice_ai_screen.dart';
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
    return MaterialApp(title: 'AICU', home: AicuShellScreen());
  }
}

// Demo entry point: no real Firebase Auth sign-in, fixed demo ward/patient
// IDs. Bottom-nav shell wiring the 4 redesigned screens; Dashboard and
// Patient File screens carry the working nurse/doctor demo flow forward.
class AicuShellScreen extends StatefulWidget {
  AicuShellScreen({super.key});

  final _vitalsRepository = VitalsRepository(firestore: FirebaseFirestore.instance);
  final _escalationRepository = EscalationRepository(firestore: FirebaseFirestore.instance);

  @override
  State<AicuShellScreen> createState() => _AicuShellScreenState();
}

class _AicuShellScreenState extends State<AicuShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ClinicalDashboardScreen(
        vitalsRepository: widget._vitalsRepository,
        escalationRepository: widget._escalationRepository,
      ),
      PatientFileScreen(
        patient: demoPatient,
        vitalsRepository: widget._vitalsRepository,
        escalationRepository: widget._escalationRepository,
      ),
      const VoiceAiScreen(),
      const ClinicalInsightsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AicuColors.primary,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.mic_none), label: 'Voice AI'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
        ],
      ),
    );
  }
}
