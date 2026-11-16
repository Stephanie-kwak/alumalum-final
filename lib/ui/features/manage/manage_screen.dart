import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/academy_repository.dart';
import '../../../domain/models/academy.dart';
import '../../core/theme.dart';
import '../../core/widgets/academy_tile.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/form_bits.dart';
import '../academy/class_fee_table.dart';
import '../session/session_view_model.dart';

/// 학원 관계자 첫 탭 '내 학원'. 지금은 반별 수강료 관리만 있다.
class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  String? _loadedFor;
  Future<Academy?>? _academy;
  Stream<List<AcademyClass>>? _classes;

  @override
  Widget build(BuildContext context) {
    final academyId = context.watch<SessionViewModel>().profile?.academyId ?? '';
    final repo = context.read<AcademyRepository>();
    // 로그아웃하는 순간 프로필이 먼저 빈다. 빈 학원 ID 로는 조회하지 않는다.
    if (academyId.isEmpty) return const SizedBox.shrink();
    if (_loadedFor != academyId) {
      _loadedFor = academyId;
      _academy = repo.byId(academyId);
      _classes = repo.classesOf(academyId);
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('내 학원', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        titleSpacing: 20,
      ),
      body: FutureBuilder(
        future: _academy,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return EmptyView(
              icon: Icons.wifi_off,
              title: '학원 정보를 불러오지 못했어요',
              message: '인터넷 연결을 확인하고 다시 시도해 주세요.',
              action: AppButton('다시 시도', height: 44, expand: false, onPressed: () => setState(() => _loadedFor = null)),
            );
          }
          final a = snap.data;
          if (a == null) {
            return const EmptyView(
              icon: Icons.apartment_outlined,
              title: '소속 학원을 찾지 못했어요',
              message: '학원 목록이 바뀌어 가입 때 고른 학원이 없어요. 새 계정으로 다시 가입해 주세요.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Material(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  onTap: () => context.push('/academy/${a.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AcademyTile(a, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.name, style: AppText.title),
                              Text('${a.dong} · 학원 상세 보기', style: AppText.small.copyWith(fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.ink4),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.card)),
                child: StreamBuilder(
                  stream: _classes,
                  builder: (context, s) {
                    final classes = s.data ?? const <AcademyClass>[];
                    void edit([AcademyClass? c]) => context.push('/class', extra: c);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('반별 수강료', style: AppText.h2),
                        const SizedBox(height: 4),
                        const Text('학원 상세의 가격 탭에 그대로 보여요. 반을 눌러 고칠 수 있어요.', style: AppText.small),
                        const SizedBox(height: 14),
                        if (s.hasError)
                          const InfoBox('수강료를 불러오지 못했어요. 잠시 후 다시 열어 주세요.')
                        else if (!s.hasData)
                          const Center(child: CircularProgressIndicator())
                        else if (classes.isEmpty)
                          const InfoBox('아직 등록한 반이 없어요. 반을 추가하면 학부모가 학원 상세에서 바로 볼 수 있어요.')
                        else
                          ClassFeeTable(classes, onTap: edit),
                        const SizedBox(height: 14),
                        AppButton('반 추가', icon: Icons.add, tone: ButtonTone.outline, height: 48, onPressed: s.hasError ? null : edit),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Tool(icon: Icons.how_to_reg_outlined, title: '오늘 출결', sub: '등원 · 하원 입력', onTap: () => context.push('/staff/attendance')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Tool(icon: Icons.campaign_outlined, title: '알림장 보내기', sub: '숙제 · 코멘트 · 긴급 안내', onTap: () => context.push('/staff/send', extra: a.name)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 내 학원의 관리 도구 타일(시연)
class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.title, required this.sub, required this.onTap});

  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.priLight, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: AppColors.pri),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              Text(sub, style: AppText.small),
            ],
          ),
        ),
      ),
    );
  }
}
