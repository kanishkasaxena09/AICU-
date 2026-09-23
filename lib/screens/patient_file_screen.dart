import 'package:flutter/material.dart';
import 'package:aicu/models/demo_patients.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
import 'package:aicu/screens/doctor_demo_screen.dart';
import 'package:aicu/screens/nurse_demo_screen.dart';

class PatientFileScreen extends StatelessWidget {
  final Patient patient;
  final DemoPatientInfo info;
  final VitalsRepository vitalsRepository;
  final EscalationRepository escalationRepository;
  const PatientFileScreen({
    super.key,
    required this.patient,
    required this.info,
    required this.vitalsRepository,
    required this.escalationRepository,
  });

  void _openVitalsEntry(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NurseDemoScreen(
        patient: patient,
        vitalsRepository: vitalsRepository,
        escalationRepository: escalationRepository,
      ),
    ));
  }

  void _openEscalations(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DoctorDemoScreen(escalationRepository: escalationRepository),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AicuColors.background,
        appBar: aicuAppBar(
          context,
          patient.fullName,
          extraActions: [
            IconButton(
              tooltip: 'Open escalations',
              icon: const Icon(Icons.warning_amber_outlined, color: AicuColors.alert),
              onPressed: () => _openEscalations(context),
            ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _HeaderCard(patient: patient, info: info),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: AicuColors.primary,
              indicator: BoxDecoration(color: AicuColors.primary, borderRadius: BorderRadius.all(Radius.circular(999))),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'History'),
                Tab(text: 'Vitals & Conditions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _OverviewTab(
                patient: patient,
                vitalsRepository: vitalsRepository,
                onLogVitals: () => _openVitalsEntry(context),
                onOpenEscalations: () => _openEscalations(context),
              ),
              _HistoryTab(patient: patient),
              _VitalsConditionsTab(
                patientId: patient.patientId,
                vitalsRepository: vitalsRepository,
                info: info,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Patient patient;
  final DemoPatientInfo info;
  const _HeaderCard({required this.patient, required this.info});

  @override
  Widget build(BuildContext context) {
    final age = computeAge(patient.dob);
    final initials = patient.fullName.trim().isEmpty
        ? '?'
        : patient.fullName.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join().toUpperCase();
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 26, backgroundColor: AicuColors.tealBg, child: Text(initials, style: const TextStyle(color: AicuColors.primaryDark, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                const Pill('P-10245'),
              ]),
              const SizedBox(height: 4),
              Text('${age}y ${info.sex} • Blood group ${info.bloodGroup}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill('Allergy: ${patient.allergies.join(', ')}', background: AicuColors.alertBg, foreground: AicuColors.alert, icon: Icons.error_outline),
          for (final condition in info.conditions) Pill(condition),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Attending: ${info.attendingPhysician} (Lead Physician, Internal Medicine)', style: const TextStyle(fontSize: 12, color: Colors.black87))),
          TextButton(onPressed: () => _showAttendingDetailsDialog(context, patient, info), child: const Text('Details')),
        ]),
      ]),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Patient patient;
  final VitalsRepository vitalsRepository;
  final VoidCallback onLogVitals;
  final VoidCallback onOpenEscalations;
  const _OverviewTab({
    required this.patient,
    required this.vitalsRepository,
    required this.onLogVitals,
    required this.onOpenEscalations,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NextReviewCard(),
        const SizedBox(height: 16),
        _QuickActions(patient: patient, onLogVitals: onLogVitals),
        const SizedBox(height: 16),
        _CaseSummaryCard(),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, dynamic>?>(
          stream: vitalsRepository.watchLatestVitals(patient.patientId),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) {
              return const Text('No vitals recorded yet', style: TextStyle(color: Colors.black54));
            }
            final abnormal = data['news2Band'] == 'medium' || data['news2Band'] == 'high';
            return Row(children: [
              Expanded(child: VitalTile(label: 'Systolic BP', value: '${data['systolicBp']} mmHg', abnormal: abnormal)),
              const SizedBox(width: 8),
              Expanded(child: VitalTile(label: 'Temperature', value: '${data['temperature']} °C', abnormal: abnormal)),
            ]);
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onOpenEscalations,
          icon: const Icon(Icons.notifications_active_outlined, color: AicuColors.primary),
          label: const Text('Open Escalations (Doctor view)', style: TextStyle(color: AicuColors.primary)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AicuColors.primary), minimumSize: const Size.fromHeight(44)),
        ),
      ],
    );
  }
}

