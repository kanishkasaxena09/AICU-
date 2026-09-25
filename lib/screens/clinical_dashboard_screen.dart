import 'package:flutter/material.dart';
import 'package:aicu/models/demo_patients.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
import 'package:aicu/screens/patient_file_screen.dart';

class ClinicalDashboardScreen extends StatelessWidget {
  final VitalsRepository vitalsRepository;
  final EscalationRepository escalationRepository;
  final ValueChanged<Patient> onPatientSelected;
  const ClinicalDashboardScreen({
    super.key,
    required this.vitalsRepository,
    required this.escalationRepository,
    required this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AicuColors.background,
      appBar: aicuAppBar(context, 'Clinical Das...'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HandoverSummaryCard(),
          const SizedBox(height: 16),
          _SearchAndFilterRow(),
          const SizedBox(height: 16),
          _QuickActionsRow(),
          const SizedBox(height: 16),
          const Text('Ward Patients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          for (final patient in demoPatients) ...[
            _PatientListCard(
              patient: patient,
              info: demoPatientInfo[patient.patientId]!,
              vitalsRepository: vitalsRepository,
              onSelect: () => _openPatientFile(context, patient),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _openPatientFile(BuildContext context, Patient patient) {
    onPatientSelected(patient);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PatientFileScreen(
        patient: patient,
        info: demoPatientInfo[patient.patientId]!,
        vitalsRepository: vitalsRepository,
        escalationRepository: escalationRepository,
      ),
    ));
  }
}

class _HandoverSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AicuColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Doctor Handover Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const Pill('2 High-Attention', background: AicuColors.alertBg, foreground: AicuColors.alert),
        ]),
        const SizedBox(height: 12),
        const Text(
          'Night Shift → Morning Rounds: 2 critical post-op vitals tracked in Step-down ICU. '
          '4 stable discharges pending.',
          style: TextStyle(color: Colors.black87, height: 1.4),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(
            child: Text('Completed at 07:45 AM • Dr. Mehta', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => _showReviewNotesDialog(context),
            child: const Text('Review Notes'),
          ),
        ]),
      ]),
    );
  }
}

class _SearchAndFilterRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: const TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.person_search, color: AicuColors.primary),
              hintText: 'Jane Doe (Demo)',
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Container(
        decoration: BoxDecoration(color: AicuColors.primary, borderRadius: BorderRadius.circular(12)),
        child: IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () => _showFilterDialog(context)),
      ),
    ]);
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onPressed) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: AicuColors.primary),
          label: Text(label, style: const TextStyle(color: AicuColors.primary, fontSize: 12), overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AicuColors.primary), padding: const EdgeInsets.symmetric(vertical: 10)),
        ),
      );
    }

    return Row(children: [
      action(Icons.person_add_alt_1, 'Add Patient', () => _showAddPatientDialog(context)),
      const SizedBox(width: 8),
      action(Icons.edit_note, 'Write Rx', () => _showWriteRxDialog(context)),
      const SizedBox(width: 8),
      action(Icons.science_outlined, 'New Lab Order', () => _showNewLabOrderDialog(context)),
    ]);
  }
}

class _PatientListCard extends StatelessWidget {
  final Patient patient;
  final DemoPatientInfo info;
  final VitalsRepository vitalsRepository;
  final VoidCallback onSelect;
  const _PatientListCard({
    required this.patient,
    required this.info,
    required this.vitalsRepository,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final age = computeAge(patient.dob);
    final initials = patient.fullName.trim().isEmpty
        ? '?'
        : patient.fullName.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join().toUpperCase();
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: AicuColors.tealBg, child: Text(initials, style: const TextStyle(color: AicuColors.primaryDark, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Pill(patient.patientId),
              ]),
              const SizedBox(height: 2),
              Text('${age}y ${info.sex} • ${info.bedLabel}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
          const Pill('Inpatient Active'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.favorite, size: 14, color: AicuColors.alert),
          const SizedBox(width: 4),
          Text('Diagnosis: ${patient.diagnosis}', style: const TextStyle(fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        Pill('Attending: ${info.attendingPhysician}', background: AicuColors.background, foreground: Colors.black87),
        const SizedBox(height: 10),
        StreamBuilder<Map<String, dynamic>?>(
          stream: vitalsRepository.watchLatestVitals(patient.patientId),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) {
              return const Text('No vitals recorded yet', style: TextStyle(fontSize: 12, color: Colors.black54));
            }
            final abnormal = data['news2Band'] == 'medium' || data['news2Band'] == 'high';
            return Row(children: [
              Expanded(child: VitalTile(label: 'Systolic BP', value: '${data['systolicBp']} mmHg', abnormal: abnormal)),
              const SizedBox(width: 8),
              Expanded(child: VitalTile(label: 'Respiration Rate', value: '${data['respirationRate']} /min', abnormal: abnormal)),
              const SizedBox(width: 8),
              Expanded(child: VitalTile(label: 'SpO2 / Pulse', value: '${data['spo2']}% / ${data['pulse']}', abnormal: abnormal)),
            ]);
          },
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: onSelect, child: const Text('Select →'))),
      ]),
    );
  }
}

