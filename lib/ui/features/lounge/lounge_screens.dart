import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

/// 남에게 보이는 이름. 학생 실명은 '선생님에게만 보여요'라고 안내했으므로 '학생'으로 쓴다.
String publicName(UserProfile? me) => me == null ? '나' : (me.role == UserRole.student ? '학생' : me.name);

TagTone _toneOf(String cat) => switch (cat) {
  '설명회' || '특강' => TagTone.blue,
  '레벨테스트' || '지역·체험' => TagTone.green,
  '개강·모집' => TagTone.red,
  '홍보·소식' => TagTone.amber,
  '익명 커뮤니티' => TagTone.purple,
  _ => TagTone.gray,
};

/// 피그마 4-1 라운지 피드 (카테고리 9종)
class LoungeScreen extends StatefulWidget {
  const LoungeScreen({super.key});

  @override
  State<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends State<LoungeScreen> {
  String _cat = '전체';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final list = store.posts.where((p) => _cat == '전체' || p.cat == _cat).toList();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: bigTitleBar(
        '라운지',
        actions: [
          IconButton(tooltip: '저장함', onPressed: () => context.push('/saved'), icon: const Icon(Icons.bookmark_border)),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '글쓰기',
        onPressed: () => context.push('/write'),
        backgroundColor: AppColors.pri,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ['전체', ...DemoStore.lounges]) PillChip(c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
              ],
            ),
          ),
          Container(
            color: AppColors.paper,
            child: const DemoNote(padding: EdgeInsets.fromLTRB(20, 4, 20, 14)),
          ),
          const SizedBox(height: 16),
          if (_cat == '구인구직')
            for (final j in store.jobs) _JobCard(j)
          else if (list.isEmpty)
            const EmptyView(icon: Icons.forum_outlined, title: '아직 글이 없어요', message: '오른쪽 아래 + 버튼으로 첫 글을 남겨 보세요.')
          else
            for (final p in list) PostCard(p),
        ],
      ),
    );
  }
}

/// 라운지 글 카드 (피드 · 저장함 공용)
class PostCard extends StatelessWidget {
  const PostCard(this.p, {super.key});

  final LoungePost p;

