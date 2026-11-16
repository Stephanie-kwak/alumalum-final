import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/user_profile.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/form_bits.dart';
import 'signup_progress.dart';

/// 피그마 1-1 회원 유형 선택
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole _role = UserRole.parent;

  static const _roles = [
    (UserRole.parent, '학원 찾기 · 상담 · 자녀 알림장·출결 확인', Icons.people_alt_outlined),
    (UserRole.staff, '원장 · 강사 · 실장 — 학원 등록, 홍보, 알림장 발송', Icons.apartment_outlined),
    (UserRole.student, '시간표 · 숙제 확인 · 선생님께 질문하기', Icons.menu_book_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SignupProgress(step: 1, showLogo: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
                children: [
                  const Text('어떤 분이신가요?', style: AppText.h1),
                  const SizedBox(height: 6),
                  const Text('회원 유형에 맞춰 첫 화면과 알림을 준비해 드려요.', style: AppText.lead),
                  const SizedBox(height: 26),
                  for (final (role, desc, icon) in _roles) ...[
                    _RoleCard(role: role, desc: desc, icon: icon, selected: _role == role, onTap: () => setState(() => _role = role)),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                  const InfoBox('학생 계정은 가입 후 보호자 계정과 연결하면 알림장과 출결 알림을 함께 받아볼 수 있어요.'),
                ],
              ),
            ),
            BottomAction(
              line: false,
              child: Column(
                children: [
                  AppButton('다음', onPressed: () => context.push('/signup/${_role.name}')),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text.rich(
                      TextSpan(
                        text: '이미 계정이 있나요? ',
                        style: TextStyle(color: AppColors.ink3, fontSize: 15),
                        children: [
                          TextSpan(
                            text: '로그인',
                            style: TextStyle(color: AppColors.pri, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.desc, required this.icon, required this.selected, required this.onTap});

  final UserRole role;
  final String desc;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.priLight : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: selected ? AppColors.pri : AppColors.line2, width: selected ? 2 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: selected ? AppColors.pri : AppColors.fill, borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: selected ? Colors.white : AppColors.ink, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontSize: 13.5, color: AppColors.ink3, height: 1.45)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.pri : null,
                  border: Border.all(color: selected ? AppColors.pri : AppColors.line2, width: 1.5),
                ),
                child: selected ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
