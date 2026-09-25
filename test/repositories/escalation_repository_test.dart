// test/repositories/escalation_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/models/sbar_summary.dart';
import 'package:aicu/repositories/escalation_repository.dart';

void main() {
  test('raiseEscalation writes a doc, watchOpenEscalations streams it', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = EscalationRepository(firestore: firestore);
    const sbar = SbarSummary(situation: 's', background: 'b', assessment: 'a', recommendation: 'r');

    final id = await repo.raiseEscalation(
      patientId: 'p1', wardId: 'w1', triggeredByVitalId: 'v1',
      news2Score: 6, news2Band: 'medium', raisedBy: 'nurse-u1', sbarSummary: sbar,
    );
    expect(id, isNotEmpty);

    final open = await repo.watchOpenEscalations('w1').first;
    expect(open.length, 1);
    expect(open.first.patientId, 'p1');
    expect(open.first.acknowledgedAt, isNull);
  });

  test('watchOpenEscalations excludes acknowledged escalations', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('escalations').add({
      'patientId': 'p1', 'wardId': 'w1', 'acknowledgedAt': DateTime.now(),
      'raisedAt': DateTime.now(), 'news2Score': 6, 'news2Band': 'medium',
      'triggeredByVitalId': 'v1', 'raisedBy': 'nurse-u1',
      'sbarSummary': {'situation': 's', 'background': 'b', 'assessment': 'a', 'recommendation': 'r'},
    });
    final repo = EscalationRepository(firestore: firestore);
    final open = await repo.watchOpenEscalations('w1').first;
    expect(open, isEmpty);
  });

  test('acknowledge sets acknowledgedBy/At and a non-negative response time', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = EscalationRepository(firestore: firestore);
    const sbar = SbarSummary(situation: 's', background: 'b', assessment: 'a', recommendation: 'r');
    final id = await repo.raiseEscalation(
      patientId: 'p1', wardId: 'w1', triggeredByVitalId: 'v1',
      news2Score: 6, news2Band: 'medium', raisedBy: 'nurse-u1', sbarSummary: sbar,
    );

    final responseTime = await repo.acknowledge(id, 'doctor-u1');

    expect(responseTime, greaterThanOrEqualTo(0));
    final doc = await firestore.collection('escalations').doc(id).get();
    expect(doc.data()!['acknowledgedBy'], 'doctor-u1');
    expect(doc.data()!['responseTimeSeconds'], responseTime);
  });
}