  @override
  Widget build(BuildContext context) {
    final e = p.event;
    final now = DateTime.now();
    final right = e != null
        ? 'D-${DateTime(e.day.year, e.day.month, e.day.day).difference(DateTime(now.year, now.month, now.day)).inDays}'
        : p.badge ?? ago(p.at);
    final meta = e != null
        ? [p.author, e.when.split('–').first, p.region].where((s) => s.isNotEmpty).join(' · ')
        : p.body.isNotEmpty && p.likes == 0
        ? p.body
        : [if (p.region.isNotEmpty) p.region else p.author, '공감 ${p.likes}', '댓글 ${p.comments.length}'].join(' · ');
    final (accent, accentColor) = e != null
        ? ('신청 ${e.applied}/${e.cap}명 · ${e.cost.split('·').first.trim()}', AppColors.pri)
        : p.expert != null
        ? ('전문가 답변 1', AppColors.purple)
        : (p.highlight, const Color(0xFFA12A5E));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: WhiteCard(
        border: p.ad ? AppColors.amber : null,
        onTap: () => context.push('/post/${p.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (p.ad) ...[const Tag('AD', tone: TagTone.amber), const SizedBox(width: 6)],
                Tag(p.cat, tone: _toneOf(p.cat)),
                if (p.ownerUid != null && p.ownerUid == context.watch<SessionViewModel>().profile?.uid) ...[
                  const SizedBox(width: 6),
                  const Tag('내 글', tone: TagTone.dark),
                ],
                const Spacer(),
                Text(right, style: AppText.small),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, height: 1.4)),
            const SizedBox(height: 5),
            Text(
              meta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.ink3),
            ),
            if (accent != null) ...[
              const SizedBox(height: 6),
              Text(
                accent,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: accentColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard(this.j);

  final Job j;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: WhiteCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Tag(j.side, tone: j.side == '구인' ? TagTone.blue : TagTone.gray),
                const SizedBox(width: 8),
                Text(
                  j.kind,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink2),
                ),
                const Spacer(),
                Text(j.due, style: AppText.small),
              ],
            ),
            const SizedBox(height: 10),
            Text(j.title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, height: 1.4)),
            const SizedBox(height: 4),
            Text(j.meta, style: const TextStyle(fontSize: 13.5, color: AppColors.ink3)),
            const SizedBox(height: 6),
            Text(j.pay, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// 피그마 4-2 · 4-3 글 상세 (설명회 · 레벨테스트 · 특강은 신청, 그 밖의 글은 공감 · 댓글)
class PostScreen extends StatelessWidget {
  const PostScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final p = store.posts.where((x) => x.id == id).firstOrNull;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackOrHome()),
        body: const EmptyView(icon: Icons.search_off, title: '글을 찾지 못했어요', message: '앱을 다시 열면 시연용 글이 처음 상태로 돌아가요.'),
      );
    }
    final e = p.event;
    final me = context.watch<SessionViewModel>().profile;
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(),
        title: Text(p.cat),
        actions: [
          IconButton(
            tooltip: p.saved ? '저장 취소' : '저장',
            onPressed: () => store.toggleSave(p),
            icon: Icon(p.saved ? Icons.bookmark : Icons.bookmark_border, color: p.saved ? AppColors.pri : null),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.priLight,
                child: Text(
                  p.author.isEmpty ? '?' : p.author[0],
                  style: const TextStyle(color: AppColors.pri, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.author, style: AppText.label),
                    Text([if (p.region.isNotEmpty) p.region, ago(p.at)].join(' · '), style: AppText.small),
                  ],
                ),
              ),
              Tag(p.cat, tone: _toneOf(p.cat)),
            ],
          ),
          const SizedBox(height: 16),
          Text(p.title, style: AppText.h2.copyWith(fontSize: 21, height: 1.35)),
          if (e != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  for (final (k, v) in [('일시', e.when), ('장소', e.where), ('대상', e.target), ('비용', e.cost)])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(k, style: const TextStyle(fontSize: 15, color: AppColors.ink3)),
                          ),
                          Expanded(child: Text(v, style: const TextStyle(fontSize: 15, height: 1.45))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text('신청 현황', style: TextStyle(fontSize: 14.5, color: AppColors.ink3)),
                const Spacer(),
                Text('${e.applied} / ${e.cap}명', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: LinearProgressIndicator(value: e.applied / e.cap, minHeight: 8, color: AppColors.pri, backgroundColor: AppColors.fill),
            ),
            if (e.steps.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('진행 순서', style: AppText.title),
              const SizedBox(height: 6),
              for (final (i, s) in e.steps.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('${i + 1}. $s', style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.ink2)),
                ),
            ],
          ],
          if (p.body.isNotEmpty) ...[const SizedBox(height: 14), Text(p.body, style: const TextStyle(fontSize: 15.5, height: 1.7))],
          if (e == null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => store.toggleLike(p),
                  icon: Icon(p.liked ? Icons.favorite : Icons.favorite_border, size: 20, color: p.liked ? AppColors.red : AppColors.ink3),
                  label: Text('공감 ${p.likes}', style: const TextStyle(color: AppColors.ink2)),
                ),
                const SizedBox(width: 4),
                Text('댓글 ${p.comments.length}', style: const TextStyle(fontSize: 14, color: AppColors.ink3)),
              ],
            ),
          ],
          if (p.expert != null) _ExpertBox(p.expert!),
          if (e == null) ...[
            const Divider(height: 28, color: AppColors.line),
            if (p.comments.isEmpty) const Text('첫 댓글을 남겨 보세요.', style: AppText.small),
            for (final (i, c) in p.comments.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.fill,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text([c.name, if (c.who.isNotEmpty) c.who, ago(c.at)].join(' · '), style: AppText.small),
                          const SizedBox(height: 2),
                          Text(c.text, style: const TextStyle(fontSize: 15, height: 1.55)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: e != null
          ? BottomAction(
              note: e.joined ? '신청됐어요. 다시 누르면 취소돼요.' : null,
              child: AppButton(e.joined ? '신청 취소' : '신청하기', tone: e.joined ? ButtonTone.outline : ButtonTone.primary, onPressed: () => store.toggleJoin(e)),
            )
          : Padding(
              // 셸 밖 화면이라 키보드 높이만큼 직접 올린다
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: ComposeBar(
                fieldKey: const Key('comment'),
                hint: '댓글을 남겨 주세요',
                onSend: (t) => store.addComment(p, p.cat == '익명 커뮤니티' ? '익명 ${p.comments.length + 1}' : publicName(me), t),
              ),
            ),
    );
  }
}

