import 'package:cloud_firestore/cloud_firestore.dart';

class Escalation {
  final String escalationId;
  final String patientId;
  final String wardId;
  final int news2Score;
  final String news2Band;
  final String raisedBy;
  final DateTime? raisedAt;
  final Map<String, dynamic> sbarSummary;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  const Escalation({
    required this.escalationId,
    required this.patientId,
    required this.wardId,
    required this.news2Score,
    required this.news2Band,
    required this.raisedBy,
    required this.raisedAt,
    required this.sbarSummary,
    required this.acknowledgedBy,
    required this.acknowledgedAt,
  });

  factory Escalation.fromMap(String id, Map<String, dynamic> map) => Escalation(
        escalationId: id,
        patientId: map['patientId'] as String,
        wardId: map['wardId'] as String,
        news2Score: map['news2Score'] as int,
        news2Band: map['news2Band'] as String,
        raisedBy: map['raisedBy'] as String,
        raisedAt: (map['raisedAt'] as Timestamp?)?.toDate(),
        sbarSummary: Map<String, dynamic>.from(map['sbarSummary'] as Map),
        acknowledgedBy: map['acknowledgedBy'] as String?,
        acknowledgedAt: (map['acknowledgedAt'] as Timestamp?)?.toDate(),
      );
}
