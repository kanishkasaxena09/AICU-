import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aicu/models/patient_note.dart';

class PatientNoteRepository {
  final FirebaseFirestore firestore;
  PatientNoteRepository({required this.firestore});

  Future<String> createNote({
    required String patientId,
    required String wardId,
    required String authorId,
    required String authorRole,
    required String transcript,
  }) async {
    final doc = await firestore.collection('patientNotes').add({
      'patientId': patientId,
      'wardId': wardId,
      'authorId': authorId,
      'authorRole': authorRole,
      'transcript': transcript,
      'createdAt': FieldValue.serverTimestamp(),
      'lastEditedBy': null,
      'lastEditedByRole': null,
      'updatedAt': null,
    });
    return doc.id;
  }

  Future<void> editNote({
    required String noteId,
    required String editorId,
    required String editorRole,
    required String newTranscript,
  }) async {
    await firestore.collection('patientNotes').doc(noteId).update({
      'transcript': newTranscript,
      'lastEditedBy': editorId,
      'lastEditedByRole': editorRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ponytail: sorted client-side to avoid needing a composite Firestore
  // index for patientId equality + createdAt ordering.
  Stream<List<PatientNote>> watchNotes(String patientId) {
    return firestore
        .collection('patientNotes')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final notes = snap.docs.map((d) => PatientNote.fromMap(d.id, d.data())).toList();
      notes.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return notes;
    });
  }
}
