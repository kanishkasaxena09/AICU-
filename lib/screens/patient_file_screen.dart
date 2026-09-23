import 'package:flutter/material.dart';
import 'package:aicu/models/patient.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
import 'package:aicu/screens/doctor_demo_screen.dart';
import 'package:aicu/screens/nurse_demo_screen.dart';

class PatientFileScreen extends StatelessWidget {
  final Patient patient;
  final VitalsRepository vitalsRepository;
  final EscalationRepository escalationRepository;
  const PatientFileScreen({
    super.key,
    required this.patient,
    required this.vitalsRepository,
    required this.escalationRepository,
  });

  void _openVitalsEntry(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NurseDemoScreen(vitalsRepository: vitalsRepository, escalationRepository: escalationRepository),
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
            child: _HeaderCard(patient: patient),
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
                patientId: patient.patientId,
                vitalsRepository: vitalsRepository,
                onLogVitals: () => _openVitalsEntry(context),
                onOpenEscalations: () => _openEscalations(context),
              ),
              const Center(child: Text('Coming soon')),
              const Center(child: Text('Coming soon')),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Patient patient;
  const _HeaderCard({required this.patient});

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
              Text('${age}y F • Blood group B+', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill('Allergy: ${patient.allergies.join(', ')}', background: AicuColors.alertBg, foreground: AicuColors.alert, icon: Icons.error_outline),
          const Pill('Type 2 Diabetes'),
          const Pill('Stage 1 Hypertension'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Text('Attending: Dr. Mehta (Lead Physician, Internal Medicine)', style: TextStyle(fontSize: 12, color: Colors.black87))),
          TextButton(onPressed: () => showComingSoon(context, 'Attending Details'), child: const Text('Details')),
        ]),
      ]),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String patientId;
  final VitalsRepository vitalsRepository;
  final VoidCallback onLogVitals;
  final VoidCallback onOpenEscalations;
  const _OverviewTab({
    required this.patientId,
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
        _QuickActions(onLogVitals: onLogVitals),
        const SizedBox(height: 16),
        _CaseSummaryCard(),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, dynamic>?>(
          stream: vitalsRepository.watchLatestVitals(patientId),
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
  final VoidCallback onLogVitals;
  const _QuickActions({required this.onLogVitals});

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
      action(Icons.note_add_outlined, 'Add Note', () => showComingSoon(context, 'Add Note')),
      const SizedBox(width: 6),
      action(Icons.monitor_heart_outlined, 'Log Vitals', onLogVitals),
      const SizedBox(width: 6),
      action(Icons.biotech_outlined, 'Order Lab', () => showComingSoon(context, 'Order Lab')),
      const SizedBox(width: 6),
      action(Icons.ios_share, 'Share Rx', () => showComingSoon(context, 'Share Rx')),
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
