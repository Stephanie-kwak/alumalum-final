import 'package:alumalum/data/repositories/academy_repository.dart';
import 'package:alumalum/data/repositories/user_repository.dart';
import 'package:alumalum/data/services/auth_service.dart';
import 'package:alumalum/domain/models/demo.dart';
import 'package:alumalum/domain/models/user_profile.dart';
import 'package:alumalum/routing/router.dart';
import 'package:alumalum/ui/core/theme.dart';
import 'package:alumalum/ui/core/widgets/choices.dart';
import 'package:alumalum/ui/features/demo/demo_store.dart';
import 'package:alumalum/ui/features/home/view_models/academy_search_view_model.dart';
import 'package:alumalum/ui/features/onboarding/view_models/signup_view_model.dart';
import 'package:alumalum/ui/features/session/session_view_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _reply = Duration(milliseconds: 100);

GoRouter? _router;

/// 실제 라우터로 앱 전체를 띄운다. [role] 계정으로 로그인한 상태.
/// [width] · [textScale] 로 작은 휴대폰 · 큰 글씨를 흉내 내고, [store] 를 넘기면 같은 휴대폰에서 계정만 바꾼 상황.
Future<DemoStore> _app(WidgetTester t, UserRole role, {String uid = 'u1', double width = 390, double textScale = 1, DemoStore? store}) async {
  t.view.physicalSize = Size(width * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final db = FakeFirebaseFirestore();
  await db.collection('academies').doc('H001').set({
    'name': '가온수학',
    'size': '소형',
    'subjects': ['수학'],
    'levels': ['초3-4'],
    'dong': '평촌동',
    'area': '평촌 학원가',
    'addr': '',
    'phone': '031-000-0000',
  });
  await db.collection('users').doc(uid).set({
    'role': role.name,
    'loginId': 'tester01',
    'name': role == UserRole.staff ? '김원장' : '평촌 초3맘',
    'area': role == UserRole.parent ? '평촌 학원가' : '',
    'plus': false,
    if (role == UserRole.parent) ...{
      'kids': [
        {'order': '첫째', 'grade': '초3', 'birthYear': 2017, 'sex': '여'},
      ],
      'interests': ['수학'],
    },
    if (role == UserRole.staff) ...{'academyId': 'H001', 'position': '원장', 'verified': false},
    if (role == UserRole.student) ...{'grade': '초3', 'parentUid': null, 'academyIds': <String>[]},
  });
  final auth = AuthService(
    MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, email: 'tester01@alumalum.app'),
    ),
  );
  final users = UserRepository(db);
  final academies = AcademyRepository(db);
  final session = SessionViewModel(auth: auth, users: users);
  store ??= DemoStore(replyDelay: _reply);
  final router = _router = buildRouter(session);
  await t.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: auth),
        Provider.value(value: users),
        Provider.value(value: academies),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => AcademySearchViewModel(academies)),
        ChangeNotifierProvider.value(value: store),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return store;
}

Future<void> _tab(WidgetTester t, String label) async {
  await t.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await t.pumpAndSettle();
}

