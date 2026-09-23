import 'package:flutter/material.dart';
import 'package:aicu/screens/common/aicu_ui.dart';

// ponytail: UI mock only. There is no speech_to_text / audio capture / LLM
// integration in this project. The mic button just flips a local boolean
// and swaps in a hardcoded transcript + response string. Real speech-to-text
// and AI inference are future work — do not mistake this for working
// functionality.
class VoiceAiScreen extends StatefulWidget {
  const VoiceAiScreen({super.key});

  @override
  State<VoiceAiScreen> createState() => _VoiceAiScreenState();
}

class _VoiceAiScreenState extends State<VoiceAiScreen> {
  bool _listening = false;

  static const _sampleTranscript = "Show patient Jane Doe's recent vitals and NEWS2 trend.";
  static const _sampleResponse =
      'NEWS2 trend for Jane Doe (Demo) over the last 24h shows two escalations above threshold, '
      'both acknowledged within target response time. Current band: Low-Medium.';

  void _toggleMic() => setState(() => _listening = !_listening);

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
          _TranscriptCard(listening: _listening, transcript: _sampleTranscript),
          const SizedBox(height: 16),
          if (_listening) _ClinicalResponseCard(response: _sampleResponse),
        ],
      ),
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
          listening ? '"$transcript"\n— Dr. Mehta' : 'No active dictation. Tap the mic to start.',
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

class _ClinicalResponseCard extends StatelessWidget {
  final String response;
  const _ClinicalResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Expanded(child: Text('Clinical Response', style: TextStyle(fontWeight: FontWeight.bold))),
          Pill('Triage Level: Low-Medium'),
        ]),
        const SizedBox(height: 10),
        Text(response, style: const TextStyle(height: 1.4, color: Colors.black87)),
      ]),
    );
  }
}
