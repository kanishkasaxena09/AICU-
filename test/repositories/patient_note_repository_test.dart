// test/repositories/patient_note_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aicu/repositories/patient_note_repository.dart';

void main() {
  test('createNote writes a doc, watchNotes streams it', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = PatientNoteRepository(firestore: firestore);

    final id = await repo.createNote(
      patientId: 'p1', wardId: 'w1', authorId: 'demo-nurse', authorRole: 'nurse',
      transcript: 'Patient resting comfortably.',
    );
    expect(id, isNotEmpty);

    final notes = await repo.watchNotes('p1').first;
    expect(notes.length, 1);
    expect(notes.first.transcript, 'Patient resting comfortably.');
    expect(notes.first.lastEditedBy, isNull);
  });

  test('editNote sets lastEditedBy/Role and updatedAt', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = PatientNoteRepository(firestore: firestore);
    final id = await repo.createNote(
      patientId: 'p1', wardId: 'w1', authorId: 'demo-nurse', authorRole: 'nurse',
      transcript: 'Original note.',
    );

    await repo.editNote(noteId: id, editorId: 'demo-doctor', editorRole: 'doctor', newTranscript: 'Revised note.');

    final notes = await repo.watchNotes('p1').first;
    expect(notes.first.transcript, 'Revised note.');
    expect(notes.first.lastEditedBy, 'demo-doctor');
    expect(notes.first.lastEditedByRole, 'doctor');
  });
}
