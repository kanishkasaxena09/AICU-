// test/screens/vitals_entry_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/vitals_entry_screen.dart';
import 'package:aicu/services/news2_engine.dart';

void main() {
  testWidgets('submitting vitals calls onRecorded with the NEWS2 result', (tester) async {
    News2Result? captured;
    await tester.pumpWidget(MaterialApp(
      home: VitalsEntryScreen(
        patientId: 'p1',
        wardId: 'w1',
        recordedBy: 'nurse-u1',
        vitalsRepository: VitalsRepository(firestore: FakeFirebaseFirestore()),
        onRecorded: (r) => captured = r,
      ),
    ));

    await tester.enterText(find.byKey(const Key('respirationRateField')), '16');
    await tester.enterText(find.byKey(const Key('spo2Field')), '98');
    await tester.enterText(find.byKey(const Key('systolicBpField')), '120');
    await tester.enterText(find.byKey(const Key('pulseField')), '75');
    await tester.enterText(find.byKey(const Key('temperatureField')), '36.5');
    await tester.tap(find.byKey(const Key('submitVitalsButton')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.aggregate, 0);
  });
}
