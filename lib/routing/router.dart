import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/user_repository.dart';
import '../data/services/auth_service.dart';
import '../domain/models/academy.dart';
import '../domain/models/user_profile.dart';
import '../ui/features/academy/academy_detail_screen.dart';
import '../ui/features/consult/consult_screens.dart';
import '../ui/features/home/views/home_screen.dart';
import '../ui/features/home/views/results_screen.dart';
import '../ui/features/manage/class_edit_screen.dart';
import '../ui/features/lounge/lounge_screens.dart';
import '../ui/features/manage/manage_screen.dart';
import '../ui/features/manage/staff_tools.dart';
import '../ui/features/my/my_screen.dart';
import '../ui/features/my/plans_screen.dart';
import '../ui/features/notebook/notebook_screens.dart';
import '../ui/features/onboarding/view_models/signup_view_model.dart';
import '../ui/features/onboarding/views/login_screen.dart';
import '../ui/features/onboarding/views/role_select_screen.dart';
import '../ui/features/onboarding/views/signup_screen.dart';
import '../ui/features/session/session_view_model.dart';
import '../ui/features/shell/app_shell.dart';

/// 화면 주소표. 로그인 전에는 /start · /signup · /login 만 열리고, 로그인하면 역할의 첫 탭으로 간다.
GoRouter buildRouter(SessionViewModel session) {
  const outside = ['/start', '/signup', '/login'];
  GoRoute tab(String path, Widget screen) => GoRoute(path: path, builder: (_, _) => screen);
  StatefulShellBranch branch(GoRoute r) => StatefulShellBranch(routes: [r]);

  return GoRouter(
    initialLocation: '/start',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isOutside = outside.any(loc.startsWith);
      // 가입 제출 중에는 화면을 옮기지 않는다. 끝나면 세션이 상태를 다시 계산해 알린다.
      if (session.signingUp) return null;
      return switch (session.status) {
        // 가입 · 로그인 화면에서는 로딩 때문에 화면을 옮기지 않는다(입력값을 잃는다).
        SessionStatus.loading => isOutside || loc == '/loading' ? null : '/loading',
        SessionStatus.signedOut => isOutside ? null : '/start',
        SessionStatus.signedIn when isOutside || loc == '/loading' => session.profile!.role == UserRole.staff ? '/manage' : '/home',
        SessionStatus.signedIn => null,
      };
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/start', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/signup/:role',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => SignupViewModel(
            role: UserRole.values.byName(state.pathParameters['role']!),
            auth: context.read<AuthService>(),
            users: context.read<UserRepository>(),
            session: session,
          ),
          child: const SignupScreen(),
        ),
      ),
      // 순서는 AppTab 과 같다.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          branch(tab('/home', const HomeScreen())),
          branch(tab('/lounge', const LoungeScreen())),
          branch(tab('/consult', const ConsultListScreen())),
          branch(tab('/notebook', const NotebookScreen())),
          branch(tab('/my', const MyScreen())),
          branch(tab('/manage', const ManageScreen())),
        ],
      ),
      // ?search=1 은 홈 검색창을 눌러 들어왔을 때만 붙인다(그때만 키보드를 바로 띄운다).
      GoRoute(
        path: '/results',
        builder: (_, state) => ResultsScreen(focusSearch: state.uri.queryParameters['search'] == '1'),
      ),
      GoRoute(
        path: '/academy/:id',
        builder: (_, state) => AcademyDetailScreen(id: state.pathParameters['id']!),
      ),
      // 반 추가 · 수정. 고칠 반은 extra 로 받는다(없으면 새 반).
      GoRoute(
        path: '/class',
        redirect: (_, _) => session.profile?.role == UserRole.staff ? null : '/home',
        builder: (_, state) => ClassEditScreen(initial: state.extra as AcademyClass?),
      ),
      GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
      // 시연 화면(라운지 · 상담 · 알림 · 학원 관계자 도구). 데이터는 DemoStore(앱 메모리)
      GoRoute(path: '/post/:id', builder: (_, s) => PostScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/write', builder: (_, _) => const WritePostScreen()),
      GoRoute(path: '/saved', builder: (_, _) => const SavedScreen()),
      GoRoute(
        path: '/consult/new',
        redirect: (_, _) => session.profile?.role == UserRole.parent ? null : '/home',
        builder: (_, s) => ConsultCardScreen(academy: s.extra as String?),
      ),
      GoRoute(path: '/chat/:id', builder: (_, s) => ChatScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/ai/:id', builder: (_, s) => AiNoteScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(
        path: '/staff/attendance',
        redirect: (_, _) => session.profile?.role == UserRole.staff ? null : '/home',
        builder: (_, _) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/staff/send',
        redirect: (_, _) => session.profile?.role == UserRole.staff ? null : '/home',
        builder: (_, s) => SendNoticeScreen(academy: s.extra as String? ?? '우리 학원'),
      ),
    ],
  );
}
