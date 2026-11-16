import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/academy_repository.dart';
import '../../../domain/models/academy.dart';
import '../../../domain/models/demo.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/theme.dart';
import '../../core/widgets/academy_tile.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/form_bits.dart';
import '../demo/demo_store.dart';
import '../lounge/lounge_screens.dart' show publicName;
import '../session/session_view_model.dart';
import 'class_fee_table.dart';
import '../../core/widgets/back_or_home.dart';

/// 피그마 3-1 · 3-2 · 3-3 학원 상세. 정보 · 가격 · 리뷰 탭(소식 · 시간표는 없다). 리뷰는 시연용(앱 메모리).
class AcademyDetailScreen extends StatefulWidget {
  const AcademyDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<AcademyDetailScreen> createState() => _AcademyDetailScreenState();
}

class _AcademyDetailScreenState extends State<AcademyDetailScreen> {
  late Future<Academy?> _academy = context.read<AcademyRepository>().byId(widget.id);
  late final _classes = context.read<AcademyRepository>().classesOf(widget.id);
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _academy,
      builder: (context, snap) {
        final a = snap.data;
        return Scaffold(
          appBar: AppBar(leading: const BackOrHome(), title: Text(a?.name ?? '')),
          body: switch (snap.connectionState) {
            ConnectionState.done when a != null => ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Header(a),
                _Tabs(labels: ['정보', '가격', '리뷰 ${context.watch<DemoStore>().reviewsOf(a.id).length}'], selected: _tab, onTap: (i) => setState(() => _tab = i)),
                switch (_tab) {
                  0 => _InfoTab(a),
                  1 => _PriceTab(a, _classes),
                  _ => _ReviewTab(a),
                },
              ],
            ),
            ConnectionState.done when snap.hasError => EmptyView(
              icon: Icons.wifi_off,
              title: '학원 정보를 불러오지 못했어요',
              message: '인터넷 연결을 확인하고 다시 시도해 주세요.',
              action: AppButton(
                '다시 시도',
                height: 44,
                expand: false,
                onPressed: () => setState(() => _academy = context.read<AcademyRepository>().byId(widget.id)),
              ),
            ),
            ConnectionState.done => const EmptyView(icon: Icons.search_off, title: '학원을 찾지 못했어요', message: '목록이 바뀌었을 수 있어요. 다시 검색해 주세요.'),
            _ => const Center(child: CircularProgressIndicator()),
          },
          bottomNavigationBar: a == null ? null : _BottomButtons(a),
        );
      },
    );
  }
}

Future<void> _open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

Uri _webUri(String web) => Uri.parse(web.startsWith('http') ? web : 'https://$web');

class _Header extends StatelessWidget {
  const _Header(this.a);

  final Academy a;

  @override
  Widget build(BuildContext context) {
    final kicker = [if (a.subjects.isNotEmpty) a.subjects.take(3).join('·'), a.ageText, a.sizeText].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AcademyTile(a, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.pri),
                    ),
                    const SizedBox(height: 3),
                    Text(a.name, style: AppText.h2.copyWith(fontSize: 21, height: 1.3)),
                    const SizedBox(height: 2),
                    Text(a.dong, style: AppText.small.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 피그마의 밑줄 탭
/// 학부모는 상담 카드(피그마 3-1 하단), 모두에게 전화 문의
class _BottomButtons extends StatelessWidget {
  const _BottomButtons(this.a);

  final Academy a;

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<SessionViewModel>().profile?.role == UserRole.parent;
    final call = a.phone.isEmpty ? null : () => _open(Uri(scheme: 'tel', path: a.phone));
    if (!parent && call == null) return const SizedBox.shrink();
    return BottomAction(
      child: Row(
        children: [
          if (call != null)
            Expanded(
              flex: parent ? 2 : 1,
              child: AppButton(parent ? '전화' : '전화 문의', icon: Icons.call, tone: parent ? ButtonTone.outline : ButtonTone.primary, onPressed: call),
            ),
          if (call != null && parent) const SizedBox(width: 10),
          if (parent)
            Expanded(
              flex: 3,
              child: AppButton('상담 카드 보내기', onPressed: () => context.push('/consult/new', extra: a.name)),
            ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.labels, required this.selected, required this.onTap});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (final (i, t) in labels.indexed)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: i == selected ? AppColors.ink : Colors.transparent, width: 2.5)),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: i == selected ? FontWeight.w800 : FontWeight.w500,
                      color: i == selected ? AppColors.ink : AppColors.ink3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab(this.a);

  final Academy a;

  @override
  Widget build(BuildContext context) {
    const unknown = Text('미정', style: TextStyle(fontSize: 15, color: AppColors.ink3));
    Widget text(String v) => v.isEmpty ? unknown : Text(v, style: const TextStyle(fontSize: 15, height: 1.45));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Fact('주소', text(a.addr)),
          _Fact('전화', text(a.phone)),
          if (a.web.isNotEmpty)
            _Fact(
              '홈페이지',
              GestureDetector(
                onTap: () => _open(_webUri(a.web)),
                child: Text(
                  a.web.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: AppColors.pri, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          _Fact(
            '셔틀',
            a.shuttle == true
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Tag('운행', tone: TagTone.green),
                  )
                : unknown,
          ),
          _Fact('대상 나이', text(a.levels.isEmpty && !a.adult ? '' : a.ageText)),
          _Fact('과목', text(a.subjects.join(' · '))),
          _Fact('규모', text(a.size)),
          if (a.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('특징', style: AppText.title),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final t in a.tags) Tag(t, tone: TagTone.gray)]),
          ],
          const SizedBox(height: 22),
          const Text('미정인 항목과 바뀐 정보는 학원에 직접 확인해 주세요.', style: AppText.small),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: const TextStyle(fontSize: 15, color: AppColors.ink3, height: 1.45)),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class _PriceTab extends StatelessWidget {
  const _PriceTab(this.a, this.classes);

  final Academy a;
  final Stream<List<AcademyClass>> classes;

  @override
  Widget build(BuildContext context) {
    final fee = a.fee;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder(
            stream: classes,
            builder: (context, snap) {
              final classes = snap.data ?? const <AcademyClass>[];
              final updated = classes.map((c) => c.updatedAt).whereType<DateTime>().fold<DateTime?>(null, (m, d) => m == null || d.isAfter(m) ? d : m);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(child: Text('반별 수강료', style: AppText.h2)),
                      if (updated != null)
                        Flexible(
                          child: Text('학원 직접 등록 · ${updated.month}/${updated.day} 수정', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snap.hasError)
                    const InfoBox('수강료를 불러오지 못했어요. 잠시 후 다시 열어 주세요.')
                  else if (!snap.hasData)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (classes.isEmpty)
                    const InfoBox('학원에서 아직 반별 수강료를 등록하지 않았어요. 아래 교육청 등록 교습비를 참고해 주세요.')
                  else
                    ClassFeeTable(classes),
                ],
              );
            },
          ),
          const SizedBox(height: 34),
          const Text('교육청 등록 교습비', style: AppText.h2),
          const SizedBox(height: 12),
          if (fee == null || fee.min == null)
            const InfoBox('교육청에 등록된 교습비 정보가 없어요. 학원에 직접 문의해 주세요.')
          else ...[
            Text(
              fee.max == null || fee.max == fee.min ? '월 ${won(fee.min!)}' : '월 ${won(fee.min!)} ~ ${won(fee.max!)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              '경기도교육청 등록 기준${fee.date.isEmpty ? '' : ' · ${fee.date.replaceAll('-', '.')} 적용'}. 실제 수강료와 다를 수 있어요.',
              style: AppText.small.copyWith(height: 1.45),
            ),
            if (fee.extra.isNotEmpty) ...[const SizedBox(height: 4), Text('기타경비: ${fee.extra}', style: AppText.small.copyWith(height: 1.45))],
            if (a.courses.isNotEmpty) ...[const SizedBox(height: 16), for (final c in a.courses) _CourseRow(c)],
          ],
        ],
      ),
    );
  }
}

