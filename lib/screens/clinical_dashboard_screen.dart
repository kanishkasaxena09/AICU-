import 'package:flutter/material.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
import 'package:aicu/screens/nurse_demo_screen.dart';
import 'package:aicu/screens/patient_file_screen.dart';

class ClinicalDashboardScreen extends StatelessWidget {
  final VitalsRepository vitalsRepository;
  final EscalationRepository escalationRepository;
  const ClinicalDashboardScreen({super.key, required this.vitalsRepository, required this.escalationRepository});

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
          const SizedBox(height: 12),
          _PatientResultCard(onSelect: () => _openPatientFile(context)),
          const SizedBox(height: 16),
          _QuickActionsRow(),
          const SizedBox(height: 16),
          const Text('Ward Patients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _PatientListCard(vitalsRepository: vitalsRepository, onSelect: () => _openPatientFile(context)),
        ],
      ),
    );
  }

  void _openPatientFile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PatientFileScreen(
        patient: demoPatient,
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
            onPressed: () => showComingSoon(context, 'Review Notes'),
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
        child: IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () {}),
      ),
    ]);
  }
}

class _PatientResultCard extends StatelessWidget {
  final VoidCallback onSelect;
  const _PatientResultCard({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Row(children: [
        const CircleAvatar(radius: 24, backgroundColor: AicuColors.tealBg, child: Text('JD', style: TextStyle(color: AicuColors.primaryDark, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Text('Jane Doe (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Pill('P-10245'),
            ]),
            const SizedBox(height: 4),
            const Pill('45y F • B+', background: AicuColors.background, foreground: Colors.black87),
            const SizedBox(height: 4),
            const Text('Diagnosis: Pneumonia', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ),
        TextButton(onPressed: onSelect, child: const Text('Select →')),
      ]),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: () => showComingSoon(context, label),
          icon: Icon(icon, size: 18, color: AicuColors.primary),
          label: Text(label, style: const TextStyle(color: AicuColors.primary, fontSize: 12), overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AicuColors.primary), padding: const EdgeInsets.symmetric(vertical: 10)),
        ),
      );
    }

    return Row(children: [
      action(Icons.person_add_alt_1, 'Add Patient'),
      const SizedBox(width: 8),
      action(Icons.edit_note, 'Write Rx'),
      const SizedBox(width: 8),
      action(Icons.science_outlined, 'New Lab Order'),
    ]);
  }
}

class _PatientListCard extends StatelessWidget {
  final VitalsRepository vitalsRepository;
  final VoidCallback onSelect;
  const _PatientListCard({required this.vitalsRepository, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 22, backgroundColor: AicuColors.tealBg, child: Text('JD', style: TextStyle(color: AicuColors.primaryDark, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Text('Jane Doe (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Pill('P-10245'),
              ]),
              const SizedBox(height: 2),
              const Text('45y F • Room 4B • Bed 2', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
          const Pill('Inpatient Active'),
        ]),
        const SizedBox(height: 10),
        Row(children: const [
          Icon(Icons.favorite, size: 14, color: AicuColors.alert),
          SizedBox(width: 4),
          Text('Diagnosis: Pneumonia', style: TextStyle(fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        const Pill('Attending: Dr. Mehta', background: AicuColors.background, foreground: Colors.black87),
        const SizedBox(height: 10),
        StreamBuilder<Map<String, dynamic>?>(
          stream: vitalsRepository.watchLatestVitals(demoPatient.patientId),
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
