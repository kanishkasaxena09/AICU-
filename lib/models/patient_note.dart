import 'package:cloud_firestore/cloud_firestore.dart';

class PatientNote {
  final String noteId;
  final String patientId;
  final String wardId;
  final String authorId;
  final String authorRole;
  final String transcript;
  final DateTime? createdAt;
  final String? lastEditedBy;
  final String? lastEditedByRole;
  final DateTime? updatedAt;

  const PatientNote({
    required this.noteId,
    required this.patientId,
    required this.wardId,
    required this.authorId,
    required this.authorRole,
    required this.transcript,
    required this.createdAt,
    required this.lastEditedBy,
    required this.lastEditedByRole,
    required this.updatedAt,
  });

  factory PatientNote.fromMap(String id, Map<String, dynamic> map) => PatientNote(
        noteId: id,
        patientId: map['patientId'] as String,
        wardId: map['wardId'] as String,
        authorId: map['authorId'] as String,
        authorRole: map['authorRole'] as String,
        transcript: map['transcript'] as String,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        lastEditedBy: map['lastEditedBy'] as String?,
        lastEditedByRole: map['lastEditedByRole'] as String?,
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'patientId': patientId,
        'wardId': wardId,
        'authorId': authorId,
        'authorRole': authorRole,
        'transcript': transcript,
        'createdAt': createdAt,
        'lastEditedBy': lastEditedBy,
        'lastEditedByRole': lastEditedByRole,
        'updatedAt': updatedAt,
      };
}
