class SbarSummary {
  final String situation;
  final String background;
  final String assessment;
  final String recommendation;
  const SbarSummary({
    required this.situation,
    required this.background,
    required this.assessment,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() => {
        'situation': situation,
        'background': background,
        'assessment': assessment,
        'recommendation': recommendation,
      };
}