void main() {
  test('한글 아이디: 영문 · 숫자는 그대로, 한글은 k. + UTF-8 16진수 (보안 규칙 테스트와 같은 값)', () {
    expect(AuthService.keyOf('Parent01'), 'parent01');
    expect(AuthService.keyOf('평촌맘'), 'k.ed8f89ecb48ceba798');
    expect(AuthService.emailOf('평촌맘'), 'k.ed8f89ecb48ceba798@alumalum.app');
    expect(AuthService.isValidLoginId('평촌맘'), isTrue);
    expect(AuthService.isValidLoginId('평'), isFalse, reason: '한글은 2자부터');
    expect(AuthService.isValidLoginId('가나다라마바사아자차카'), isFalse, reason: '한글은 10자까지(이메일 64자 제한)');
    expect(AuthService.isValidLoginId('abc'), isFalse);
    expect(AuthService.isValidLoginId('mom_01'), isFalse);
    expect('${AuthService.keyOf('가나다라마바사아자차')}@'.length, lessThanOrEqualTo(65));
    // 맥에서 복사한 자모 분리형(NFD) '평촌맘' 도 같은 키
    const nfd = '\u1111\u1167\u11BC\u110E\u1169\u11AB\u1106\u1161\u11B7';
    expect(AuthService.composeHangul(nfd), '평촌맘');
    expect(AuthService.keyOf(nfd), AuthService.keyOf('평촌맘'));
    expect(AuthService.isValidLoginId(nfd), isTrue);
  });

  test('학생 성인: 학년 숫자 없이 통과하고, 홈 추천은 성인 구간', () {
    final db = FakeFirebaseFirestore();
    final auth = AuthService(MockFirebaseAuth());
    final users = UserRepository(db);
    final vm =
        SignupViewModel(
            role: UserRole.student,
            auth: auth,
            users: users,
            session: SessionViewModel(auth: auth, users: users),
          )
          ..step = 3
          ..studentName = '김성인'
          ..level = '성인';
    vm.validate();
    expect(vm.errors['grade'], isNull);
    expect(ageOfGrade('성인'), '성인');
  });

  testWidgets('학부모 라운지: 피드 · 구인구직 · 설명회 신청, 글쓰기는 익명 커뮤니티만', (t) async {
    await _app(t, UserRole.parent);
    await _tab(t, '라운지');
    expect(find.text('2027 중등 수학 로드맵 설명회'), findsOneWidget);

    await t.tap(find.text('구인구직'));
    await t.pumpAndSettle();
    expect(find.text('중등 수학 전임 강사 (내신 담당)'), findsOneWidget);
    await t.tap(find.text('전체'));
    await t.pumpAndSettle();

    await t.tap(find.text('2027 중등 수학 로드맵 설명회'));
    await t.pumpAndSettle();
    expect(find.text('23 / 40명'), findsOneWidget);
    await t.tap(find.text('신청하기'));
    await t.pumpAndSettle();
    expect(find.text('24 / 40명'), findsOneWidget);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();

    await t.tap(find.byTooltip('글쓰기'));
    await t.pumpAndSettle();
    expect(find.text('개강·모집'), findsNothing, reason: '모집 · 홍보 글은 학원 관계자만');
    expect(find.text('교육팁'), findsOneWidget, reason: '학부모는 교육팁 · 익명 커뮤니티');
    expect(find.text('익명 커뮤니티'), findsOneWidget);
    await t.tap(find.text('익명 커뮤니티'));
    await t.pump();
    await t.enterText(find.byKey(const Key('postTitle')), '중1 영어 학원 고민');
    await t.enterText(find.byKey(const Key('postBody')), '문법 위주가 좋을까요?');
    await t.tap(find.text('올리기'));
    await t.pumpAndSettle();
    expect(find.text('중1 영어 학원 고민'), findsOneWidget);
    expect(find.text('내 글'), findsOneWidget);
  });

  testWidgets('학원 관계자 라운지: 9개 카테고리 전부, 설명회는 일정 · 정원, 구인구직은 근무 조건', (t) async {
    final store = await _app(t, UserRole.staff);
    await _tab(t, '라운지');
    await t.tap(find.byTooltip('글쓰기'));
    await t.pumpAndSettle();
    for (final c in DemoStore.lounges) {
      expect(find.widgetWithText(OptionBox, c), findsOneWidget, reason: c);
    }

    await t.tap(find.widgetWithText(OptionBox, '설명회'));
    await t.pumpAndSettle();
    await t.tap(find.text('올리기'));
    await t.pump();
    expect(find.text('날짜를 골라 주세요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('postTitle')), '겨울방학 설명회');
    await t.tap(find.byKey(const Key('eventDay')));
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('where')), '3층 세미나실');
    await t.dragUntilVisible(find.byKey(const Key('cap')), find.byType(ListView).last, const Offset(0, -200));
    await t.enterText(find.byKey(const Key('cap')), '30');
    await t.tap(find.text('올리기'));
    await t.pumpAndSettle();
    final ev = store.posts.first;
    expect(ev.title, '겨울방학 설명회');
    expect(ev.event!.cap, 30);
    expect(ev.event!.where, '3층 세미나실');
    expect(find.text('겨울방학 설명회'), findsOneWidget);

    await t.tap(find.byTooltip('글쓰기'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(OptionBox, '구인구직'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('postTitle')), '수학 보조 강사 모집');
    await t.enterText(find.byKey(const Key('meta')), '평촌동 · 평일 오후');
    await t.tap(find.text('올리기'));
    await t.pumpAndSettle();
    expect(store.jobs.first.title, '수학 보조 강사 모집');
    await t.tap(find.widgetWithText(PillChip, '구인구직'));
    await t.pumpAndSettle();
    expect(find.text('수학 보조 강사 모집'), findsOneWidget);
  });

  testWidgets('학부모 상담: 상담 카드 → 채팅방, 메시지를 보내면 학원이 답장한다', (t) async {
    await _app(t, UserRole.parent);
    await _tab(t, '상담');
    expect(find.text('바른수학 학원'), findsOneWidget, reason: '예시 상담방');
    expect(find.textContaining('호계동 초3맘'), findsNothing, reason: '다른 학부모 상담은 관계자에게만');

    await t.tap(find.text('상담 카드 보내기'));
    await t.pumpAndSettle();
    await t.tap(find.text('상담 카드 보내기').last);
    await t.pump();
    expect(find.text('받는 학원을 골라 주세요'), findsOneWidget);

    await t.tap(find.text('학원 고르기'));
    await t.pumpAndSettle();
    await t.tap(find.text('가온수학'));
    await t.pumpAndSettle();
    await t.tap(find.text('한 학기 선행'));
    await t.tap(find.text('서술형이 약해요'));
    await t.tap(find.text('상담 카드 보내기').last);
    await t.pumpAndSettle();
    expect(find.text('상담 카드'), findsWidgets);
    expect(find.text('첫째 · 초3 · 한 학기 선행'), findsOneWidget);

    await t.pump(_reply);
    await t.pumpAndSettle();
    expect(find.textContaining('상담 카드 잘 받았어요'), findsOneWidget, reason: '시연용 자동 답장');

    await t.enterText(find.byKey(const Key('chat')), '토요일 상담 가능할까요?');
    await t.tap(find.byTooltip('보내기'));
    await t.pump();
    expect(find.text('토요일 상담 가능할까요?'), findsOneWidget);
    await t.pump(_reply);
    await t.pumpAndSettle();
    expect(find.textContaining('담당 선생님이 곧'), findsOneWidget);

    await t.tap(find.byTooltip('AI 상담노트'));
    await t.pumpAndSettle();
    expect(find.text('가온수학 상담 요약'), findsOneWidget);
  });

  testWidgets('학부모 알림장 · 알림: 숙제 체크, 긴급 안내 확인', (t) async {
    final store = await _app(t, UserRole.parent);
    await _tab(t, '알림장');
    expect(find.text('이번 주 시간표 · 첫째 · 초3'), findsOneWidget);
    expect(find.text('1/3 완료'), findsOneWidget);
    await t.tap(find.text('서술형 3문제 — 풀이 과정 꼭 쓰기'));
    await t.pumpAndSettle();
    expect(find.text('2/3 완료'), findsOneWidget);

    await _tab(t, '홈');
    await t.tap(find.byTooltip('알림'));
    await t.pumpAndSettle();
    expect(find.textContaining('강풍 예보로 휴원합니다'), findsOneWidget);
    await t.tap(find.widgetWithText(OutlinedButton, '확인했어요'));
    await t.pumpAndSettle();
    expect(store.notices.first.acked, isTrue);
    expect(store.unread, 0, reason: '열어 본 알림은 읽음');
  });

  testWidgets('학원 관계자: 상담함에 받은 상담, 출결 입력, 긴급 안내 보내기', (t) async {
    final store = await _app(t, UserRole.staff);
    await _tab(t, '상담함');
    expect(find.textContaining('호계동 초3맘'), findsOneWidget);

    await _tab(t, '내 학원');
    await t.tap(find.text('오늘 출결'));
    await t.pumpAndSettle();
    await t.tap(find.text('등원').first);
    await t.pumpAndSettle();
    expect(find.textContaining('등원 '), findsWidgets);
    expect(store.pupils.first.inAt, isNotNull);
    await t.tap(find.byType(BackButton));
    await t.pumpAndSettle();

    await t.tap(find.text('알림장 보내기'));
    await t.pumpAndSettle();
    await t.tap(find.text('긴급 안내'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('noticeTitle')), '오늘 정전으로 휴원합니다');
    await t.tap(find.text('보내기'));
    await t.pumpAndSettle();
    expect(store.notices.first.title, '오늘 정전으로 휴원합니다');
    expect(store.notices.first.academy, '가온수학');
  });

  testWidgets('계정을 바꾸면 이전 학부모의 상담 · 글은 내 것으로 보이지 않는다', (t) async {
    final store = DemoStore(replyDelay: _reply);
    store.sendCard(
      academies: ['가온수학'],
      parent: '다른맘',
      ownerUid: 'other',
      card: const ConsultCard(kid: '첫째 · 초3', prog: '학교 진도만', worries: [], how: '채팅', memo: ''),
    );
    store.addPost(cat: '익명 커뮤니티', title: '다른 사람 글', body: '본문', author: '익명', ownerUid: 'other');
    await t.pump(_reply);
    await _app(t, UserRole.parent, store: store);
    await _tab(t, '상담');
    expect(find.text('가온수학'), findsNothing, reason: '다른 학부모가 보낸 상담');
    await _tab(t, '라운지');
    expect(find.text('다른 사람 글'), findsOneWidget);
    expect(find.text('내 글'), findsNothing);
  });

  testWidgets('관계자 상담함: 예시 상담과 내 학원으로 온 상담만', (t) async {
    final store = DemoStore(replyDelay: _reply);
    store.sendCard(
      academies: ['가온수학'],
      parent: 'A맘',
      ownerUid: 'a',
      card: const ConsultCard(kid: '첫째 · 초3', prog: '학교 진도만', worries: [], how: '채팅', memo: '우리 학원'),
    );
    store.sendCard(
      academies: ['다른학원'],
      parent: 'B맘',
      ownerUid: 'b',
      card: const ConsultCard(kid: '첫째 · 초5', prog: '학교 진도만', worries: [], how: '채팅', memo: '남의 학원'),
    );
    await t.pump(_reply);
    await _app(t, UserRole.staff, store: store);
    await _tab(t, '상담함');
    expect(find.textContaining('A맘'), findsOneWidget);
    expect(find.textContaining('B맘'), findsNothing);
    expect(find.textContaining('호계동 초3맘'), findsOneWidget, reason: '예시 상담');
  });

  // 작은 휴대폰(320dp) · 큰 글씨(1.3배)로 모든 화면을 열어 글자 넘침 · 레이아웃 오류가 없는지 본다.
  for (final (width, scale) in [(320.0, 1.3), (360.0, 1.6)]) {
    for (final role in UserRole.values) {
      testWidgets('전 화면 순회 (${width.toInt()}dp · 글자 $scale배): ${role.label}', (t) async {
        await _app(t, role, width: width, textScale: scale);
        final tabs = switch (role) {
          UserRole.parent => ['홈', '라운지', '상담', '알림장', 'MY'],
          UserRole.student => ['홈', '라운지', '알림장', 'MY'],
          UserRole.staff => ['내 학원', '상담함', '라운지', 'MY'],
        };
        for (final tab in tabs) {
          await _tab(t, tab);
        }
        final routes = [
          '/academy/H001',
          '/post/p1',
          '/post/p3',
          '/post/p4',
          '/write',
          '/saved',
          '/plans',
          if (role == UserRole.parent) ...['/results', '/consult/new', '/chat/t1', '/ai/t1', '/notifications'],
          if (role == UserRole.student) '/notifications',
          if (role == UserRole.staff) ...['/class', '/staff/attendance', '/staff/send', '/chat/t2'],
        ];
        for (final r in routes) {
          _router!.push(r);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: r);
          _router!.pop();
          await t.pumpAndSettle();
        }
        if (role != UserRole.staff) {
          // 학원 상세의 가격 · 리뷰 탭
          _router!.push('/academy/H001');
          await t.pumpAndSettle();
          await t.tap(find.text('가격'));
          await t.pumpAndSettle();
          await t.tap(find.textContaining('리뷰 '));
          await t.pumpAndSettle();
        }
      });
    }
  }

  testWidgets('로그인 전 화면 순회 (360dp · 글자 1.6배): 시작 · 로그인 · 가입 첫 단계', (t) async {
    t.view.physicalSize = const Size(360 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final db = FakeFirebaseFirestore();
    final auth = AuthService(MockFirebaseAuth());
    final users = UserRepository(db);
    final academies = AcademyRepository(db);
    final session = SessionViewModel(auth: auth, users: users);
    final router = buildRouter(session);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: auth),
          Provider.value(value: users),
          Provider.value(value: academies),
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider(create: (_) => AcademySearchViewModel(academies)),
          ChangeNotifierProvider(create: (_) => DemoStore()),
        ],
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('어떤 분이신가요?'), findsOneWidget);
    for (final r in ['/login', '/signup/parent', '/signup/staff', '/signup/student']) {
      router.go(r);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: r);
    }
  });
}
