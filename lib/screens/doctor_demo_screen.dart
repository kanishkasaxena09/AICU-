import 'package:flutter/material.dart';
import 'package:aicu/models/escalation.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/screens/escalation_alert_screen.dart';

const _demoWardId = 'demo-ward';

class DoctorDemoScreen extends StatelessWidget {
  final EscalationRepository escalationRepository;
  const DoctorDemoScreen({super.key, required this.escalationRepository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open escalations')),
      body: StreamBuilder<List<Escalation>>(
        stream: escalationRepository.watchOpenEscalations(_demoWardId),
        builder: (context, snapshot) {
          final escalations = snapshot.data ?? const [];
          if (escalations.isEmpty) {
            return const Center(child: Text('No open escalations'));
          }
          return ListView.builder(
            itemCount: escalations.length,
            itemBuilder: (context, index) {
              final e = escalations[index];
              return ListTile(
                title: Text(e.sbarSummary['situation'] as String? ?? 'Escalation'),
                subtitle: Text('NEWS2 ${e.news2Score} (${e.news2Band})'),
                tileColor: Colors.red.withValues(alpha: 0.08),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EscalationAlertScreen(
                      escalation: e,
                      escalationRepository: escalationRepository,
                      acknowledgedBy: 'demo-doctor',
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
