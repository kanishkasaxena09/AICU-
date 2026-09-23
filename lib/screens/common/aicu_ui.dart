import 'package:flutter/material.dart';

/// Shared visual language for the redesigned AICU screens (dashboard,
/// patient file, voice AI, insights): teal brand color, white rounded
/// cards, pill badges, and a consistent top app bar. Kept in one place so
/// the 4 new screens don't each reinvent the same look.
class AicuColors {
  AicuColors._();
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF0B5A54);
  static const background = Color(0xFFF3F4F6);
  static const alert = Color(0xFFDC2626);
  static const alertBg = Color(0xFFFEE2E2);
  static const tealBg = Color(0xFFCCFBF1);
}

/// Standard top app bar: hamburger, title, search, bell+dot, avatar.
PreferredSizeWidget aicuAppBar(BuildContext context, String title, {List<Widget>? extraActions}) {
  return AppBar(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
    leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.maybeOf(context)?.openDrawer()),
    title: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
    actions: [
      ...?extraActions,
      IconButton(icon: const Icon(Icons.search), onPressed: () {}),
      Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AicuColors.alert, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.only(right: 16, left: 4),
        child: CircleAvatar(radius: 16, backgroundColor: AicuColors.primary, child: Icon(Icons.person, color: Colors.white, size: 18)),
      ),
    ],
  );
}

/// Small rounded status/pill badge, e.g. "P-10245", "2 High-Attention".
class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  const Pill(this.text, {super.key, this.background = AicuColors.tealBg, this.foreground = AicuColors.primaryDark, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: foreground), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// White rounded card with a soft shadow — the base container used by
/// every card in the redesign.
class AicuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AicuCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// Small vital-sign readout tile used on patient cards (e.g. "BP
/// Monitoring 128/82"). [abnormal] switches the accent to red.
class VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final bool abnormal;
  final IconData? trailingIcon;
  const VitalTile({super.key, required this.label, required this.value, this.abnormal = false, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    final accent = abnormal ? AicuColors.alert : AicuColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AicuColors.background, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 4),
        Row(children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
          if (trailingIcon != null) Icon(trailingIcon, size: 14, color: accent),
        ]),
      ]),
    );
  }
}

int computeAge(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
  return age;
}

void showComingSoon(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(feature),
      content: const Text('Coming soon — not part of this demo.'),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ),
  );
}
