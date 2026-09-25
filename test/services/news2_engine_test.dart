import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/services/news2_engine.dart';

VitalsReading normal({
  int respirationRate = 16,
  int spo2 = 98,
  SpoScale spo2Scale = SpoScale.scale1,
  bool onSupplementalOxygen = false,
  int systolicBp = 120,
  int pulse = 75,
  Consciousness consciousness = Consciousness.alert,
  double temperature = 36.5,
}) =>
    VitalsReading(
      respirationRate: respirationRate,
      spo2: spo2,
      spo2Scale: spo2Scale,
      onSupplementalOxygen: onSupplementalOxygen,
      systolicBp: systolicBp,
      pulse: pulse,
      consciousness: consciousness,
      temperature: temperature,
    );

void main() {
  group('News2Engine.score', () {
    test('all-normal vitals aggregate to 0, band none, no red flag', () {
      final r = News2Engine.score(normal());
      expect(r.aggregate, 0);
      expect(r.band, News2Band.none);
      expect(r.redFlag, false);
    });

    test('respiration rate >=25 scores 3 and is a red flag', () {
      final r = News2Engine.score(normal(respirationRate: 27));
      expect(r.aggregate, 3);
      expect(r.redFlag, true);
      expect(r.band, News2Band.low);
    });

    test('SpO2 Scale 1: 92-93 scores 2, <=91 scores 3', () {
      expect(News2Engine.score(normal(spo2: 93, spo2Scale: SpoScale.scale1)).aggregate, 2);
      expect(News2Engine.score(normal(spo2: 91, spo2Scale: SpoScale.scale1)).redFlag, true);
    });

    test('SpO2 Scale 2 on oxygen: 88-92 scores 0, >=97 on O2 scores 3', () {
      final onTarget = normal(spo2: 90, spo2Scale: SpoScale.scale2, onSupplementalOxygen: true);
      expect(News2Engine.score(onTarget).aggregate, 2); // 0 for spo2 + 2 for supplemental O2
      final tooHigh = normal(spo2: 97, spo2Scale: SpoScale.scale2, onSupplementalOxygen: true);
      expect(News2Engine.score(tooHigh).redFlag, true);
    });

    test('supplemental oxygen adds 2 on top of the SpO2 scale score', () {
      final onO2 = News2Engine.score(normal(spo2: 98, onSupplementalOxygen: true));
      expect(onO2.aggregate, 2); // 0 (SpO2 96+) + 2 (O2)
    });

    test('new confusion scores 3, same as voice/pain/unresponsive', () {
      expect(News2Engine.score(normal(consciousness: Consciousness.confusionNew)).aggregate, 3);
      expect(News2Engine.score(normal(consciousness: Consciousness.voice)).aggregate, 3);
      expect(News2Engine.score(normal(consciousness: Consciousness.pain)).aggregate, 3);
      expect(News2Engine.score(normal(consciousness: Consciousness.unresponsive)).aggregate, 3);
    });

    test('a single parameter scoring 3 sets redFlag even if aggregate stays under 5', () {
      final r = News2Engine.score(normal(temperature: 34.0)); // <=35.0 -> 3
      expect(r.aggregate, 3);
      expect(r.redFlag, true);
      expect(r.band, News2Band.low);
    });

    test('aggregate band boundaries: 1-4 low, 5-6 medium, 7+ high', () {
      expect(News2Engine.score(normal(pulse: 125, respirationRate: 22)).band, News2Band.low);
      expect(News2Engine.score(normal(pulse: 125, respirationRate: 26)).band, News2Band.medium);
      expect(
        News2Engine.score(normal(pulse: 135, respirationRate: 26, spo2: 90)).band,
        News2Band.high,
      );
    });

    test('systolic BP extremes both score 3', () {
      expect(News2Engine.score(normal(systolicBp: 225)).redFlag, true);
      expect(News2Engine.score(normal(systolicBp: 85)).redFlag, true);
      expect(News2Engine.score(normal(systolicBp: 105)).aggregate, 1);
    });
  });
}
