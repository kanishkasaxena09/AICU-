enum SpoScale { scale1, scale2 }
enum Consciousness { alert, confusionNew, voice, pain, unresponsive }

class VitalsReading {
  final int respirationRate;
  final int spo2;
  final SpoScale spo2Scale;
  final bool onSupplementalOxygen;
  final int systolicBp;
  final int pulse;
  final Consciousness consciousness;
  final double temperature;

  const VitalsReading({
    required this.respirationRate,
    required this.spo2,
    required this.spo2Scale,
    required this.onSupplementalOxygen,
    required this.systolicBp,
    required this.pulse,
    required this.consciousness,
    required this.temperature,
  });
}
