import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:aicu/models/patient_note.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/repositories/escalation_repository.dart';
import 'package:aicu/repositories/patient_note_repository.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/screens/common/aicu_ui.dart';
import 'package:aicu/screens/nurse_demo_screen.dart' show demoPatient;
import 'package:aicu/services/news2_engine.dart';
import 'package:aicu/services/vitals_intake.dart';

// Speech-to-text capture (mic -> live transcript) is real, via the
// speech_to_text package. "Save as note" persists the live transcript to
// Firestore via PatientNoteRepository, and the notes list is a live stream
// of real patientNotes docs. "Extract & Save to Patient Record" is backed by
// a real Azure OpenAI chat-completions call that extracts structured vitals
// + a freeform clinical observation from the spoken transcript (see
// _extractAndSave below), and saves the result through the same
// recordVitals/escalation pipeline as the nurse demo screen — the API key
// is read from a compile-time --dart-define and never hardcoded.
const _azureOpenAiEndpoint =
    'https://info-mjgvb8f5-eastus2.openai.azure.com/openai/v1/chat/completions';
const _azureOpenAiApiKey = String.fromEnvironment('AZURE_OPENAI_API_KEY');

// Clinically-normal defaults used to fill in any vital not mentioned in the
// speech, so a partial utterance ("BP's 120 over 80") doesn't block saving —
// VitalsReading requires every field.
const _defaultRespirationRate = 16;
const _defaultSpo2 = 98;
const _defaultSystolicBp = 120;
const _defaultPulse = 75;
const _defaultTemperature = 36.5;

class VoiceAiScreen extends StatefulWidget {
  final String patientId;
  final String wardId;
  final PatientNoteRepository patientNoteRepository;
  final VitalsRepository vitalsRepository;
  final EscalationRepository escalationRepository;
  final String currentUserId;
  final String currentUserRole;

  const VoiceAiScreen({
    super.key,
    required this.patientId,
    required this.wardId,
    required this.patientNoteRepository,
    required this.vitalsRepository,
    required this.escalationRepository,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<VoiceAiScreen> createState() => _VoiceAiScreenState();
}

class _VoiceAiScreenState extends State<VoiceAiScreen> {
  final _speech = SpeechToText();
  bool _listening = false;
  String _liveTranscript = '';

  bool _aiLoading = false;
  _ExtractionSummary? _extractionSummary;

  @override
  void dispose() {
    if (_listening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${error.errorMsg}')),
        );
        setState(() => _listening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );

    if (!available) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice dictation.')),
      );
      return;
    }

    setState(() {
      _listening = true;
      _liveTranscript = '';
    });
    await _speech.listen(
      onResult: (result) => setState(() => _liveTranscript = result.recognizedWords),
    );
  }

  Future<void> _saveAsNote() async {
    if (_liveTranscript.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    await widget.patientNoteRepository.createNote(
      patientId: widget.patientId,
      wardId: widget.wardId,
      authorId: widget.currentUserId,
      authorRole: widget.currentUserRole,
      transcript: _liveTranscript,
    );
    messenger.showSnackBar(const SnackBar(content: Text('Note saved')));
  }

  Future<void> _extractAndSave() async {
    if (_liveTranscript.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);

    if (_azureOpenAiApiKey.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('AI extraction not configured — missing API key')),
      );
      return;
    }

    setState(() {
      _aiLoading = true;
      _extractionSummary = null;
    });

