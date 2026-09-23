import 'package:flutter/material.dart';
import 'package:aicu/screens/common/aicu_ui.dart';

// ponytail: every number on this screen is static demo data. There is no
// real ML/predictive model in this project — do not wire one in, and do not
// let the "simulated for demo" framing be removed.
class ClinicalInsightsScreen extends StatelessWidget {
  const ClinicalInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AicuColors.background,
      appBar: aicuAppBar(context, 'Clinical Insights'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DisclaimerBanner(),
          const SizedBox(height: 16),
          _PatientContextHeader(),
          const SizedBox(height: 16),
          _RiskIndexCard(),
          const SizedBox(height: 16),
          _DeteriorationWarningCard(),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Expanded(child: Text('AI Decision Support Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Pill('v4.8-sim'),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AicuColors.alertBg, borderRadius: BorderRadius.circular(10)),
          child: const Text(
            'AI Predictive Insights — Demo | Simulated data for prototype demonstration only. '
            'Not for real medical diagnosis or clinical prescription.',
            style: TextStyle(color: AicuColors.alert, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
          ),
        ),
      ]),
    );
  }
}

class _PatientContextHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Row(children: [
        const CircleAvatar(radius: 22, backgroundColor: AicuColors.tealBg, child: Text('JD', style: TextStyle(color: AicuColors.primaryDark, fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Text('Jane Doe (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Pill('P-10245'),
              SizedBox(width: 8),
              Pill('OPD Follow-up'),
            ]),
            const SizedBox(height: 4),
            const Text('Dr. Mehta • Internal Medicine', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: const [
              Pill('Type 2 Diabetes (6 yrs)'),
              Pill('Primary Hypertension (Stage 1)'),
              Pill('BMI 27.4'),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _RiskIndexCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Overall Clinical Risk Index', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(alignment: Alignment.center, children: [
              const SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: 0.42,
                  strokeWidth: 8,
                  backgroundColor: AicuColors.background,
                  valueColor: AlwaysStoppedAnimation(Colors.orange),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: const [
                Text('42/100', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Moderate', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(children: [
              _RiskBar(label: 'Glycemic Volatility', percent: 0.72, tag: 'High', color: AicuColors.alert),
              const SizedBox(height: 10),
              _RiskBar(label: 'Cardiovascular Strain', percent: 0.48, tag: 'Moderate', color: Colors.orange),
              const SizedBox(height: 10),
              _RiskBar(label: 'Renal Safety (eGFR)', percent: 0.16, tag: 'Low Risk', color: AicuColors.primary),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final String label;
  final double percent;
  final String tag;
  final Color color;
  const _RiskBar({required this.label, required this.percent, required this.tag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text('$tag ${(percent * 100).round()}%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: AicuColors.background, valueColor: AlwaysStoppedAnimation(color)),
      ),
    ]);
  }
}

class _DeteriorationWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AicuCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(child: Text('Deterioration Early Warning', style: TextStyle(fontWeight: FontWeight.bold))),
          Pill('14D Continuous', background: AicuColors.alertBg, foreground: AicuColors.alert),
        ]),
        const SizedBox(height: 10),
        const Text('Postprandial Spike Cluster Detected', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text(
          'Simulated model flags a recurring post-meal glucose spike pattern over the last two weeks, '
          'suggesting current titration may be insufficient.',
          style: TextStyle(color: Colors.black87, height: 1.4, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Unmanaged', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text('8.4% HbA1c', style: TextStyle(fontWeight: FontWeight.bold, color: AicuColors.alert)),
            ]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Titrated', style: TextStyle(fontSize: 11, color: Colors.black54)),
              Text('7.2% HbA1c', style: TextStyle(fontWeight: FontWeight.bold, color: AicuColors.primary)),
            ]),
          ),
          TextButton(onPressed: () => showComingSoon(context, 'Deterioration Details'), child: const Text('Details')),
        ]),
      ]),
    );
  }
}
