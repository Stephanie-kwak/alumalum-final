import 'dart:typed_data';

import 'package:alumalum/data/repositories/user_repository.dart';
import 'package:alumalum/data/services/auth_service.dart';
import 'package:alumalum/domain/models/user_profile.dart';
import 'package:alumalum/ui/features/onboarding/view_models/signup_view_model.dart';
import 'package:alumalum/ui/features/session/session_view_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// firebase_auth_mocks 는 임시(익명) 계정을 아이디 계정으로 바꾸는 linkWithCredential 을 흉내 내지 못한다.
/// 단위 테스트는 임시 로그인을 건너뛰고, 전환 경로는 실제 Firebase 에서 확인한다.
class _NoGuestAuth extends AuthService {
  _NoGuestAuth(super.auth);

  @override
  Future<void> ensureGuest() async {}
}

void main() {
  late FakeFirebaseFirestore db;
  late MockFirebaseAuth auth;

  SignupViewModel newVm(UserRole role) {
    final a = _NoGuestAuth(auth);
    final users = UserRepository(db);
    return SignupViewModel(
      role: role,
      auth: a,
      users: users,
      session: SessionViewModel(auth: a, users: users),
    );
  }

  void fillBasic(SignupViewModel vm, String id) {
    vm
      ..loginId = id
      ..password = 'abcd1234'
      ..password2 = 'abcd1234'
      ..phone = '010-1234-5678'
      ..sendCode()
      ..code = '123456';
  }

  void sign(SignupViewModel vm) => vm
    ..agreed.addAll(SignupViewModel.all)
    ..signature = Uint8List.fromList([1, 2, 3]);

  setUp(() {
    db = FakeFirebaseFirestore();
    auth = MockFirebaseAuth();
  });

  test('기본 정보: 빈칸 · 비밀번호 불일치 · 인증 요청 전', () async {
    final vm = newVm(UserRole.parent);
    expect(await vm.next(), isFalse);
    expect(vm.errors.keys, containsAll(['loginId', 'password', 'phone']));
    vm
      ..loginId = 'mom01'
      ..password = 'abcd1234'
      ..password2 = 'abcd9999';
    vm.validate();
    expect(vm.errors['password2'], '비밀번호가 서로 달라요');
    vm.phone = '1234';
    vm.sendCode();
    expect(vm.errors['phone'], contains('010'));
  });

  test('자녀 추가: 출생연도 계산과 순서 다시 매기기', () {
    final vm = newVm(UserRole.parent)
      ..addKid('초3', '여')
      ..addKid('중3', '남');
    final y = DateTime.now().year;
    expect(vm.kids.map((k) => (k.order, k.birthYear)), [('첫째', y - 9), ('둘째', y - 15)]);
    vm.removeKid(0);
    expect(vm.kids.single.order, '첫째');
    expect(vm.kids.single.grade, '중3');
  });

  test('학부모 가입 끝까지: 공개 프로필 · 개인 정보 · 자녀 연결 코드가 나뉘어 저장된다', () async {
    final vm = newVm(UserRole.parent);
    fillBasic(vm, 'Mom01');
    await vm.next();
    expect(vm.step, 3);
    await vm.next();
    expect(vm.errors.keys, containsAll(['nick', 'area', 'kids']));
    vm
      ..nick = '평촌 초3맘'
      ..area = '호계'
      ..addKid('초3', '여')
      ..interests.add('수학');
    await vm.next();
    expect(vm.step, 4);
    await vm.next();
    expect(vm.errors.keys, containsAll(['agree', 'signature']));
    sign(vm);
    expect(await vm.next(), isTrue);

    final uid = auth.currentUser!.uid;
    final pub = (await db.doc('users/$uid').get()).data()!;
    expect(pub['loginId'], 'mom01');
    expect(pub['name'], '평촌 초3맘');
    expect(pub['kids'], hasLength(1));
    expect(pub.containsKey('phone'), isFalse);
    final priv = (await db.doc('users/$uid/private/info').get()).data()!;
    expect(priv['phone'], '010-1234-5678');
    final code = priv['linkCode'] as String;
    expect(code, matches(RegExp(r'^\d{6}$')));
    expect((await db.doc('linkCodes/$code').get()).data(), {'parentUid': uid, 'parentName': '평촌 초3맘'});
  });

  test('학생: 보호자 코드로 연결, 틀린 코드는 오류', () async {
    await db.doc('linkCodes/482915').set({'parentUid': 'p1', 'parentName': '평촌 초3맘'});
    final vm = newVm(UserRole.student)..linkCode = '111111';
    await vm.linkParent();
    expect(vm.linkedParent, isNull);
    expect(vm.errors['link'], isNotNull);
    vm.linkCode = '482915';
    await vm.linkParent();
    expect(vm.linkedParent?.uid, 'p1');
    expect(vm.linkedParent?.name, '평촌 초3맘');

    fillBasic(vm, 'kid01');
    await vm.next();
    vm
      ..studentName = '김지우'
      ..level = '초등'
      ..gradeNum = 3;
    await vm.next();
    sign(vm);
    expect(await vm.next(), isTrue);
    final pub = (await db.doc('users/${auth.currentUser!.uid}').get()).data()!;
    expect(pub['grade'], '초3');
    expect(pub['parentUid'], 'p1');
  });

  test('관계자: 학원을 고르지 않으면 넘어가지 않는다', () async {
    final vm = newVm(UserRole.staff);
    fillBasic(vm, 'teacher01');
    await vm.next();
    vm.staffName = '김도현';
    await vm.next();
    expect(vm.step, 3);
    expect(vm.errors['academy'], isNotNull);
    vm.academyId = 'A001';
    await vm.next();
    expect(vm.step, 4);
  });
}