    try {
      final systemPrompt =
          'You are a clinical data extraction assistant. Given a spoken clinical observation '
          'about a patient, extract any vital signs mentioned and any other clinical '
          'observations. Respond with ONLY a JSON object, no other text, matching exactly this '
          'shape: {"respirationRate": number|null, "spo2": number|null, "systolicBp": '
          'number|null, "pulse": number|null, "temperature": number|null, "consciousness": '
          '"alert"|"confusionNew"|"voice"|"pain"|"unresponsive"|null, "conditions": '
          'string|null}. Use null for any field not mentioned in the speech. "conditions" '
          'should be a brief clinical summary of any non-vital-sign observations mentioned '
          '(symptoms, patient state, complaints) — null if none. Patient: '
          '${demoPatient.fullName}, diagnosis: ${demoPatient.diagnosis}, allergies: '
          '${demoPatient.allergies.join(', ')}.';

      final response = await http
          .post(
            Uri.parse(_azureOpenAiEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'api-key': _azureOpenAiApiKey,
            },
            body: jsonEncode({
              'model': 'gpt-5.4',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': _liveTranscript},
              ],
              'max_tokens': 400,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode != 200) {
        messenger.showSnackBar(
          SnackBar(content: Text('AI request failed (${response.statusCode})')),
        );
        setState(() => _aiLoading = false);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (data['choices'] as List)[0]['message']['content'] as String;

      Map<String, dynamic> extracted;
      try {
        extracted = jsonDecode(_stripCodeFences(content)) as Map<String, dynamic>;
      } catch (_) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not extract structured data from response')),
        );
        setState(() => _aiLoading = false);
        return;
      }

      await _saveExtractedData(extracted, messenger);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('AI request failed — check your connection and try again')));
      setState(() => _aiLoading = false);
    }
  }

  String _stripCodeFences(String content) {
    var text = content.trim();
    if (text.startsWith('```')) {
      text = text.substring(3);
      if (text.startsWith('json')) text = text.substring(4);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  Future<void> _saveExtractedData(Map<String, dynamic> extracted, ScaffoldMessengerState messenger) async {
    final respirationRate = extracted['respirationRate'] as num?;
    final spo2 = extracted['spo2'] as num?;
    final systolicBp = extracted['systolicBp'] as num?;
    final pulse = extracted['pulse'] as num?;
    final temperature = extracted['temperature'] as num?;
    final consciousness = extracted['consciousness'] as String?;
    final conditions = extracted['conditions'] as String?;

    final hasVitals = respirationRate != null ||
        spo2 != null ||
        systolicBp != null ||
        pulse != null ||
        temperature != null ||
        consciousness != null;
    final hasConditions = conditions != null && conditions.trim().isNotEmpty;

    if (!hasVitals && !hasConditions) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No clinical data recognized in that speech — try again.')),
      );
      setState(() => _aiLoading = false);
      return;
    }

    News2Result? result;
    VitalsReading? reading;
    if (hasVitals) {
      reading = VitalsReading(
        respirationRate: respirationRate?.toInt() ?? _defaultRespirationRate,
        spo2: spo2?.toInt() ?? _defaultSpo2,
        spo2Scale: SpoScale.scale1,
        onSupplementalOxygen: false,
        systolicBp: systolicBp?.toInt() ?? _defaultSystolicBp,
        pulse: pulse?.toInt() ?? _defaultPulse,
        consciousness: _parseConsciousness(consciousness),
        temperature: temperature?.toDouble() ?? _defaultTemperature,
      );
      result = await widget.vitalsRepository.recordVitals(
        patientId: widget.patientId,
        wardId: widget.wardId,
        recordedBy: widget.currentUserId,
        reading: reading,
      );
      if (!mounted) return;
      await handleVitalsSubmission(
        context: context,
        escalationRepository: widget.escalationRepository,
        patient: demoPatient,
        reading: reading,
        result: result,
        recordedBy: widget.currentUserId,
      );
    }

    if (hasConditions) {
      await widget.patientNoteRepository.createNote(
        patientId: widget.patientId,
        wardId: widget.wardId,
        authorId: widget.currentUserId,
        authorRole: widget.currentUserRole,
        transcript: conditions.trim(),
      );
    }

    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      _extractionSummary = _ExtractionSummary(
        respirationRate: respirationRate?.toInt(),
        spo2: spo2?.toInt(),
        systolicBp: systolicBp?.toInt(),
        pulse: pulse?.toInt(),
        temperature: temperature?.toDouble(),
        consciousness: consciousness,
        conditions: hasConditions ? conditions.trim() : null,
        news2Result: result,
      );
    });
  }

  Consciousness _parseConsciousness(String? value) => switch (value) {
        'confusionNew' => Consciousness.confusionNew,
        'voice' => Consciousness.voice,
        'pain' => Consciousness.pain,
        'unresponsive' => Consciousness.unresponsive,
        _ => Consciousness.alert,
      };

  Future<void> _editNote(PatientNote note) async {
    final controller = TextEditingController(text: note.transcript);
    final newTranscript = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit note'),
        content: TextField(controller: controller, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTranscript == null || newTranscript.trim().isEmpty) return;
    await widget.patientNoteRepository.editNote(
      noteId: note.noteId,
      editorId: widget.currentUserId,
      editorRole: widget.currentUserRole,
      newTranscript: newTranscript.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note updated')));
  }

  bool _canEdit(PatientNote note) {
    if (widget.currentUserRole == 'doctor') return true;
    return note.authorId == widget.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AicuColors.background,
      appBar: aicuAppBar(context, 'Voice Ai'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(),
          const SizedBox(height: 16),
          _PatientContextChip(),
          const SizedBox(height: 24),
          _MicButton(listening: _listening, onTap: _toggleMic),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _listening ? 'Listening to Dictation...' : 'Tap mic to pause or switch to typing',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          _Waveform(active: _listening),
          const SizedBox(height: 20),
          _TranscriptCard(listening: _listening, transcript: _liveTranscript),
          if (_listening) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _liveTranscript.trim().isEmpty || _aiLoading ? null : _extractAndSave,
                  icon: _aiLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_aiLoading ? 'Extracting...' : 'Extract & Save to Patient Record'),
                  style: ElevatedButton.styleFrom(backgroundColor: AicuColors.primary, foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: _liveTranscript.trim().isEmpty ? null : _saveAsNote,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save as note'),
                  style: ElevatedButton.styleFrom(backgroundColor: AicuColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_extractionSummary != null) _ExtractionSummaryCard(summary: _extractionSummary!),
          const SizedBox(height: 24),
          const Text('Patient notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<List<PatientNote>>(
            stream: widget.patientNoteRepository.watchNotes(widget.patientId),
            builder: (context, snapshot) {
              final notes = snapshot.data ?? const <PatientNote>[];
              if (notes.isEmpty) {
                return const Text('No notes yet.', style: TextStyle(color: Colors.black54));
              }
              return Column(
                children: notes
                    .map((note) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NoteCard(
                            note: note,
                            canEdit: _canEdit(note),
                            onEdit: () => _editNote(note),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final PatientNote note;
  final bool canEdit;
  final VoidCallback onEdit;
  const _NoteCard({required this.note, required this.canEdit, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pill(note.authorRole == 'doctor' ? 'Doctor' : 'Nurse'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note.createdAt != null ? note.createdAt.toString() : 'Just now',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AicuColors.primary),
              onPressed: onEdit,
              tooltip: 'Edit note',
            ),
        ]),
        const SizedBox(height: 8),
        Text(note.transcript, style: const TextStyle(color: Colors.black87)),
        if (note.lastEditedBy != null) ...[
          const SizedBox(height: 8),
          Text(
            'Edited by ${note.lastEditedByRole == 'doctor' ? 'Dr.' : 'Nurse'} ${note.lastEditedBy}',
            style: const TextStyle(fontSize: 11, color: AicuColors.alert, fontStyle: FontStyle.italic),
          ),
        ],
      ]),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AicuColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Clinical Voice Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
            child: const Text('WhisperMed v4.2 Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        const Text('Hands-free clinical intelligence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        const Text(
          'Continuous speech recognition tuned for Indian medical pharmacology & diagnostics.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ]),
    );
  }
}

class _PatientContextChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Row(children: [
        const Icon(Icons.favorite, color: AicuColors.alert, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Text('Jane Doe (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Pill('B+'),
            ]),
            const Text('P-10245 • 45y F • Pneumonia', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        IconButton(icon: const Icon(Icons.swap_horiz, color: AicuColors.primary), onPressed: () => showComingSoon(context, 'Switch Patient')),
      ]),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool listening;
  final VoidCallback onTap;
  const _MicButton({required this.listening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: listening ? AicuColors.alert : AicuColors.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: (listening ? AicuColors.alert : AicuColors.primary).withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 4)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(listening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 36),
            const SizedBox(height: 4),
            Text(listening ? 'LIVE' : 'TAP', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  final bool active;
  const _Waveform({required this.active});

  @override
  Widget build(BuildContext context) {
    final heights = [8.0, 16.0, 24.0, 14.0, 28.0, 12.0, 20.0, 10.0, 18.0, 8.0];
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: heights
            .map((h) => Container(
                  width: 4,
                  height: active ? h : 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? AicuColors.primary : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final bool listening;
  final String transcript;
  const _TranscriptCard({required this.listening, required this.transcript});

  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.subtitles_outlined, size: 18, color: AicuColors.primary),
          SizedBox(width: 8),
          Text('Live Speech Transcript', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        Text(
          !listening
              ? 'No active dictation. Tap the mic to start.'
              : transcript.trim().isEmpty
                  ? 'Listening... say something'
                  : '"$transcript"',
          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.refresh, size: 14, color: Colors.black45),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              listening ? 'AI Query Interpreted — Synthesizing Clinical Card...' : 'Idle',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Clear')),
        ]),
      ]),
    );
  }
}

/// Result of one _extractAndSave() call: whatever the AI extracted (and
/// null for anything not mentioned), plus the NEWS2 result if vitals were
/// saved. Drives _ExtractionSummaryCard below.
class _ExtractionSummary {
  final int? respirationRate;
  final int? spo2;
  final int? systolicBp;
  final int? pulse;
  final double? temperature;
  final String? consciousness;
  final String? conditions;
  final News2Result? news2Result;

  const _ExtractionSummary({
    this.respirationRate,
    this.spo2,
    this.systolicBp,
    this.pulse,
    this.temperature,
    this.consciousness,
    this.conditions,
    this.news2Result,
  });
}

class _ExtractionSummaryCard extends StatelessWidget {
  final _ExtractionSummary summary;
  const _ExtractionSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (summary.respirationRate != null) VitalTile(label: 'Respiration Rate', value: '${summary.respirationRate} /min'),
      if (summary.spo2 != null) VitalTile(label: 'SpO2', value: '${summary.spo2}%'),
      if (summary.systolicBp != null) VitalTile(label: 'Systolic BP', value: '${summary.systolicBp} mmHg'),
      if (summary.pulse != null) VitalTile(label: 'Pulse', value: '${summary.pulse} bpm'),
      if (summary.temperature != null) VitalTile(label: 'Temperature', value: '${summary.temperature} °C'),
      if (summary.consciousness != null) VitalTile(label: 'Consciousness', value: summary.consciousness!),
    ];

    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Expanded(child: Text('Extracted & Saved', style: TextStyle(fontWeight: FontWeight.bold))),
          Pill('AI Extracted'),
        ]),
        const SizedBox(height: 10),
        if (tiles.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: tiles.map((t) => SizedBox(width: 150, child: t)).toList()),
        if (summary.news2Result != null) ...[
          const SizedBox(height: 10),
          Pill('NEWS2 ${summary.news2Result!.aggregate} (${summary.news2Result!.band.name})'),
        ],
        if (summary.conditions != null) ...[
          const SizedBox(height: 10),
          Text('Observation note: ${summary.conditions}', style: const TextStyle(color: Colors.black87)),
        ],
        const SizedBox(height: 10),
        Text('Saved to ${demoPatient.fullName}', style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
