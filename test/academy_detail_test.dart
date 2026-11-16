import 'package:alumalum/data/repositories/academy_repository.dart';
import 'package:alumalum/data/repositories/user_repository.dart';
import 'package:alumalum/data/services/auth_service.dart';
import 'package:alumalum/domain/models/academy.dart';
import 'package:alumalum/ui/core/theme.dart';
import 'package:alumalum/ui/features/academy/academy_detail_screen.dart';
import 'package:alumalum/ui/features/demo/demo_store.dart';
import 'package:alumalum/ui/features/manage/class_edit_screen.dart';
import 'package:alumalum/ui/features/session/session_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _doc = {
  'name': '가온수학',
  'size': '소형',
  'subjects': ['수학'],
  'levels': ['초3-4', '초5-6'],
  'adult': false,
  'addr': '',
  'dong': '평촌동',
  'area': '평촌 학원가',
  'phone': '',
  'web': '',
  'shuttle': null,
  'tags': <String>[],
  'fee': {'min': 160000, 'max': 240000, 'avg': 200000, 'date': '2024-03-02', 'extra': ''},
  'courses': [
    {'name': '초등주3회', 'level': '초등', 'subject': '수학', 'cap': 8, 'minutes': 1080, 'monthly': 240000},
  ],
};

Future<void> _phone(WidgetTester t) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// 학원 상세만 띄운다(로그인 전 상태 · 시연 저장소 포함)
Widget _detailApp(FakeFirebaseFirestore db, String id) {
  final auth = AuthService(MockFirebaseAuth());
  return MultiProvider(
    providers: [
      Provider.value(value: AcademyRepository(db)),
      ChangeNotifierProvider(create: (_) => SessionViewModel(auth: auth, users: UserRepository(db))),
      ChangeNotifierProvider(create: (_) => DemoStore()),
    ],
    child: MaterialApp(theme: buildAppTheme(), home: AcademyDetailScreen(id: id)),
  );
}