class _NextReviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AicuColors.tealBg, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.calendar_today_outlined, color: AicuColors.primaryDark, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Next Clinical Review', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text('Tomorrow, 11:30 AM', style: TextStyle(fontSize: 13)),
            Text('Dr. Mehta • Step-down ICU', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        const Pill('18 Hours left'),
      ]),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Patient patient;
  final VoidCallback onLogVitals;
  const _QuickActions({required this.patient, required this.onLogVitals});

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: AicuColors.primary),
          label: Text(label, style: const TextStyle(color: AicuColors.primary, fontSize: 12), overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AicuColors.primary), padding: const EdgeInsets.symmetric(vertical: 10)),
        ),
      );
    }

    return Row(children: [
      action(Icons.note_add_outlined, 'Add Note', () => _showAddNoteDialog(context, patient)),
      const SizedBox(width: 6),
      action(Icons.monitor_heart_outlined, 'Log Vitals', onLogVitals),
      const SizedBox(width: 6),
      action(Icons.biotech_outlined, 'Order Lab', () => _showOrderLabDialog(context, patient)),
      const SizedBox(width: 6),
      action(Icons.ios_share, 'Share Rx', () => _showShareRxDialog(context, patient)),
    ]);
  }
}

class _CaseSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Expanded(child: Text('Physician Case Summary', style: TextStyle(fontWeight: FontWeight.bold))),
          Pill('Updated Today'),
        ]),
        const SizedBox(height: 10),
        const Text(
          'Patient continues management for pneumonia with comorbid Type 2 diabetes and stage 1 '
          'hypertension. Vitals trending stable overnight; glycemic control remains the primary '
          'focus of this admission.',
          style: TextStyle(height: 1.4, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: const [
          Pill('Compliance: 92%'),
          Pill('Target HbA1c: < 7.0%'),
        ]),
      ]),
    );
  }
}

// -- Attending physician details -------------------------------------------

String _specialtyFor(Patient patient) {
  final dx = patient.diagnosis.toLowerCase();
  if (dx.contains('copd')) return 'Pulmonology';
  if (dx.contains('appendectomy') || dx.contains('surgery') || dx.contains('post-op')) return 'General Surgery';
  return 'Internal Medicine';
}

void _showAttendingDetailsDialog(BuildContext context, Patient patient, DemoPatientInfo info) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(info.attendingPhysician),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_specialtyFor(patient), style: const TextStyle(fontWeight: FontWeight.w600, color: AicuColors.primary)),
        const SizedBox(height: 8),
        const Text('Rounds: 7:00 AM & 6:00 PM · Page via ward desk', style: TextStyle(color: Colors.black54)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    ),
  );
}

// -- Add Note ----------------------------------------------------------------

void _showAddNoteDialog(BuildContext context, Patient patient) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add Note'),
      content: TextField(
        controller: controller,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter clinical note…', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            // ponytail: UI-only demo action — not persisted anywhere. This screen
            // has no PatientNoteRepository wired in; real persistence lives in
            // voice_ai_screen.dart's construction chain and is out of scope here.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Note added to ${patient.fullName}'s chart (demo)")),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// -- Order Lab ----------------------------------------------------------------

const _labTests = [
  'CBC',
  'Basic Metabolic Panel',
  'Liver Function Panel',
  'Chest X-ray',
  'Sputum Culture',
  'ABG (Arterial Blood Gas)',
];

void _showOrderLabDialog(BuildContext context, Patient patient) {
  var selected = _labTests.first;
  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Order Lab'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final test in _labTests)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(test),
                trailing: selected == test ? const Icon(Icons.check_circle, color: AicuColors.primary) : const Icon(Icons.circle_outlined, color: Colors.black26),
                onTap: () => setState(() => selected = test),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // ponytail: UI-only demo action — no lab order is actually placed/persisted.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lab order placed: $selected for ${patient.fullName} (demo)')),
              );
            },
            child: const Text('Order'),
          ),
        ],
      ),
    ),
  );
}

// -- Share Rx ----------------------------------------------------------------

List<String> _medicationsFor(Patient patient) {
  switch (patient.patientId) {
    case 'demo-patient-2': // Rohan Mehta — COPD exacerbation + IHD
      return ['Salbutamol inhaler PRN', 'Aspirin 75mg OD'];
    case 'demo-patient-3': // Priya Nair — post-appendectomy, no chronic conditions
      return ['Paracetamol 1g QDS PRN pain'];
    case 'demo-patient': // Jane Doe — pneumonia + T2DM + HTN
    default:
      return ['Amoxicillin-clavulanate 625mg TDS', 'Metformin 500mg BD', 'Amlodipine 5mg OD'];
  }
}

