import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/demo.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/theme.dart';
import '../../core/widgets/choices.dart';
import '../demo/demo_store.dart';
import '../demo/demo_widgets.dart';
import '../session/session_view_model.dart';
import '../../core/widgets/back_or_home.dart';

/// 시간표 색 (수학 · 피아노 · 영어 순)
const lessonColors = [AppColors.pri, Color(0xFFF2A93B), Color(0xFF0F5C46)];

/// 피그마 7-1 · 7-2 알림장 (주간 시간표 · 숙제 · 선생님 코멘트 · 질의응답)
class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  int _kid = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final me = context.watch<SessionViewModel>().profile;
    final student = me?.role == UserRole.student;
    final kids = me?.kids ?? const <Kid>[];
    final hw = store.homework.where((h) => !h.comment).toList();
    final comments = store.homework.where((h) => h.comment).toList();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: bigTitleBar('알림장'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (kids.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: [for (final (i, k) in kids.indexed) PillChip(k.label, selected: _kid == i, onTap: () => setState(() => _kid = i))],
              ),
            ),
          DemoNote(text: kids.length > 1 ? '시연용 예시 화면이라 자녀마다 같은 예시가 보여요.' : null),
          _WeekCard(who: kids.isEmpty ? null : kids[_kid.clamp(0, kids.length - 1)].label),
          _Section(
            title: '숙제',
            trailing: '${hw.where((h) => h.done).length}/${hw.length} 완료',
            children: [
              for (final h in hw)
                CheckboxListTile(
                  value: h.done,
                  onChanged: (_) => store.toggleHomework(h),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.green,
                  title: Text(
                    h.title,
                    style: TextStyle(fontSize: 15.5, decoration: h.done ? TextDecoration.lineThrough : null, color: h.done ? AppColors.ink3 : AppColors.ink),
                  ),
                  subtitle: Text('${h.academy} · ${h.done ? '완료' : h.due}', style: TextStyle(fontSize: 13.5, color: h.done ? AppColors.green : AppColors.ink3)),
                ),
            ],
          ),
          _Section(
            title: '선생님 코멘트',
            children: [
              for (final c in comments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.greenLight,
                        child: Text(
                          c.by.isEmpty ? '선' : c.by[0],
                          style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${c.by} · ${c.academy} · ${ago(c.at)}', style: AppText.small),
                            const SizedBox(height: 2),
                            Text(c.title, style: const TextStyle(fontSize: 15, height: 1.6)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _Section(
            title: '질문 · 답변',
            children: [
              for (final q in store.qna)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(12)),
                        child: Text('Q. ${q.q}', style: const TextStyle(fontSize: 15)),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8, left: 24),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: q.a == null ? AppColors.paper : AppColors.priLight,
                          borderRadius: BorderRadius.circular(12),
                          border: q.a == null ? Border.all(color: AppColors.line2) : null,
                        ),
                        child: Text(
                          q.a == null ? '선생님 답변을 기다리고 있어요' : 'A. ${q.a} — ${q.aBy}',
                          style: TextStyle(fontSize: 15, height: 1.5, color: q.a == null ? AppColors.ink3 : AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ComposeBar(fieldKey: const Key('ask'), hint: student ? '선생님께 질문하기' : '선생님께 문의하기', onSend: (q) => store.ask('바른수학', q)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppText.title)),
                if (trailing != null) Text(trailing!, style: AppText.small),
              ],
            ),
            const SizedBox(height: 6),
            if (children.isEmpty) const Text('아직 없어요.', style: AppText.small) else ...children,
          ],
        ),
      ),
    );
  }
}

/// 피그마 7-1 주간 시간표
class _WeekCard extends StatelessWidget {
  const _WeekCard({this.who});

