import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/user_profile.dart';
import '../../core/theme.dart';
import '../session/session_view_model.dart';

/// 라우터의 탭 순서. router.dart 의 StatefulShellBranch 순서와 같아야 한다.
enum AppTab {
  home('홈', Icons.home_outlined, Icons.home),
  lounge('라운지', Icons.grid_view_outlined, Icons.grid_view_rounded),
  consult('상담', Icons.chat_bubble_outline, Icons.chat_bubble),
  notebook('알림장', Icons.book_outlined, Icons.book),
  my('MY', Icons.person_outline, Icons.person),
  manage('내 학원', Icons.apartment_outlined, Icons.apartment);

  const AppTab(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// 역할마다 보이는 탭. 학원 관계자의 '상담' 탭 이름은 '상담함'.
List<AppTab> tabsOf(UserRole role) => switch (role) {
  UserRole.parent => [AppTab.home, AppTab.lounge, AppTab.consult, AppTab.notebook, AppTab.my],
  UserRole.student => [AppTab.home, AppTab.lounge, AppTab.notebook, AppTab.my],
  UserRole.staff => [AppTab.manage, AppTab.consult, AppTab.lounge, AppTab.my],
};

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionViewModel>().profile?.role ?? UserRole.parent;
    final tabs = tabsOf(role);
    final current = AppTab.values[shell.currentIndex];
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.paper,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (s) => TextStyle(
                fontSize: 11.5,
                fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
                color: s.contains(WidgetState.selected) ? AppColors.pri : AppColors.ink3,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(size: 25, color: s.contains(WidgetState.selected) ? AppColors.pri : AppColors.ink3),
            ),
          ),
          child: NavigationBar(
            height: 66,
            selectedIndex: tabs.contains(current) ? tabs.indexOf(current) : 0,
            onDestinationSelected: (i) {
              final idx = tabs[i].index;
              shell.goBranch(idx, initialLocation: idx == shell.currentIndex);
            },
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: role == UserRole.staff && t == AppTab.consult ? '상담함' : t.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 아직 만들지 않은 화면. 진짜 화면이 생기면 router.dart 에서 바꿔 끼운다.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, this.showBack = false});

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: showBack, titleSpacing: showBack ? 0 : 20),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 40, color: AppColors.ink4),
              const SizedBox(height: 12),
              Text(title, style: AppText.title),
              const SizedBox(height: 4),
              const Text('준비 중인 화면이에요', style: AppText.lead),
            ],
          ),
        ),
      ),
    );
  }
}