/// 피그마 4-3 유료 전문가 답변. 시연이라 결제는 없고 요금제 안내로 보낸다.
class _ExpertBox extends StatelessWidget {
  const _ExpertBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.amber, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '전문가 답변 · 교육 컨설턴트',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.6, color: Color(0xFFC9CED8))),
          ),
          const SizedBox(height: 14),
          AppButton('PLUS 회원에게 공개돼요 · 요금제 보기', tone: ButtonTone.amber, height: 48, onPressed: () => context.push('/plans')),
        ],
      ),
    );
  }
}

/// 피그마 4-5 글쓰기(의뢰인 요청 261026).
/// 학원 관계자: 9개 카테고리 전부. 설명회 · 레벨테스트 · 특강은 일정 칸, 구인구직은 근무 조건 칸이 붙는다.
/// 학부모: 교육팁 · 익명 커뮤니티. 학생: 익명 커뮤니티.
class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  static const _events = ['설명회', '레벨테스트', '특강'];
  String? _cat;
  String _title = '', _body = '';
  // 설명회 · 레벨테스트 · 특강
  DateTime? _day;
  String _time = '', _where = '', _target = '', _cost = '', _cap = '';
  // 구인구직
  String _side = '구인', _kind = '', _meta = '', _pay = '';
  Map<String, String> _errors = {};

  Future<void> _pickDay() async {
    hideKeyboard();
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _day ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _day = d);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionViewModel>().profile;
    final cats = switch (me?.role) {
      UserRole.staff => DemoStore.lounges,
      UserRole.parent => const ['교육팁', '익명 커뮤니티'],
      _ => const ['익명 커뮤니티'],
    };
    if (cats.length == 1) _cat ??= cats.first;
    final event = _events.contains(_cat), job = _cat == '구인구직';
    void submit() {
      final cap = int.tryParse(_cap.trim());
      final e = {
        if (_cat == null) 'cat': '어떤 글인지 골라 주세요',
        if (_title.trim().isEmpty) 'title': '제목을 적어 주세요',
        if (!event && !job && _body.trim().isEmpty) 'body': '내용을 적어 주세요',
        if (event && _day == null) 'day': '날짜를 골라 주세요',
        if (event && _where.trim().isEmpty) 'where': '장소를 적어 주세요',
        if (event && (cap == null || cap < 1 || cap > 999)) 'cap': '정원을 숫자로 적어 주세요',
        if (job && _meta.trim().isEmpty) 'meta': '근무 조건을 적어 주세요',
      };
      setState(() => _errors = e);
      if (e.isNotEmpty) return;
      final store = context.read<DemoStore>();
      if (job) {
        store.addJob(
          Job(
            side: _side,
            kind: _kind.trim().isEmpty ? '기타' : _kind.trim(),
            title: _title.trim(),
            meta: _meta.trim(),
            pay: _pay.trim().isEmpty ? '협의' : _pay.trim(),
            due: '방금',
          ),
        );
      } else {
        store.addPost(
          cat: _cat!,
          title: _title.trim(),
          body: _body.trim(),
          author: _cat == '익명 커뮤니티' ? '익명' : publicName(me),
          ownerUid: me?.uid,
          event: event
              ? EventInfo(
                  day: _day!,
                  when: [mdw(_day!), _time.trim()].where((x) => x.isNotEmpty).join(' '),
                  where: _where.trim(),
                  target: _target.trim().isEmpty ? '누구나' : _target.trim(),
                  cost: _cost.trim().isEmpty ? '무료' : _cost.trim(),
                  cap: cap!,
                  applied: 0,
                )
              : null,
        );
      }
      hideKeyboard();
      context.pop();
    }

    Widget field(String label, String key, String hint, ValueChanged<String> onChanged, {String? note, TextInputType? keyboard, int max = 60}) => Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(label, hint: note),
          AppTextField(
            key: ValueKey('field-$key'),
            fieldKey: Key(key),
            hint: hint,
            maxLength: max,
            keyboard: keyboard,
            error: _errors[key],
            onChanged: onChanged,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(leading: const BackOrHome(), title: const Text('글쓰기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const FieldLabel('카테고리'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in cats) OptionBox(c, pill: true, selected: _cat == c, onTap: () => setState(() => _cat = c))],
          ),
          ErrorText(_errors['cat']),
          if (_cat == '익명 커뮤니티')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('닉네임 대신 \'익명\'으로 올라가요.', style: AppText.small),
            ),
          if (job) ...[
            const SizedBox(height: 22),
            const FieldLabel('구분'),
            Row(
              children: [
                for (final (i, side) in ['구인', '구직'].indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: OptionBox(side, selected: _side == side, onTap: () => setState(() => _side = side)),
                  ),
                ],
              ],
            ),
          ],
          field('제목', 'postTitle', job ? '예) 초등 영어 파트 강사 모집 (주 3일)' : '제목을 적어 주세요', (v) => _title = v),
          if (event) ...[
            const SizedBox(height: 22),
            const FieldLabel('날짜'),
            OutlinedButton.icon(
              key: const Key('eventDay'),
              onPressed: _pickDay,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(_day == null ? '날짜 고르기' : mdw(_day!)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                alignment: Alignment.centerLeft,
                foregroundColor: _day == null ? AppColors.ink3 : AppColors.ink,
                side: BorderSide(color: _errors['day'] == null ? AppColors.line2 : AppColors.red, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
            ),
            ErrorText(_errors['day']),
            field('시간', 'eventTime', '예) 오전 10:00–11:30', (v) => _time = v, note: '(선택)'),
            field('장소', 'where', '예) 학원 3층 세미나실', (v) => _where = v),
            field('대상', 'target', '예) 초5–중2 학부모', (v) => _target = v, note: '(선택)'),
            field('비용', 'cost', '예) 무료 · 자녀 동반 가능', (v) => _cost = v, note: '(선택)'),
            field('정원', 'cap', '예) 40', (v) => _cap = v, keyboard: TextInputType.number, max: 3),
          ],
          if (job) ...[
            field('분야', 'kind', '예) 영어 · 파트타임', (v) => _kind = v, note: '(선택)'),
            field('근무 조건', 'meta', '예) 호계동 · 월·수·금 15–20시', (v) => _meta = v),
            field('급여', 'pay', '예) 시급 협의', (v) => _pay = v, note: '(선택)'),
          ],
          if (!job) ...[
            const SizedBox(height: 22),
            FieldLabel('내용', hint: event ? '(선택)' : null),
            AppTextField(
              key: const ValueKey('field-body'),
              fieldKey: const Key('postBody'),
              hint: event ? '진행 순서나 안내할 내용을 적어 주세요' : '궁금한 점이나 나누고 싶은 이야기를 적어 주세요',
              maxLength: 1000,
              maxLines: 6,
              error: _errors['body'],
              onChanged: (v) => _body = v,
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomAction(
        note: '시연용이라 이 휴대폰에서만 보여요.',
        child: AppButton('올리기', onPressed: submit),
      ),
    );
  }
}

/// 피그마 4-7 저장함
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<DemoStore>().posts.where((p) => p.saved).toList();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(leading: const BackOrHome(), title: const Text('저장함')),
      body: saved.isEmpty
          ? const EmptyView(icon: Icons.bookmark_border, title: '저장한 글이 없어요', message: '글 상세에서 오른쪽 위 책갈피를 누르면 여기에 모여요.')
          : ListView(padding: const EdgeInsets.only(top: 12), children: [for (final p in saved) PostCard(p)]),
    );
  }
}
