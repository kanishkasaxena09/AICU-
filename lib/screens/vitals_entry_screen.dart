import 'package:flutter/material.dart';
import 'package:aicu/models/vitals_reading.dart';
import 'package:aicu/repositories/vitals_repository.dart';
import 'package:aicu/services/news2_engine.dart';

class VitalsEntryScreen extends StatefulWidget {
  final String patientId;
  final String wardId;
  final String recordedBy;
  final VitalsRepository vitalsRepository;
  final void Function(News2Result) onRecorded;

  const VitalsEntryScreen({
    super.key,
    required this.patientId,
    required this.wardId,
    required this.recordedBy,
    required this.vitalsRepository,
    required this.onRecorded,
  });

  @override
  State<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends State<VitalsEntryScreen> {
  final _respirationRate = TextEditingController();
  final _spo2 = TextEditingController();
  final _systolicBp = TextEditingController();
  final _pulse = TextEditingController();
  final _temperature = TextEditingController();
  final Consciousness _consciousness = Consciousness.alert;
  final bool _onO2 = false;

  Future<void> _submit() async {
    final reading = VitalsReading(
      respirationRate: int.parse(_respirationRate.text),
      spo2: int.parse(_spo2.text),
      spo2Scale: SpoScale.scale1,
      onSupplementalOxygen: _onO2,
      systolicBp: int.parse(_systolicBp.text),
      pulse: int.parse(_pulse.text),
      consciousness: _consciousness,
      temperature: double.parse(_temperature.text),
    );
    final result = await widget.vitalsRepository.recordVitals(
      patientId: widget.patientId,
      wardId: widget.wardId,
      recordedBy: widget.recordedBy,
      reading: reading,
    );
    widget.onRecorded(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record vitals')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(key: const Key('respirationRateField'), controller: _respirationRate, decoration: const InputDecoration(labelText: 'Respiration rate')),
          TextField(key: const Key('spo2Field'), controller: _spo2, decoration: const InputDecoration(labelText: 'SpO2 %')),
          TextField(key: const Key('systolicBpField'), controller: _systolicBp, decoration: const InputDecoration(labelText: 'Systolic BP')),
          TextField(key: const Key('pulseField'), controller: _pulse, decoration: const InputDecoration(labelText: 'Pulse')),
          TextField(key: const Key('temperatureField'), controller: _temperature, decoration: const InputDecoration(labelText: 'Temperature °C')),
          ElevatedButton(key: const Key('submitVitalsButton'), onPressed: _submit, child: const Text('Submit')),
        ]),
      ),
    );
  }
}