/// 교육청 등록 교습과정 한 줄
class _CourseRow extends StatelessWidget {
  const _CourseRow(this.c);

  final Course c;

  @override
  Widget build(BuildContext context) {
    final sub = [c.level, c.subject, if (c.cap != null) '정원 ${c.cap}명'].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (sub.isNotEmpty) Text(sub, style: AppText.small),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            c.monthly == null ? '-' : won(c.monthly!),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

/// 피그마 3-3 리뷰. 시연용이라 앱 메모리에만 남는다. 실제 학원에 가짜 후기가 붙지 않도록 예시 리뷰는 넣지 않는다.
class _ReviewTab extends StatelessWidget {
  const _ReviewTab(this.a);

  final Academy a;

  Future<void> _write(BuildContext context) async {
    final store = context.read<DemoStore>();
    final nick = publicName(context.read<SessionViewModel>().profile);
    final r = await showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(nick: nick),
    );
    if (r != null) store.addReview(a.id, r);
  }

  @override
  Widget build(BuildContext context) {
    final list = context.watch<DemoStore>().reviewsOf(a.id);
    final avg = list.isEmpty ? 0.0 : list.map((r) => r.stars).reduce((x, y) => x + y) / list.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(list.isEmpty ? '-' : avg.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Stars(avg.round()),
                    Text('리뷰 ${list.length}개 · 시연용(이 휴대폰에만 저장)', style: AppText.small),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton('리뷰 쓰기', icon: Icons.edit_outlined, tone: ButtonTone.outline, height: 48, onPressed: () => _write(context)),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('아직 리뷰가 없어요. 첫 리뷰를 남겨 보세요.', textAlign: TextAlign.center, style: AppText.lead),
            ),
          for (final r in list)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r.nick, style: AppText.label),
                      const SizedBox(width: 8),
                      _Stars(r.stars, size: 15),
                      const Spacer(),
                      Text(ago(r.at), style: AppText.small),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.text, style: const TextStyle(fontSize: 15, height: 1.6)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.n, {this.size = 20});

  final int n;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [for (var i = 1; i <= 5; i++) Icon(i <= n ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.star)],
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.nick});

  final String nick;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _stars = 0;
  String _text = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('리뷰 쓰기', style: AppText.h2),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '별 $i개',
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 36, color: AppColors.star),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextField(fieldKey: const Key('review'), hint: '수업 · 숙제 · 소통은 어땠나요?', maxLength: 500, maxLines: 4, error: _error, onChanged: (v) => _text = v),
          const SizedBox(height: 16),
          AppButton(
            '올리기',
            onPressed: () {
              if (_stars == 0 || _text.trim().isEmpty) {
                setState(() => _error = '별점과 내용을 모두 남겨 주세요');
                return;
              }
              Navigator.pop(context, Review(stars: _stars, text: _text.trim(), nick: widget.nick, at: DateTime.now()));
            },
          ),
        ],
      ),
    );
  }
}
