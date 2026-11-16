import 'package:alumalum/data/repositories/user_repository.dart';
import 'package:alumalum/data/services/auth_service.dart';
import 'package:alumalum/ui/features/session/session_view_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('가입 중 임시(익명) 로그인은 로딩을 거치지 않고 로그인 전 상태로 남는다 (실기기에서 관계자 가입이 첫 화면으로 튕기던 문제)', () async {
    final mock = MockFirebaseAuth();
    final session = SessionViewModel(auth: AuthService(mock), users: UserRepository(FakeFirebaseFirestore()));
    final seen = <SessionStatus>[];
    session.addListener(() => seen.add(session.status));
    await Future<void>.delayed(Duration.zero);
    await mock.signInAnonymously();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen, isNot(contains(SessionStatus.loading)));
    expect(session.status, SessionStatus.signedOut);
  });
}