void _showShareRxDialog(BuildContext context, Patient patient) {
  final medications = _medicationsFor(patient);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Share Rx'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current medications:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final med in medications) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text('• $med')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            // ponytail: UI-only demo action — nothing is actually sent to a pharmacy system.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prescription shared with pharmacy (demo)')),
            );
          },
          child: const Text('Share'),
        ),
      ],
    ),
  );
}

// -- History tab --------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  final Patient patient;
  const _HistoryTab({required this.patient});

  static const _historyByPatientId = <String, List<String>>{
    'demo-patient': [
      'Day 1: Admitted with fever, cough and dyspnea — diagnosed pneumonia',
      'Day 2: Started IV antibiotics',
      'Day 3: NEWS2 escalation triggered, reviewed by on-call physician',
      'Day 4: Vitals stabilising, glycaemic control monitoring continued',
    ],
    'demo-patient-2': [
      'Day 1: Admitted with worsening breathlessness and productive cough — COPD exacerbation',
      'Day 2: Started nebulised bronchodilators and oral steroids',
      'Day 3: Cardiology review for stable ischemic heart disease, ECG unchanged',
      'Day 4: Weaning supplemental oxygen, mobilising with physiotherapy',
    ],
    'demo-patient-3': [
      'Day 1: Admitted for emergency laparoscopic appendectomy — uncomplicated procedure',
      'Day 2: Post-op day 1, pain controlled, tolerating oral fluids',
      'Day 3: Ambulating independently, surgical wound clean and dry',
      'Day 4: Planned for discharge review',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final entries = _historyByPatientId[patient.patientId] ?? const ['Day 1: Admitted for observation and initial workup'];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => AicuCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: AicuColors.tealBg,
            child: Text('${index + 1}', style: const TextStyle(color: AicuColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          title: Text(entries[index]),
        ),
      ),
    );
  }
}

// -- Vitals & Conditions tab ---------------------------------------------------

String _consciousnessLabel(String? code) => switch (code) {
      'A' => 'Alert',
      'C' => 'Confusion (new)',
      'V' => 'Responds to Voice',
      'P' => 'Responds to Pain',
      'U' => 'Unresponsive',
      _ => 'Unknown',
    };

class _VitalsConditionsTab extends StatelessWidget {
  final String patientId;
  final VitalsRepository vitalsRepository;
  final DemoPatientInfo info;
  const _VitalsConditionsTab({required this.patientId, required this.vitalsRepository, required this.info});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<Map<String, dynamic>?>(
          stream: vitalsRepository.watchLatestVitals(patientId),
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (data == null) {
              return const Text('No vitals recorded yet', style: TextStyle(color: Colors.black54));
            }
            final abnormal = data['news2Band'] == 'medium' || data['news2Band'] == 'high';
            final onO2 = data['onSupplementalOxygen'] == true || data['spo2Scale'] == 2;
            return AicuCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Latest Vitals', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  SizedBox(width: 150, child: VitalTile(label: 'Respiration Rate', value: '${data['respirationRate']} /min', abnormal: abnormal)),
                  SizedBox(
                    width: 150,
                    child: VitalTile(
                      label: 'SpO2',
                      value: '${data['spo2']}% (${onO2 ? 'Scale 2, on O2' : 'Scale 1, room air'})',
                      abnormal: abnormal,
                    ),
                  ),
                  SizedBox(width: 150, child: VitalTile(label: 'Systolic BP', value: '${data['systolicBp']} mmHg', abnormal: abnormal)),
                  SizedBox(width: 150, child: VitalTile(label: 'Pulse', value: '${data['pulse']} bpm', abnormal: abnormal)),
                  SizedBox(width: 150, child: VitalTile(label: 'Temperature', value: '${data['temperature']} °C', abnormal: abnormal)),
                  SizedBox(width: 150, child: VitalTile(label: 'Consciousness', value: _consciousnessLabel(data['consciousness'] as String?), abnormal: abnormal)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Pill(
                    'NEWS2: ${data['news2Score']}',
                    background: abnormal ? AicuColors.alertBg : AicuColors.tealBg,
                    foreground: abnormal ? AicuColors.alert : AicuColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Pill('Band: ${data['news2Band']}'),
                ]),
              ]),
            );
          },
        ),
        const SizedBox(height: 16),
        AicuCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Conditions & Comorbidities', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (final condition in info.conditions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.circle, size: 6, color: AicuColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(condition)),
                ]),
              ),
          ]),
        ),
      ],
    );
  }
}
