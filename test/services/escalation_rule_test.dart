import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/services/escalation_rule.dart';
import 'package:aicu/services/news2_engine.dart';

News2Result result({required News2Band band, bool redFlag = false, int aggregate = 0}) =>
    News2Result(aggregate: aggregate, band: band, redFlag: redFlag);

void main() {
  group('EscalationRule.shouldEscalate', () {
    test('none band, no red flag -> false', () {
      expect(EscalationRule.shouldEscalate(result(band: News2Band.none)), false);
    });
    test('low band, no red flag -> false', () {
      expect(EscalationRule.shouldEscalate(result(band: News2Band.low, aggregate: 3)), false);
    });
    test('low band with a red flag -> true (urgent review regardless of aggregate)', () {
      expect(EscalationRule.shouldEscalate(result(band: News2Band.low, aggregate: 3, redFlag: true)), true);
    });
    test('medium band -> true', () {
      expect(EscalationRule.shouldEscalate(result(band: News2Band.medium, aggregate: 5)), true);
    });
    test('high band -> true', () {
      expect(EscalationRule.shouldEscalate(result(band: News2Band.high, aggregate: 8)), true);
    });
  });
}
