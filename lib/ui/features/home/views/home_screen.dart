import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/demo.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/academy_tile.dart';
import '../../../core/widgets/choices.dart';
import '../../demo/demo_store.dart';
import '../../session/session_view_model.dart';
import '../../notebook/notebook_screens.dart';
import '../view_models/academy_search_view_model.dart';
import 'academy_cards.dart';
import 'filter_sheet.dart';

/// 피그마 2-1 홈 (탐색). '오늘의 알림장' 카드와 '이번 주 설명회 · 레벨테스트'는 시연용 예시 데이터(DemoStore).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _kid = 0;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AcademySearchViewModel>();
    final me = context.read<SessionViewModel>().profile!;
    // 그리는 도중에 상태 알림을 보내지 않도록 첫 화면을 그린 뒤에 계정 필터를 맞추고 불러온다
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.startFor(me.uid, me.area);
      vm.load();
    });
  }

  Future<void> _openFilter() async {
    final go = await showFilterSheet(context);
    if (go == true && mounted) context.push('/results');
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionViewModel>().profile;
    if (me == null) return const SizedBox.shrink();
    final vm = context.watch<AcademySearchViewModel>();
    final kids = me.role == UserRole.parent ? me.kids : const <Kid>[];
    final grade = me.role == UserRole.student ? me.grade : (kids.isEmpty ? null : kids[_kid.clamp(0, kids.length - 1)].grade);
    final area = vm.areas.length == 1 ? vm.areas.first : me.area;
    final picks = vm.recommendFor(area: area, kidGrade: grade, interests: me.interests);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.load(refresh: true),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: AppColors.paper,
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _openFilter,
                            child: Row(
                              children: [
                                Text(
                                  vm.areas.isEmpty
                                      ? '동안구 전체'
                                      : vm.areas.length == 1
                                      ? areaName(vm.areas.first)
                                      : '${areaName(vm.areas.first)} 외 ${vm.areas.length - 1}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                                const Icon(Icons.expand_more),
                              ],
                            ),
                          ),
                          const Spacer(),
                          BellButton(onPressed: () => context.push('/notifications')),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push('/results?search=1'),
                          child: const SizedBox(
                            height: 48,
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Icon(Icons.search, color: AppColors.ink2),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '학원명, 과목, 동 이름 검색',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.ink4, fontSize: 16),
                                  ),
                                ),
                                SizedBox(width: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          PillChip('', icon: Icons.tune, selected: false, onTap: _openFilter),
                          for (final (i, k) in kids.indexed) ...[
                            const SizedBox(width: 8),
                            PillChip(k.label, selected: _kid == i, onTap: () => setState(() => _kid = i)),
                          ],
                          for (final s in me.interests) ...[
                            const SizedBox(width: 8),
                            PillChip(
                              s,
                              selected: false,
                              onTap: () {
                                vm.setSubject(s);
                                context.push('/results');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _TodayCard(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 8, 12),
                child: Row(
                  children: [
                    Expanded(child: Text('${grade ?? '우리 아이'}에게 맞는 동네 학원', style: AppText.h2)),
                    TextButton(
                      onPressed: () => context.push('/results'),
                      child: const Text('전체보기', style: TextStyle(color: AppColors.ink3)),
                    ),
                  ],
                ),
              ),
              if (vm.loading)
                const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              else if (vm.error != null)
                EmptyView(icon: Icons.wifi_off, title: vm.error!, message: '아래로 당겨 다시 불러와 주세요')
              else if (picks.isEmpty)
                const EmptyView(icon: Icons.school_outlined, title: '이 동네 학원이 아직 없어요', message: '필터에서 다른 권역을 골라 보세요')
              else
                SizedBox(
                  // 그림 96 + 글자 세 줄. 글씨를 키운 휴대폰에서도 카드 아래가 잘리지 않게 배율만큼 늘린다
                  height: 96 + MediaQuery.textScalerOf(context).scale(100),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: picks.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => AcademyCard(picks[i]),
                  ),
                ),
              const _EventsSection(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// 피그마 2-1 '오늘의 알림장' 카드 (시연용)
class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final now = DateTime.now();
    final today = store.lessons.where((l) => l.days.contains(now.weekday)).toList()..sort((a, b) => a.start.compareTo(b.start));
    final left = store.homework.where((h) => !h.comment && !h.done).length;
    final comments = store.homework.where((h) => h.comment).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.go('/notebook'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 알림장 · ${now.month}월 ${now.day}일 ${'월화수목금토일'[now.weekday - 1]}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8EA7FF)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        today.isEmpty ? '오늘은 수업이 없어요' : today.map((l) => '${l.label} ${l.start}').join(' · '),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text('숙제 $left개 남음 · 선생님 코멘트 $comments개', style: const TextStyle(fontSize: 14, color: Color(0xFFC9CED8))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 피그마 2-1 '이번 주 설명회 · 레벨테스트' (라운지의 행사 글, 시연용)
class _EventsSection extends StatelessWidget {
  const _EventsSection();

  @override
  Widget build(BuildContext context) {
    final events = context.watch<DemoStore>().posts.where((p) => p.event != null).toList()..sort((a, b) => a.event!.day.compareTo(b.event!.day));
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 8, 12),
          child: Row(
            children: [
              const Expanded(child: Text('다가오는 설명회 · 레벨테스트', style: AppText.h2)),
              TextButton(
                onPressed: () => context.go('/lounge'),
                child: const Text('라운지', style: TextStyle(color: AppColors.ink3)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.card),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [for (final (i, p) in events.take(3).indexed) _EventRow(p, first: i == 0)]),
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.p, {required this.first});

  final LoungePost p;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final e = p.event!;
    final (bg, fg) = p.cat == '레벨테스트' ? (AppColors.greenLight, AppColors.green) : (AppColors.priLight, AppColors.pri);
    return InkWell(
      onTap: () => context.push('/post/${p.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: first
            ? null
            : const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
        child: Row(
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '월화수목금토일'[e.day.weekday - 1],
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                  ),
                  Text(
                    '${e.day.day}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg, height: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.cat,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
                  ),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${p.author} · 신청 ${e.applied}/${e.cap}명',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