void main() {
  test('금액 표기', () {
    expect(won(240000), '24만원');
    expect(won(245000), '24만 5천원');
    expect(won(9900), '9,900원');
    expect(won(245500), '245,500원', reason: '반올림하지 않는다');
    expect(won(176700), '176,700원');
    expect(won(0), '0원');
  });

  test('교육청 교습비 · 교습과정을 읽고, 없으면 null · 빈 목록', () {
    final a = Academy.fromJson('H001', _doc);
    expect(a.fee!.min, 160000);
    expect(a.courses.single.monthly, 240000);
    final empty = Academy.fromJson('H002', {'name': '빈 학원'});
    expect(empty.fee, isNull);
    expect(empty.courses, isEmpty);
    expect(empty.ageText, '나이 미정');
    expect(empty.sizeText, '규모 미정');
  });

  testWidgets('학원 상세: 정보 탭은 모르는 값을 미정으로, 가격 탭은 학원 등록 수강료와 교육청 교습비를 보인다', (t) async {
    await _phone(t);
    final db = FakeFirebaseFirestore();
    await db.collection('academies').doc('H001').set(_doc);
    await db.collection('academies/H001/classes').add({
      'grade': '초3', 'name': '사고력반', 'subject': '수학', 'perWeek': 2, 'minutes': 90, 'fee': 240000, 'cap': 8, 'updatedAt': Timestamp.now(),
    });
    await t.pumpWidget(_detailApp(db, 'H001'));
    await t.pumpAndSettle();
    expect(find.text('가온수학'), findsWidgets);
    expect(find.text('미정'), findsWidgets, reason: '주소 · 전화 · 셔틀');
    expect(find.text('전화 문의'), findsNothing, reason: '전화번호가 없으면 버튼을 숨긴다');

    await t.tap(find.text('가격'));
    await t.pumpAndSettle();
    expect(find.text('초3 사고력반'), findsOneWidget);
    expect(find.text('주 2회 · 90분'), findsOneWidget);
    expect(find.text('월 16만원 ~ 24만원'), findsOneWidget);
    expect(find.text('초등주3회'), findsOneWidget);
  });

  testWidgets('학원 상세: 없는 학원 ID 는 안내를 보인다', (t) async {
    await t.pumpWidget(_detailApp(FakeFirebaseFirestore(), 'A001'));
    await t.pumpAndSettle();
    expect(find.text('학원을 찾지 못했어요'), findsOneWidget);
  });

  /// 소속 학원이 H001 인 관계자로 로그인한 상태에서 '/class' 를 연다. [initial] 을 주면 수정 화면.
  Future<FakeFirebaseFirestore> openEditor(WidgetTester t, {AcademyClass? initial}) async {
    await _phone(t);
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('s1').set({'role': 'staff', 'loginId': 'teacher01', 'name': '김도현', 'area': '', 'plus': false, 'academyId': 'H001', 'position': '원장', 'verified': false});
    final auth = AuthService(MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 's1', email: 'teacher01@alumalum.app')));
    final session = SessionViewModel(auth: auth, users: UserRepository(db));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(body: TextButton(onPressed: () => context.push('/class', extra: initial), child: const Text('열기'))),
        ),
        GoRoute(path: '/class', builder: (_, s) => ClassEditScreen(initial: s.extra as AcademyClass?)),
      ],
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [Provider.value(value: AcademyRepository(db)), ChangeNotifierProvider.value(value: session)],
        child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      ),
    );
    await t.pumpAndSettle();
    expect(session.profile?.academyId, 'H001');
    await t.tap(find.text('열기'));
    await t.pumpAndSettle();
    return db;
  }

  testWidgets('반 추가: 빈 칸은 오류, 다 채우면 소속 학원에 저장하고 닫힌다', (t) async {
    final db = await openEditor(t);
    await t.tap(find.text('저장'));
    await t.pump();
    expect(find.text('대상 학년을 골라 주세요'), findsOneWidget);
    expect(find.text('반 이름을 적어 주세요'), findsOneWidget);

    await t.tap(find.text('초3'));
    await t.enterText(find.byKey(const Key('className')), '사고력반');
    await t.tap(find.text('수학'));
    await t.tap(find.text('주 2회'));
    await t.scrollUntilVisible(find.byKey(const Key('fee')), 200, scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byKey(const Key('minutes')), '90');
    await t.enterText(find.byKey(const Key('cap')), '8');
    await t.enterText(find.byKey(const Key('fee')), '-5000');
    await t.tap(find.text('저장'));
    await t.pump();
    expect(find.text('월 수강료를 숫자로 적어 주세요 (1천만 원 이하)'), findsOneWidget, reason: '음수는 거부');

    await t.enterText(find.byKey(const Key('fee')), '240,000');
    await t.pump();
    expect(find.textContaining('24만원'), findsOneWidget, reason: '입력한 금액을 읽기 쉽게 보여 준다');
    // 연타해도 반은 하나만 생긴다
    await t.tap(find.text('저장'));
    await t.tap(find.text('저장'), warnIfMissed: false);
    await t.pumpAndSettle();

    expect(find.text('열기'), findsOneWidget, reason: '저장하면 닫힌다');
    final saved = (await db.collection('academies/H001/classes').get()).docs.single.data();
    expect(saved, containsPair('fee', 240000));
    expect(saved, containsPair('perWeek', 2));
    expect(saved, containsPair('grade', '초3'));
  });

  testWidgets('반 수정 · 삭제: 같은 문서를 고치고, 확인을 받아 지운다', (t) async {
    const c = AcademyClass(id: 'c1', grade: '중3', name: '내신반', subject: '영어', perWeek: 3, minutes: 120, fee: 380000, cap: 12);
    final db = await openEditor(t, initial: c);
    await db.doc('academies/H001/classes/c1').set({...c.toJson(), 'updatedAt': Timestamp.now()});
    expect(find.text('반 수정'), findsOneWidget);
    await t.enterText(find.byKey(const Key('className')), '내신심화반');
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect((await db.doc('academies/H001/classes/c1').get()).data(), containsPair('name', '내신심화반'));

    await t.tap(find.text('열기'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('반 지우기'));
    await t.pumpAndSettle();
    await t.tap(find.text('지우기'));
    await t.pumpAndSettle();
    expect((await db.doc('academies/H001/classes/c1').get()).exists, isFalse);
  });
}
