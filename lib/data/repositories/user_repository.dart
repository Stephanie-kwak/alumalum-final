import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_profile.dart';

/// 회원 프로필 읽기 · 쓰기. 공개 정보는 users/{uid}, 휴대폰 · 이메일 · 동의 서명은 users/{uid}/private/info.
/// 자녀 연결 코드는 linkCodes/{코드} → 보호자 uid. 보안 규칙에서 목록 조회를 막아 코드를 아는 사람만 찾을 수 있다.
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<UserProfile?> watch(String uid) => _users.doc(uid).snapshots().map((s) => s.exists ? UserProfile.fromJson(uid, s.data()!) : null);

  Future<void> create(UserProfile profile, {required Map<String, dynamic> private, String? linkCode}) async {
    final batch = _db.batch()
      ..set(_users.doc(profile.uid), {...profile.toJson(), 'createdAt': FieldValue.serverTimestamp()})
      ..set(_users.doc(profile.uid).collection('private').doc('info'), {
        for (final e in private.entries) e.key: e.value is Uint8List ? Blob(e.value as Uint8List) : e.value,
        'linkCode': ?linkCode,
        'signedAt': FieldValue.serverTimestamp(),
      });
    if (linkCode != null) batch.set(_db.collection('linkCodes').doc(linkCode), {'parentUid': profile.uid, 'parentName': profile.name});
    await batch.commit();
  }

  /// 학생이 입력한 6자리 코드로 보호자를 찾는다. 없으면 null.
  /// 보호자 프로필(자녀 정보 포함)은 본인만 읽을 수 있어서, 코드 문서에 담아 둔 닉네임만 돌려준다.
  Future<({String uid, String name})?> findParentByLinkCode(String code) async {
    final d = (await _db.collection('linkCodes').doc(code).get()).data();
    if (d == null) return null;
    return (uid: d['parentUid'] as String, name: d['parentName'] as String? ?? '');
  }

  Future<String?> linkCodeOf(String uid) async => (await _users.doc(uid).collection('private').doc('info').get()).data()?['linkCode'] as String?;

  /// 학부모 가입 때 만드는 자녀 연결 코드. 이미 쓰는 코드면 다시 뽑는다(같은 코드로 저장하면 보안 규칙이 가입을 거부한다).
  Future<String> freeLinkCode() async {
    for (var i = 0; i < 5; i++) {
      final code = (Random.secure().nextInt(900000) + 100000).toString();
      if (!(await _db.collection('linkCodes').doc(code).get()).exists) return code;
    }
    throw StateError('연결 코드를 만들지 못했어요');
  }
}
