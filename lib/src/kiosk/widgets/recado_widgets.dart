import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../data/family_data.dart';
import '../data/messages_data.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';

/// The recados' speech-bubble icon.
const recadoIcon = '<path d="M4 5h16v11H8l-4 4z"/>';
const recadoEveryoneIcon = '<path d="M12 4v16M5 8l14 8M19 8L5 16"/>';

/// "Hoje às 18:40", "Ontem às 21:15", "Segunda às 16:00", "17 out às 09:00".
String recadoWhen(DateTime d, {bool lower = false}) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  final day = switch (days) {
    0 => l10n.commonToday,
    1 => l10n.commonYesterday,
    < 7 => KDates.weekdaysShort[d.weekday - 1],
    _ => KDates.short(d),
  };
  // Lowercase mid-sentence; weekdays only where the language writes them so ("segunda", not "monday").
  final weekday = KDates.weekdays[d.weekday - 1];
  final lowerDay = lower && (days < 2 || (days < 7 && weekday[0] == weekday[0].toLowerCase()));
  return l10n.recadoDayAt(lowerDay ? day[0].toLowerCase() + day.substring(1) : day, KDates.hm(d));
}

/// "de Ana", or that the voice wasn't recognised.
String recadoFrom(FamilyMessage m) => m.from == null ? l10n.recadoFromUnknown : l10n.recadoFrom(m.from!);

/// "Visto por Ana · ontem às 22:02" (by voice), "Visto · agora" (a tap).
String recadoSeen(FamilyMessage m) {
  final at = m.seenAt;
  final when = at == null ? '' : (DateTime.now().difference(at).inMinutes < 2 ? l10n.recadoNow : recadoWhen(at, lower: true));
  return [m.seenBy == null ? l10n.recadoSeen : l10n.recadoSeenBy(m.seenBy!), if (when.isNotEmpty) when].join(' · ');
}

/// Who a recado is for: the person's colour and initial, or everyone.
class RecadoToChip extends StatelessWidget {
  const RecadoToChip({super.key, required this.message, required this.members, this.height = 44});

  final FamilyMessage message;
  final List<FamilyMember> members;
  final double height;

  @override
  Widget build(BuildContext context) {
    final member = members.where((p) => p.name == message.to).firstOrNull;
    final everyone = message.to == null;
    final dot = height - 10;
    return Container(
      height: height,
      padding: EdgeInsets.fromLTRB(5, 0, 16, 0),
      decoration: BoxDecoration(
        color: everyone ? KColors.accentSoft : (member?.color.tint ?? KColors.chipAlt),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dot,
            height: dot,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: everyone ? KColors.accent : (member?.color.color ?? KColors.muted), shape: BoxShape.circle),
            // Everyone: an asterisk, drawn (the app's fonts have no "∗").
            child: everyone
                ? KIcon(recadoEveryoneIcon, size: dot * 0.5, stroke: 2.6, color: Colors.white)
                : Text(
                    member?.initial ?? message.to!.characters.first.toUpperCase(),
                    style: KText.s(dot * 0.47, weight: FontWeight.w700, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              everyone ? l10n.recadoForEveryone : l10n.recadoFor(message.to!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.s(height * 0.43, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
