import 'package:aicu/models/vitals_reading.dart';

enum News2Band { none, low, medium, high }

class News2Result {
  final int aggregate;
  final News2Band band;
  final bool redFlag;
  const News2Result({required this.aggregate, required this.band, required this.redFlag});
}

class News2Engine {
  static News2Result score(VitalsReading v) {
    final scores = <int>[
      _respirationScore(v.respirationRate),
      _spo2Score(v),
      _bpScore(v.systolicBp),
      _pulseScore(v.pulse),
      _consciousnessScore(v.consciousness),
      _temperatureScore(v.temperature),
    ];
    final oxygenScore = v.onSupplementalOxygen ? 2 : 0;
    final aggregate = scores.fold(0, (a, b) => a + b) + oxygenScore;
    final redFlag = scores.any((s) => s == 3);

    News2Band band;
    if (aggregate >= 7) {
      band = News2Band.high;
    } else if (aggregate >= 5) {
      band = News2Band.medium;
    } else if (aggregate >= 1) {
      band = News2Band.low;
    } else {
      band = News2Band.none;
    }
    return News2Result(aggregate: aggregate, band: band, redFlag: redFlag);
  }

  static int _respirationScore(int rr) {
    if (rr >= 25) return 3;
    if (rr >= 21) return 2;
    if (rr >= 18) return 0;
    if (rr >= 12) return 0;
    if (rr >= 9) return 1;
    return 3; // <=8
  }

  static int _spo2Score(VitalsReading v) {
    if (v.spo2Scale == SpoScale.scale1) {
      if (v.spo2 >= 96) return 0;
      if (v.spo2 >= 94) return 1;
      if (v.spo2 >= 92) return 2;
      return 3; // <=91
    }
    // Scale 2 (hypercapnic respiratory failure, target 88-92)
    if (v.onSupplementalOxygen) {
      if (v.spo2 >= 97) return 3;
      if (v.spo2 >= 95) return 2;
      if (v.spo2 >= 93) return 1;
    }
    if (v.spo2 >= 93) return 0; // >=93 on air
    if (v.spo2 >= 88) return 0;
    if (v.spo2 >= 86) return 1;
    if (v.spo2 >= 84) return 2;
    return 3; // <=83
  }

  static int _bpScore(int sbp) {
    if (sbp >= 220) return 3;
    if (sbp >= 111) return 0;
    if (sbp >= 101) return 1;
    if (sbp >= 91) return 2;
    return 3; // <=90
  }

  static int _pulseScore(int pulse) {
    if (pulse >= 131) return 3;
    if (pulse >= 121) return 2;
    if (pulse >= 91) return 1;
    if (pulse >= 51) return 0;
    if (pulse >= 41) return 1;
    return 3; // <=40
  }

  static int _consciousnessScore(Consciousness c) =>
      c == Consciousness.alert ? 0 : 3;

  static int _temperatureScore(double t) {
    if (t >= 39.1) return 2;
    if (t >= 38.1) return 1;
    if (t >= 36.1) return 0;
    if (t >= 35.1) return 1;
    return 3; // <=35.0
  }
}
