import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:aicu/models/demo_patients.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/patient_note_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/clinical_dashboard_screen.dart';
import 'package:aicu/screens/clinical_insights_screen.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
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
  final _patientNoteRepository = PatientNoteRepository(firestore: FirebaseFirestore.instance);

  @override
  State<AicuShellScreen> createState() => _AicuShellScreenState();
}

class _AicuShellScreenState extends State<AicuShellScreen> {
  int _index = 0;
  Patient _selectedPatient = janeDoe;

  void _selectPatient(Patient patient) => setState(() => _selectedPatient = patient);

  // ponytail: demo-only stand-in for real login. No AuthRepository/RoleRouter
  // wiring yet (Task 3 built them, unused), so this in-memory toggle lets us
  // demo both a nurse and a doctor acting against the same patient. Delete
  // this once real auth is wired in.
  String _actingAsRole = 'nurse';

  @override
  Widget build(BuildContext context) {
    final actingAsUserId = _actingAsRole == 'doctor' ? 'demo-doctor' : 'demo-nurse';
    final screens = [
      ClinicalDashboardScreen(
        vitalsRepository: widget._vitalsRepository,
        escalationRepository: widget._escalationRepository,
        onPatientSelected: _selectPatient,
      ),
      PatientFileScreen(
        patient: _selectedPatient,
        info: demoPatientInfo[_selectedPatient.patientId]!,
        vitalsRepository: widget._vitalsRepository,
        escalationRepository: widget._escalationRepository,
      ),
      VoiceAiScreen(
        patient: _selectedPatient,
        patientId: _selectedPatient.patientId,
        wardId: _selectedPatient.wardId,
        patientNoteRepository: widget._patientNoteRepository,
        vitalsRepository: widget._vitalsRepository,
        escalationRepository: widget._escalationRepository,
        currentUserId: actingAsUserId,
        currentUserRole: _actingAsRole,
      ),
      const ClinicalInsightsScreen(),
    ];

    return Scaffold(
      body: Column(children: [
        if (_index == 2)
          // ponytail: demo-only role switcher, see comment on _actingAsRole above.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'nurse', label: Text('Acting as: Nurse')),
                ButtonSegment(value: 'doctor', label: Text('Acting as: Doctor')),
              ],
              selected: {_actingAsRole},
              onSelectionChanged: (selection) => setState(() => _actingAsRole = selection.first),
            ),
          ),
        Expanded(child: IndexedStack(index: _index, children: screens)),
      ]),
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
