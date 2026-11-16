import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user_profile.dart';
import '../../core/theme.dart';
import '../home/view_models/academy_search_view_model.dart';
import '../session/session_view_model.dart';

/// MY. 피그마에 없는 화면이라 시안 A의 MY 를 따른다. 프로필 · 자녀 연결 코드 · 요금제 안내 · 로그아웃.
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  /// 세션이 바뀔 때마다 다시 읽지 않도록 한 번만 읽어 둔다.
  Future<String?>? _linkCode;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    // 로그아웃 순간 프로필이 먼저 비고 화면은 잠깐 남아 있다.
    final me = session.profile;
    if (me == null) return const SizedBox.shrink();
    if (me.role == UserRole.parent) _linkCode ??= context.read<UserRepository>().linkCodeOf(me.uid);
    final sub = switch (me.role) {
      UserRole.parent => [...me.kids.map((k) => k.label), areaName(me.area)].where((s) => s.isNotEmpty).join(' · '),
      UserRole.staff => me.position ?? '',
      UserRole.student => me.grade ?? '',
    };
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('MY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        titleSpacing: 20,
      ),
      body: ListView(
        children: [
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.priLight,
                  child: Text(
                    me.name.isEmpty ? '?' : me.name[0],
                    style: const TextStyle(color: AppColors.pri, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('${me.role.label}${sub.isEmpty ? '' : ' · $sub'}', style: AppText.small.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.card),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (me.role == UserRole.parent)
                    ListTile(
                      leading: const Icon(Icons.link, color: AppColors.ink2),
                      title: const Text('자녀 연결 코드'),
                      subtitle: const Text('학생 계정 가입 때 이 코드를 넣으면 연결돼요'),
                      trailing: FutureBuilder(
                        future: _linkCode,
                        builder: (_, s) =>
                            Text(s.hasError ? '다시 열어 주세요' : s.data ?? '…', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.ink2),
                    title: const Text('알음알음 요금제'),
                    subtitle: const Text('PLUS · BIZ 안내'),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.ink4),
                    onTap: () => context.push('/plans'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.ink2),
                    title: const Text('로그아웃'),
                    onTap: session.signOut,
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
