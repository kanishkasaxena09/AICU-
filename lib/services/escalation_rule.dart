import 'package:aicu/services/news2_engine.dart';

class EscalationRule {
  static bool shouldEscalate(News2Result result) {
    return result.redFlag ||
        result.band == News2Band.medium ||
        result.band == News2Band.high;
  }
}
