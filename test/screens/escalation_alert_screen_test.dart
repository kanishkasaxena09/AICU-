import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:aicu/models/escalation.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/screens/escalation_alert_screen.dart';

void main() {
  testWidgets('tapping acknowledge calls the repository and shows response time', (tester) async {
    final firestore = FakeFirebaseFirestore();
    final repo = EscalationRepository(firestore: firestore);
    const escalation = Escalation(
      escalationId: 'e1', patientId: 'p1', wardId: 'w1', news2Score: 6, news2Band: 'medium',
      raisedBy: 'nurse-u1', raisedAt: null,
      sbarSummary: {'situation': 'Jane Doe, NEWS2 6', 'background': 'b', 'assessment': 'a', 'recommendation': 'r'},
      acknowledgedBy: null, acknowledgedAt: null,
    );
    await firestore.collection('escalations').doc('e1').set({
      'patientId': 'p1', 'wardId': 'w1', 'news2Score': 6, 'news2Band': 'medium',
      'raisedBy': 'nurse-u1', 'raisedAt': DateTime.now(),
      'sbarSummary': escalation.sbarSummary, 'acknowledgedBy': null, 'acknowledgedAt': null,
    });

    await tester.pumpWidget(MaterialApp(
      home: EscalationAlertScreen(escalation: escalation, escalationRepository: repo, acknowledgedBy: 'doctor-u1'),
    ));

    expect(find.textContaining('Jane Doe, NEWS2 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('acknowledgeButton')));
    await tester.pumpAndSettle();

    final doc = await firestore.collection('escalations').doc('e1').get();
    expect(doc.data()!['acknowledgedBy'], 'doctor-u1');
  });
}
