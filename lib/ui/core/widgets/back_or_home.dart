import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_profile.dart';
import '../../features/session/session_view_model.dart';

/// 하위 화면 앱바의 왼쪽 버튼. 돌아갈 화면이 있으면 뒤로, 없으면(웹에서 주소로 바로 들어오거나 새로고침) 첫 탭으로.
class BackOrHome extends StatelessWidget {
  const BackOrHome({super.key});

  @override
  Widget build(BuildContext context) {
    if (GoRouter.maybeOf(context) == null || Navigator.of(context).canPop()) return const BackButton();
    final staff = context.watch<SessionViewModel>().profile?.role == UserRole.staff;
    return IconButton(tooltip: '홈으로', icon: const Icon(Icons.home_outlined), onPressed: () => context.go(staff ? '/manage' : '/home'));
  }
}