  final String? who;

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<DemoStore>().lessons;
    final hours = {for (final l in lessons) int.parse(l.start.split(':')[0])}.toList()..sort();
    final today = DateTime.now().weekday;
    final legend = {for (final l in lessons) l.label: l.color}..remove('보강');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(who == null ? '이번 주 시간표' : '이번 주 시간표 · $who', style: AppText.title),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (final MapEntry(key: label, value: c) in legend.entries)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: lessonColors[c], borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 4),
                      Text(label, style: AppText.small),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 34),
                for (var d = 1; d <= 7; d++)
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: d == today ? AppColors.ink : null, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '월화수목금토일'[d - 1],
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: d == today ? Colors.white : AppColors.ink2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (final h in hours)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(width: 34, child: Text('$h시', style: AppText.small)),
                    for (var d = 1; d <= 7; d++)
                      Expanded(child: _cell(lessons.where((l) => l.days.contains(d) && int.parse(l.start.split(':')[0]) == h).firstOrNull)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(Lesson? l) => Container(
    height: 44,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    alignment: Alignment.topLeft,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: l == null ? AppColors.fill : lessonColors[l.color], borderRadius: BorderRadius.circular(8)),
    child: l == null
        ? null
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l.label,
              maxLines: 1,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
  );
}

/// 피그마 6-1 알림 센터 (긴급 안내 · 오늘 출결 · 알림)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _f = '전체';

  @override
  void initState() {
    super.initState();
    // 열어 본 알림은 읽은 것으로(종 아이콘의 숫자가 사라진다)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DemoStore>().markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final urgent = store.notices.where((n) => n.urgent).toList();
    bool show(String k) => _f == '전체' || _f.startsWith(k);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(leading: const BackOrHome(), title: const Text('알림')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8,
              children: [
                for (final f in ['전체', '긴급 ${urgent.where((n) => !n.acked).length}', '출결', '알림장'])
                  PillChip(f, selected: _f == f || (_f.startsWith('긴급') && f.startsWith('긴급')), onTap: () => setState(() => _f = f)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const DemoNote(),
          if (show('긴급'))
            for (final n in urgent)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: n.acked ? AppColors.paper : AppColors.redLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: n.acked ? AppColors.line : const Color(0xFFEBA79B), width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: n.acked ? AppColors.line2 : AppColors.red,
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '긴급 · ${n.academy} · ${hm(n.at)}',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFFA12A15)),
                            ),
                            const SizedBox(height: 3),
                            Text(n.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.35)),
                            if (n.body.isNotEmpty) Text(n.body, style: const TextStyle(fontSize: 14.5, color: AppColors.ink2)),
                            const SizedBox(height: 12),
                            if (n.acked)
                              const Text(
                                '확인했어요',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink3),
                              )
                            else
                              OutlinedButton(
                                onPressed: () => store.ack(n),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFA12A15),
                                  side: const BorderSide(color: AppColors.red, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('확인했어요', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (show('출결'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(child: Text('오늘 출결', style: AppText.title)),
                        Icon(Icons.circle, size: 10, color: AppColors.green),
                        SizedBox(width: 5),
                        Text(
                          '실시간',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final a in store.attendance)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(
                                a.planned ? Icons.radio_button_unchecked : Icons.circle,
                                size: 14,
                                color: a.planned ? AppColors.line2 : AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${a.time} ${a.kind}',
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        TextSpan(
                                          text: ' · ${a.academy}',
                                          style: const TextStyle(color: AppColors.ink2),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(fontSize: 15.5),
                                  ),
                                  Text(a.via, style: AppText.small),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (show('알림장'))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: WhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, n) in store.notis.indexed)
                      Container(
                        decoration: i == 0
                            ? null
                            : const BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.line)),
                              ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: n.kind == 'hw' ? AppColors.priLight : AppColors.fill, borderRadius: BorderRadius.circular(11)),
                              child: Icon(
                                n.kind == 'hw' ? Icons.book_outlined : Icons.chat_bubble_outline,
                                size: 20,
                                color: n.kind == 'hw' ? AppColors.pri : AppColors.ink2,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: n.lead),
                                        TextSpan(
                                          text: n.bold,
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        TextSpan(text: n.tail),
                                      ],
                                    ),
                                    style: const TextStyle(fontSize: 15, height: 1.45),
                                  ),
                                  Text(ago(n.at), style: AppText.small),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 종 아이콘 + 안 읽은 알림 수
class BellButton extends StatelessWidget {
  const BellButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final n = context.watch<DemoStore>().unread;
    return IconButton(
      onPressed: onPressed,
      tooltip: '알림',
      icon: Badge(isLabelVisible: n > 0, label: Text('$n'), backgroundColor: AppColors.red, child: const Icon(Icons.notifications_none, size: 26)),
    );
  }
}
