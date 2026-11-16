import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/academy_repository.dart';
import '../../../domain/models/academy.dart';
import '../../../domain/models/demo.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/theme.dart';
import '../../core/widgets/academy_tile.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/choices.dart';
import '../../core/widgets/form_bits.dart';
import '../demo/demo_store.dart';
import '../demo/demo_widgets.dart';
import '../session/session_view_model.dart';
import '../../core/widgets/back_or_home.dart';

/// 상담 탭(학부모) · 상담함 탭(학원 관계자).
/// 학부모는 예시 상담 + 내가 보낸 상담, 관계자는 예시 상담 + 내 학원으로 온 상담.
class ConsultListScreen extends StatefulWidget {
  const ConsultListScreen({super.key});

  @override
  State<ConsultListScreen> createState() => _ConsultListScreenState();
}

class _ConsultListScreenState extends State<ConsultListScreen> {
  String? _for;
  Future<Academy?>? _myAcademy;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionViewModel>().profile;
    final staff = me?.role == UserRole.staff;
    if (staff && _for != me?.academyId) {
      _for = me?.academyId;
      _myAcademy = context.read<AcademyRepository>().byId(_for ?? '');
    }
    return FutureBuilder(future: _myAcademy, builder: (context, snap) => _build(context, me, staff, snap.data?.name));
  }

  Widget _build(BuildContext context, UserProfile? me, bool staff, String? myAcademy) {
    final store = context.watch<DemoStore>();
    final list =
        store.threads.where((t) => staff ? t.ownerUid == null || t.academy == myAcademy : !t.incoming && (t.ownerUid == null || t.ownerUid == me?.uid)).toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: bigTitleBar(staff ? '상담함' : '상담'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const DemoNote(),
          if (!staff)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('학원에 궁금한 걸 한 번에 물어보세요', style: AppText.title),
                    const SizedBox(height: 4),
                    const Text('자녀 학년과 고민을 카드 한 장에 담아 최대 3곳에 보내요.', style: AppText.small),
                    const SizedBox(height: 14),
                    AppButton('상담 카드 보내기', icon: Icons.send_outlined, height: 48, onPressed: () => context.push('/consult/new')),
                  ],
                ),
              ),
            ),
          if (list.isEmpty)
            EmptyView(
              icon: Icons.chat_bubble_outline,
              title: staff ? '받은 상담이 없어요' : '아직 상담이 없어요',
              message: staff ? '학부모가 상담 카드를 보내면 여기에 모여요.' : '학원 상세나 위 버튼에서 상담 카드를 보내 보세요.',
            )
          else
            for (final t in list)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: WhiteCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push('/chat/${t.id}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.priLight,
                        child: Text(
                          (staff ? t.parent : t.academy)[0],
                          style: const TextStyle(color: AppColors.pri, fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff ? '${t.parent} · ${t.card.kid}' : t.academy, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              t.msgs.isEmpty ? '상담 카드 · ${t.card.memo}' : t.msgs.last.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, color: AppColors.ink3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(ago(t.at), style: AppText.small.copyWith(fontSize: 12)),
                          const SizedBox(height: 5),
                          Tag(t.status, tone: t.status == '새 상담' ? TagTone.amber : TagTone.green),
                        ],
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

/// 피그마 5-1 상담 카드 작성. [academy] 를 주면 받는 학원에 미리 넣는다(학원 상세에서 들어올 때).
class ConsultCardScreen extends StatefulWidget {
  const ConsultCardScreen({super.key, this.academy});

  final String? academy;

  @override
  State<ConsultCardScreen> createState() => _ConsultCardScreenState();
}

class _ConsultCardScreenState extends State<ConsultCardScreen> {
  late final List<String> _to = [?widget.academy];
  String? _kid, _prog;
  final Set<String> _worries = {};
  String _how = '채팅', _memo = '';
  Map<String, String> _errors = {};

  Future<void> _addAcademy() async {
    hideKeyboard();
    final picked = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const _AcademyPicker());
    if (picked != null && !_to.contains(picked)) setState(() => _to.add(picked));
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionViewModel>().profile;
    final kids = [for (final k in me?.kids ?? const <Kid>[]) '${k.order} · ${k.grade}'];
    if (kids.isEmpty && me?.grade != null) kids.add(me!.grade!);
    _kid ??= kids.firstOrNull;
    void submit() {
      final e = {if (_to.isEmpty) 'to': '받는 학원을 골라 주세요', if (_prog == null) 'prog': '지금 진도를 골라 주세요'};
      setState(() => _errors = e);
      if (e.isNotEmpty) return;
      final id = context.read<DemoStore>().sendCard(
        academies: _to,
        parent: me?.name ?? '학부모',
        ownerUid: me?.uid,
        card: ConsultCard(kid: _kid ?? '자녀', prog: _prog!, worries: _worries.toList(), how: _how, memo: _memo.trim()),
      );
      hideKeyboard();
      context.pushReplacement('/chat/$id');
    }

    return Scaffold(
      appBar: AppBar(leading: const BackOrHome(), title: const Text('상담 카드')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(16)),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('받는 학원', style: TextStyle(fontSize: 14.5, color: AppColors.ink3)),
                for (final a in _to)
                  InputChip(
                    label: Text(a, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onDeleted: () => setState(() => _to.remove(a)),
                    backgroundColor: AppColors.paper,
                    shape: const StadiumBorder(side: BorderSide(color: AppColors.line2)),
                  ),
                if (_to.length < 3)
                  TextButton.icon(onPressed: _addAcademy, icon: const Icon(Icons.add, size: 18), label: Text(_to.isEmpty ? '학원 고르기' : '학원 추가')),
              ],
            ),
          ),
          ErrorText(_errors['to']),
          const SizedBox(height: 22),
          if (kids.isNotEmpty) ...[
            const FieldLabel('자녀'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final k in kids) OptionBox(k, pill: true, selected: _kid == k, onTap: () => setState(() => _kid = k))],
            ),
            const SizedBox(height: 22),
          ],
          const FieldLabel('지금 진도는?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final p in DemoStore.progs) OptionBox(p, pill: true, selected: _prog == p, onTap: () => setState(() => _prog = p))],
          ),
          ErrorText(_errors['prog']),
          const SizedBox(height: 22),
          const FieldLabel('고민', hint: '· 여러 개'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in DemoStore.worries)
                PillChip(w, selected: _worries.contains(w), onTap: () => setState(() => _worries.contains(w) ? _worries.remove(w) : _worries.add(w))),
            ],
          ),
          const SizedBox(height: 22),
          const FieldLabel('상담 방식'),
          Row(
            children: [
              for (final (i, h) in ['채팅', '전화', '방문'].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: OptionBox(h, selected: _how == h, onTap: () => setState(() => _how = h)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          const FieldLabel('학원에 전할 말'),
          AppTextField(fieldKey: const Key('memo'), hint: '예) 문제는 잘 푸는데 풀이 과정을 안 써요.', maxLength: 300, maxLines: 4, onChanged: (v) => _memo = v),
        ],
      ),
      bottomNavigationBar: BottomAction(
        note: '카드 한 장으로 최대 3곳에 보낼 수 있어요.',
        child: AppButton(_to.length > 1 ? '${_to.length}곳에 상담 카드 보내기' : '상담 카드 보내기', onPressed: submit),
      ),
    );
  }
}

