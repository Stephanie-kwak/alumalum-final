import 'dart:typed_data';

import 'package:alumalum/data/repositories/academy_repository.dart';
import 'package:alumalum/data/repositories/user_repository.dart';
import 'package:alumalum/data/services/auth_service.dart';
import 'package:alumalum/domain/models/user_profile.dart';
import 'package:alumalum/ui/core/theme.dart';
import 'package:alumalum/ui/features/home/views/results_screen.dart';
import 'package:alumalum/ui/features/home/view_models/academy_search_view_model.dart';
import 'package:alumalum/ui/core/widgets/choices.dart';
import 'package:alumalum/ui/features/onboarding/view_models/signup_view_model.dart';
import 'package:alumalum/ui/features/onboarding/views/role_select_screen.dart';
import 'package:alumalum/ui/features/onboarding/views/signature_pad.dart';
import 'package:alumalum/ui/features/onboarding/views/signup_screen.dart';
import 'package:alumalum/ui/features/session/session_view_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('1-1 회원 유형: 고른 카드에만 체크가 붙는다', (t) async {
    await t.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const RoleSelectScreen()));
    expect(find.text('어떤 분이신가요?'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await t.tap(find.text('학생'));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    final studentCard = find.ancestor(of: find.text('학생'), matching: find.byType(InkWell)).first;
    expect(find.descendant(of: studentCard, matching: find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('1-2 기본 정보: 빈 채로 다음을 누르면 칸 아래에 오류가 보인다', (t) async {
    // 피그마 프레임과 같은 390 × 844 폰 화면
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final db = FakeFirebaseFirestore();
    final auth = AuthService(MockFirebaseAuth());
    final users = UserRepository(db);
    final vm = SignupViewModel(
      role: UserRole.parent,
      auth: auth,
      users: users,
      session: SessionViewModel(auth: auth, users: users),
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: AcademyRepository(db)),
          ChangeNotifierProvider.value(value: vm),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const SignupScreen()),
      ),
    );
    expect(find.text('학부모로 가입 중'), findsOneWidget);
    await t.tap(find.text('인증하고 다음'));
    await t.pump();
    expect(find.text('영문 · 숫자 4–20자, 한글은 2–10자로 적어 주세요'), findsOneWidget);
    expect(find.text('010-0000-0000 형식으로 적어 주세요'), findsOneWidget);

    await t.enterText(find.byKey(const Key('phone')), '010-1234-5678');
    await t.tap(find.text('인증하고 다음'));
    await t.pump();
    expect(find.text('휴대폰 번호를 적고 인증 요청을 눌러 주세요'), findsOneWidget, reason: '형식은 맞는데 인증 요청을 안 한 경우');
    await t.tap(find.text('인증 요청'));
    await t.pump();
    expect(find.byKey(const Key('code')), findsOneWidget);
    expect(find.text('재요청'), findsOneWidget);
  });

  testWidgets('알약 선택 상자는 줄바꿈 배치 안에서 글자 너비만큼만 차지한다 (실기기에서 가로로 늘어나던 문제)', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Wrap(
            children: [
              for (final a in ['호계', '비산']) OptionBox(a, pill: true, selected: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    final w = t.getSize(find.widgetWithText(OptionBox, '호계')).width;
    expect(w, lessThan(120));
    expect(t.getTopLeft(find.text('비산')).dy, t.getTopLeft(find.text('호계')).dy, reason: '두 칩이 한 줄에 나란히 있어야 한다');
  });

  testWidgets('자녀 추가 시트를 닫아도 닉네임 칸에 포커스가 돌아가지 않는다 (실기기에서 키보드가 다시 뜨던 문제)', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final db = FakeFirebaseFirestore();
    final auth = AuthService(MockFirebaseAuth());
    final users = UserRepository(db);
    final vm = SignupViewModel(
      role: UserRole.parent,
      auth: auth,
      users: users,
      session: SessionViewModel(auth: auth, users: users),
    )..step = 3;
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: AcademyRepository(db)),
          ChangeNotifierProvider.value(value: vm),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const SignupScreen()),
      ),
    );
    await t.tap(find.byKey(const Key('nick')));
    await t.pump();
    expect(t.testTextInput.isVisible, isTrue, reason: '닉네임 칸을 누르면 키보드가 뜬다');
    await t.tap(find.text('자녀 추가'));
    await t.pumpAndSettle();
    await t.tap(find.text('초3'));
    await t.tap(find.text('여'));
    await t.pump();
    await t.tap(find.text('추가하기'));
    await t.pumpAndSettle();
    expect(vm.kids.single.grade, '초3');
    expect(t.testTextInput.isVisible, isFalse, reason: '시트를 닫은 뒤 키보드가 다시 뜨면 안 된다');
  });

  testWidgets('서명은 칸 안에만 그려진다: 칸 밖까지 끌어도 칸 모양으로 잘리고 서명은 저장된다 (실기기에서 화면 전체에 그려지던 문제)', (t) async {
    Uint8List? saved;
    await t.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                SignaturePad(onChanged: (b) => saved = b),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pump();
    final pad = find.byType(SignaturePad);
    expect(find.descendant(of: pad, matching: find.byType(ClipRRect)), findsOneWidget);
    final start = t.getCenter(pad);
    final g = await t.startGesture(start);
    await g.moveBy(const Offset(0, 300));
    await g.moveBy(const Offset(500, 0));
    await g.up();
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await t.pump();
    expect(saved, isNotNull);
  });

  testWidgets('검색 결과의 정렬을 누르면 목록이 펼쳐지고 고른 정렬로 바뀐다', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final db = FakeFirebaseFirestore();
    await db.collection('academies').doc('A001').set({
      'name': '가온수학',
      'area': '호계',
      'subjects': ['수학'],
      'levels': <String>[],
      'tags': <String>[],
    });
    final vm = AcademySearchViewModel(AcademyRepository(db));
    await vm.load();
    await t.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: MaterialApp(theme: buildAppTheme(), home: const ResultsScreen()),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('추천순'));
    await t.pumpAndSettle();
    expect(find.text('리뷰 많은 순'), findsOneWidget);
    expect(find.text('이름순'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget, reason: '지금 정렬(추천순)에만 체크');
    await t.tap(find.text('이름순'));
    await t.pumpAndSettle();
    expect(vm.sort, '이름순');
    expect(find.text('리뷰 많은 순'), findsNothing, reason: '고르면 목록이 닫힌다');
  });
}
