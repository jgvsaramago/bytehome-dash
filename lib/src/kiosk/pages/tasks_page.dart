import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';

import '../data/chores_data.dart';
import '../data/family_data.dart';
import '../data/dates.dart';
import '../modals/task_modal.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_header.dart';
import '../widgets/kiosk_widgets.dart';

/// Tarefas: this week's days with their progress, then one column per
/// family member with that day's tasks to tick off.
class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  DateTime? _selected;
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    final now = watchNow(ref);
    final state = ref.watch(choresProvider);
    final members = ref.watch(familyMembersProvider);
    final monday = mondayOf(now);
    final day = _selected ?? dateOnly(now);
    final dayList = state.forDay(day);
    final dayDone = dayList.where((c) => state.isDone(day, c)).length;
    final isToday = sameDay(day, now);
    final dayLabel = isToday ? l10n.commonToday : l10n.tasksWeekdayDate(KDates.weekdaysShort[day.weekday - 1], KDates.short(day));
    final progress = dayList.isEmpty ? l10n.tasksSummaryNone : l10n.tasksSummaryDone(dayDone, dayList.length);

    return KFadeUp(
      child: KSection(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.tasksTitle, style: KText.pageTitle),
                      const SizedBox(height: 2),
                      Text(
                        '$dayLabel · $progress',
                        style: KText.s(20, weight: FontWeight.w500, color: KColors.muted),
                      ),
                    ],
                  ),
                ),
                KButton.primary(
                  label: l10n.tasksNew,
                  icon: KIcons.plus,
                  height: 72,
                  fontSize: 24,
                  onTap: () => showTaskModal(context, day: day),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: () {
                      final d = addDays(monday, i);
                      final list = state.forDay(d);
                      final n = list.where((c) => state.isDone(d, c)).length;
                      final on = sameDay(d, day), today = sameDay(d, now);
                      final sub = on ? KColors.onAccentMuted : (today ? KColors.todayInk : KColors.muted);
                      return KPress(
                        onTap: () => setState(() {
                          _selected = d;
                          _tick++;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 148,
                          decoration: BoxDecoration(
                            color: on ? KColors.accent : (today ? KColors.todayBg : KColors.sub),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: today && !on ? KColors.todayBorder : Colors.transparent, width: 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                KDates.abbr[i],
                                style: KText.s(17, weight: FontWeight.w700, spacing: 1.5, color: sub),
                              ),
                              const SizedBox(height: 8),
                              Text('${d.day}', style: KText.d(36, height: 1, color: on ? KColors.onAccent : KColors.ink)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 72,
                                child: KProgress(
                                  value: list.isEmpty ? 0 : n / list.length,
                                  height: 8,
                                  track: on ? KColors.onAccent.withValues(alpha: 0.25) : KColors.border,
                                  fill: on ? KColors.onAccent : KColors.accent,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                list.isEmpty ? '—' : '$n/${list.length}',
                                style: KText.s(15, weight: FontWeight.w600, color: sub),
                              ),
                            ],
                          ),
                        ),
                      );
                    }(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_tick),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 340),
                curve: kEase,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
                ),
                child: dayList.isEmpty
                    ? _EmptyDay(body: isToday ? l10n.tasksEmptyDayBodyToday : l10n.tasksEmptyDayBody(KDates.longLower(day)))
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, m) in members.indexed) ...[
                            if (i > 0) const SizedBox(width: 16),
                            Expanded(
                              child: _PersonColumn(member: m, day: day, isToday: isToday, chores: dayList.where((c) => c.who == m.id).toList(), state: state),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonColumn extends ConsumerWidget {
  const _PersonColumn({required this.member, required this.day, required this.isToday, required this.chores, required this.state});

  final FamilyMember member;
  final DateTime day;
  final bool isToday;
  final List<Chore> chores;
  final ChoresState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = member.color;
    final n = chores.where((x) => state.isDone(day, x)).length;
    final allDone = chores.isNotEmpty && n == chores.length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KAvatar(initial: member.initial, color: c.color, size: 64, fontSize: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(26, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: KProgress(value: chores.isEmpty ? 0 : n / chores.length, height: 8, track: KColors.border, fill: c.color),
                        ),
                        const SizedBox(width: 10),
                        Text(chores.isEmpty ? l10n.tasksFree : l10n.tasksCountOf(n, chores.length), style: KText.s(18, color: KColors.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allDone) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: kEase,
              builder: (context, s, child) => Opacity(
                opacity: ((s - 0.5) * 2).clamp(0.0, 1.0),
                child: Transform.scale(scale: s, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    KIcon(KIcons.check, size: 28, color: c.ink, stroke: 2.6),
                    const SizedBox(width: 12),
                    Text(
                      l10n.tasksAllDone,
                      style: KText.s(22, weight: FontWeight.w600, color: c.ink),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: chores.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: _EmptyState(
                      circle: 88,
                      icon: 42,
                      circleColor: KColors.tile,
                      iconColor: c.color,
                      title: Text(l10n.tasksNoneTitle, style: KText.s(22, weight: FontWeight.w600)),
                      body: _isHousehold(member)
                          ? (isToday ? l10n.tasksHouseholdFreeToday : l10n.tasksHouseholdFreeDay)
                          : (isToday ? l10n.tasksMemberFreeToday(member.name) : l10n.tasksMemberFreeDay(member.name)),
                      bodySize: 18,
                      gap: 10,
                    ),
                  )
                : ListView.separated(
                    itemCount: chores.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final x = chores[i];
                      final done = state.isDone(day, x);
                      return Container(
                        constraints: const BoxConstraints(minHeight: 104),
                        decoration: BoxDecoration(color: done ? KColors.tile.withValues(alpha: 0.55) : KColors.tile, borderRadius: BorderRadius.circular(22)),
                        child: Row(
                          children: [
                            KPress(
                              onTap: () => ref.read(choresProvider.notifier).toggle(day, x).catchError(KToast.error),
                              child: SizedBox(
                                width: 84,
                                height: 104,
                                child: Center(
                                  child: KCheckCircle(done: done, size: 48, color: c.color),
                                ),
                              ),
                            ),
                            Expanded(
                              child: KPress(
                                onTap: () => showTaskModal(context, chore: x, day: day),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 14, 18, 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        x.title,
                                        style: KText.s(
                                          24,
                                          weight: FontWeight.w600,
                                          height: 1.2,
                                          color: done ? KColors.faint : KColors.ink,
                                        ).copyWith(decoration: done ? TextDecoration.lineThrough : null),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(x.meta, style: KText.s(17, color: KColors.muted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// The shared member ("Família") as opposed to a person.
bool _isHousehold(FamilyMember m) => m.id == 'familia' || m.id == 'family' || const ['família', 'family'].contains(m.name.toLowerCase());

/// No one has anything on the selected day (design: "Página Tarefas sem
/// tarefas") — one panel instead of a column per person.
class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(30)),
      child: _EmptyState(
        circle: 128,
        icon: 60,
        circleColor: KColors.tile,
        iconColor: KColors.accentFg,
        title: Text(l10n.tasksEmptyDayTitle, style: KText.d(40)),
        body: body,
        bodySize: 22,
        gap: 16,
      ),
    );
  }
}

/// Icon in a circle, a title and a line of text, centred — the design's
/// empty states for tasks.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.circle,
    required this.icon,
    required this.circleColor,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.bodySize,
    required this.gap,
  });

  final double circle, icon, bodySize, gap;
  final Color circleColor, iconColor;
  final Widget title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circle,
                height: circle,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(
                  child: KIcon(KIcons.tasks, size: icon, color: iconColor, stroke: 1.8),
                ),
              ),
              SizedBox(height: gap),
              title,
              SizedBox(height: gap),
              Text(
                body,
                textAlign: TextAlign.center,
                style: KText.s(bodySize, color: KColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