/// 상담 카드의 받는 학원 고르기 (실제 학원 목록에서 검색)
class _AcademyPicker extends StatefulWidget {
  const _AcademyPicker();

  @override
  State<_AcademyPicker> createState() => _AcademyPickerState();
}

class _AcademyPickerState extends State<_AcademyPicker> {
  late final _all = context.read<AcademyRepository>().all();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: AppTextField(
                fieldKey: const Key('pickAcademy'),
                hint: '학원 이름이나 동 이름',
                prefix: const Icon(Icons.search),
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _all,
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snap.data!.where((a) => _q.isEmpty || '${a.name} ${a.dong}'.contains(_q)).take(30).toList();
                  return ListView(
                    children: [
                      for (final Academy a in list)
                        ListTile(leading: AcademyTile(a, size: 40), title: Text(a.name), subtitle: Text(a.dong), onTap: () => Navigator.pop(context, a.name)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 피그마 5-2 1:1 채팅. 학부모와 학원 관계자가 같은 방을 서로 반대편에서 본다.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.id});

  final String id;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final staff = context.watch<SessionViewModel>().profile?.role == UserRole.staff;
    final t = store.threads.where((x) => x.id == widget.id).firstOrNull;
    if (t == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackOrHome()),
        body: const EmptyView(icon: Icons.chat_bubble_outline, title: '상담을 찾지 못했어요', message: '앱을 다시 열면 시연용 상담이 처음 상태로 돌아가요.'),
      );
    }
    final items = <Widget>[
      const DemoNote(padding: EdgeInsets.only(bottom: 12)),
      _CardBubble(t.card, mine: !staff),
      for (final m in t.msgs) _Bubble(m, mine: m.fromStaff == staff),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F4),
      appBar: AppBar(
        leading: const BackOrHome(),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff ? '${t.parent} · ${t.card.kid}' : t.academy, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              t.status,
              maxLines: 1,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.green),
            ),
          ],
        ),
        actions: [
          if (!staff) IconButton(tooltip: 'AI 상담노트', onPressed: () => context.push('/ai/${t.id}'), icon: const Icon(Icons.auto_awesome)),
          const SizedBox(width: 6),
        ],
      ),
      // 새 말이 아래에 붙고 화면은 늘 맨 아래를 보도록 뒤집어 그린다
      body: ListView(reverse: true, padding: const EdgeInsets.fromLTRB(14, 14, 14, 20), children: items.reversed.toList()),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ComposeBar(
          fieldKey: const Key('chat'),
          hint: '메시지를 입력하세요',
          onSend: (text) => store.send(t, text, asStaff: staff),
        ),
      ),
    );
  }
}