void _showReviewNotesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Handover Notes'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• Room 4B (Jane Doe): pneumonia, monitor for escalation, penicillin allergy noted on chart.'),
          SizedBox(height: 8),
          Text('• Room 5A (Rohan Mehta): COPD exacerbation, on 2L O2 via nasal cannula, target SpO2 88-92%.'),
          SizedBox(height: 8),
          Text('• 2 patients cleared for discharge pending final labs.'),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    ),
  );
}

void _showAddPatientDialog(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final diagnosisCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add Patient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
          TextField(controller: diagnosisCtrl, decoration: const InputDecoration(labelText: 'Diagnosis')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            // ponytail: demo-only action — there's no patient-creation repository method
            // in this app yet, so this just confirms via SnackBar without persisting
            // anything to Firestore or the demoPatients list.
            Navigator.of(dialogContext).pop();
            messenger.showSnackBar(const SnackBar(content: Text('Patient added to ward (demo)')));
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

void _showWriteRxDialog(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  Patient selectedPatient = demoPatients.first;
  final medicationCtrl = TextEditingController();
  final dosageCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Write Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<Patient>(
              value: selectedPatient,
              isExpanded: true,
              items: [for (final p in demoPatients) DropdownMenuItem(value: p, child: Text(p.fullName))],
              onChanged: (p) => setState(() => selectedPatient = p!),
            ),
            TextField(controller: medicationCtrl, decoration: const InputDecoration(labelText: 'Medication')),
            TextField(controller: dosageCtrl, decoration: const InputDecoration(labelText: 'Dosage')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              // ponytail: demo-only action — no prescription backend exists yet, so this
              // just confirms via SnackBar without persisting anything.
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(SnackBar(content: Text('Prescription sent for ${selectedPatient.fullName} (demo)')));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ),
  );
}

const _demoLabTests = ['CBC', 'Basic Metabolic Panel', 'Chest X-ray', 'Blood Culture'];

void _showNewLabOrderDialog(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  Patient selectedPatient = demoPatients.first;
  String selectedTest = _demoLabTests.first;
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('New Lab Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<Patient>(
              value: selectedPatient,
              isExpanded: true,
              items: [for (final p in demoPatients) DropdownMenuItem(value: p, child: Text(p.fullName))],
              onChanged: (p) => setState(() => selectedPatient = p!),
            ),
            DropdownButton<String>(
              value: selectedTest,
              isExpanded: true,
              items: [for (final t in _demoLabTests) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (t) => setState(() => selectedTest = t!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              // ponytail: demo-only action — no lab-order backend exists yet, so this
              // just confirms via SnackBar without persisting anything.
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(SnackBar(content: Text('Lab order placed: $selectedTest for ${selectedPatient.fullName} (demo)')));
            },
            child: const Text('Order'),
          ),
        ],
      ),
    ),
  );
}

void _showFilterDialog(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  bool highRiskOnly = false;
  bool myPatientsOnly = false;
  bool sortByRoom = false;
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Filter Ward Patients'),
        // ponytail: with only 3 demo patients these toggles are cosmetic and don't
        // actually filter/sort demoPatients — upgrade if the ward list grows.
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: highRiskOnly,
              title: const Text('Show only high-risk (NEWS2 ≥ 5)'),
              onChanged: (v) => setState(() => highRiskOnly = v ?? false),
            ),
            CheckboxListTile(
              value: myPatientsOnly,
              title: const Text('Show only my patients'),
              onChanged: (v) => setState(() => myPatientsOnly = v ?? false),
            ),
            CheckboxListTile(
              value: sortByRoom,
              title: const Text('Sort by room number'),
              onChanged: (v) => setState(() => sortByRoom = v ?? false),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              messenger.showSnackBar(const SnackBar(content: Text('Filters applied (demo)')));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}
