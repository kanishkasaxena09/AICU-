import 'package:flutter/material.dart';
import 'package:aicu/models/escalation.dart';
import 'package:aicu/repositories/escalation_repository.dart';

class EscalationAlertScreen extends StatelessWidget {
  final Escalation escalation;
  final EscalationRepository escalationRepository;
  final String acknowledgedBy;

  const EscalationAlertScreen({
    super.key,
    required this.escalation,
    required this.escalationRepository,
    required this.acknowledgedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escalation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(escalation.sbarSummary['situation'] as String),
          Text(escalation.sbarSummary['recommendation'] as String),
          ElevatedButton(
            key: const Key('acknowledgeButton'),
            onPressed: () => escalationRepository.acknowledge(escalation.escalationId, acknowledgedBy),
            child: const Text('Acknowledge'),
          ),
        ]),
      ),
    );
  }
}