class _CardBubble extends StatelessWidget {
  const _CardBubble(this.c, {required this.mine});

  final ConsultCard c;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.pri, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상담 카드',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.pri),
            ),
            const SizedBox(height: 6),
            Text('${c.kid} · ${c.prog}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (c.worries.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('고민: ${c.worries.join(', ')}', style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
            ],
            Text('상담 방식: ${c.how}', style: const TextStyle(fontSize: 14, color: AppColors.ink2)),
            if (c.memo.isNotEmpty) ...[const SizedBox(height: 6), Text(c.memo, style: const TextStyle(fontSize: 14, height: 1.5))],
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m, {required this.mine});

  final Msg m;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(color: mine ? AppColors.pri : AppColors.paper, borderRadius: BorderRadius.circular(16)),
            child: Text(m.text, style: TextStyle(fontSize: 15, height: 1.55, color: mine ? Colors.white : AppColors.ink)),
          ),
          const SizedBox(height: 3),
          Text(m.auto ? '${hm(m.at)} · 시연용 자동 답장' : hm(m.at), style: AppText.small.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// 피그마 5-3 AI 상담노트. 시연용이라 상담 카드와 대화로 요약 문장을 만든다(실제 AI 호출 없음).
class AiNoteScreen extends StatelessWidget {
  const AiNoteScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<DemoStore>().threads.where((x) => x.id == id).firstOrNull;
    if (t == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackOrHome()),
        body: const EmptyView(icon: Icons.auto_awesome, title: '상담을 찾지 못했어요', message: '앱을 다시 열면 시연용 상담이 처음 상태로 돌아가요.'),
      );
    }
    final c = t.card;
    final offer = t.msgs.where((m) => m.fromStaff).map((m) => m.text).firstOrNull;
    final sections = [
      ('아이 상황', ['${c.kid} · ${c.prog}', if (c.worries.isNotEmpty) '고민: ${c.worries.join(', ')}', if (c.memo.isNotEmpty) c.memo]),
      ('학원 답장', [offer ?? '아직 학원 답장이 없어요.']),
      ('다음에 할 일', ['레벨테스트 일정 확정하기', '반 시간표 · 수강료 확인하기 (학원 상세 > 가격)', '셔틀 노선과 시간 확인하기']),
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(leading: const BackOrHome(), title: const Text('AI 상담노트')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const DemoNote(padding: EdgeInsets.fromLTRB(4, 0, 4, 12)),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${t.academy} 상담 요약', style: AppText.title)),
                    const Tag('PLUS', tone: TagTone.amber),
                  ],
                ),
                for (final (title, lines) in sections) ...[
                  const SizedBox(height: 18),
                  Text(title, style: AppText.label),
                  const SizedBox(height: 6),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $l', style: const TextStyle(fontSize: 15, height: 1.6)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
