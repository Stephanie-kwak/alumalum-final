import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

/// 아이디 · 비밀번호 로그인. Firebase 는 이메일 로그인만 받으므로 아이디를 가상 이메일로 바꿔 쓴다.
/// 예: parent01 → parent01@alumalum.app (메일은 보내지 않는다)
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  static String emailOf(String loginId) => '${keyOf(loginId)}@alumalum.app';

  /// 이메일에 쓰는 아이디. 영문 · 숫자는 그대로(소문자), 한글이 섞이면 'k.' + UTF-8 16진수.
  /// 예: parent01 → parent01, 평촌맘 → k.ed8f89ecb48ceba798. 회원 정보의 loginId 에도 이 값을 저장한다(보안 규칙이 이메일과 비교).
  static String keyOf(String loginId) {
    final id = composeHangul(loginId.trim()).toLowerCase();
    if (RegExp(r'^[a-z0-9]+$').hasMatch(id)) return id;
    return 'k.${utf8.encode(id).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// 가입할 수 있는 아이디: 영문 · 숫자 4–20자, 또는 한글이 들어간 2–10자(이메일 앞부분 64자 제한)
  static bool isValidLoginId(String loginId) {
    final id = composeHangul(loginId.trim());
    if (RegExp(r'^[a-zA-Z0-9]{4,20}$').hasMatch(id)) return true;
    return RegExp(r'^[가-힣a-zA-Z0-9]{2,10}$').hasMatch(id) && RegExp(r'[가-힣]').hasMatch(id);
  }

  /// 아이디 계정의 uid. 가입 중 임시(익명) 계정은 '로그인 전'(null)으로 본다.
  /// 임시 계정을 아이디 계정으로 바꿀 때는 로그인 상태가 그대로라 authStateChanges 가 울리지 않으므로 userChanges 를 본다.
  Stream<String?> get uidChanges => _auth.userChanges().map((u) => u == null || u.isAnonymous ? null : u.uid).distinct();
  String? get currentUid => _auth.currentUser?.uid;

  /// 자모로 나뉜 한글(맥에서 복사한 글자 등, NFD)을 완성형 글자로 합친다. 유니코드 한글 조합 공식.
  static String composeHangul(String s) {
    final cs = s.runes.toList();
    final out = StringBuffer();
    for (var i = 0; i < cs.length; i++) {
      final l = cs[i] - 0x1100, v = i + 1 < cs.length ? cs[i + 1] - 0x1161 : -1;
      if (l >= 0 && l < 19 && v >= 0 && v < 21) {
        final t = i + 2 < cs.length ? cs[i + 2] - 0x11A7 : 0;
        final hasT = t > 0 && t < 28;
        out.writeCharCode(0xAC00 + (l * 21 + v) * 28 + (hasT ? t : 0));
        i += hasT ? 2 : 1;
      } else {
        out.writeCharCode(cs[i]);
      }
    }
    return out.toString();
  }

  /// 가입 화면에 들어오면 임시(익명) 로그인을 한다. 학원 목록 · 자녀 연결 코드는 로그인한 사람만 읽을 수 있어서다.
  Future<void> ensureGuest() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  /// 임시 계정이 있으면 그 계정을 아이디 · 비밀번호 계정으로 바꾸고, 없으면 새로 만든다.
  Future<String> signUp(String loginId, String password) async {
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      final cred = await user.linkWithCredential(EmailAuthProvider.credential(email: emailOf(loginId), password: password));
      // 전환하면 Firebase 가 새 토큰(로그인 방식 · 이메일 포함)을 발급해 Firestore 에 넘긴다.
      // 여기서 getIdToken(true) 로 강제 갱신하면 안드로이드에서 no-current-user 로 실패하고 로그아웃된다(실기기 확인).
      return cred.user!.uid;
    }
    final cred = await _auth.createUserWithEmailAndPassword(email: emailOf(loginId), password: password);
    return cred.user!.uid;
  }

  /// 가입하다 그만두고 로그인하면 임시 계정이 남으므로 먼저 지운다.
  Future<String> signIn(String loginId, String password) async {
    final guest = _auth.currentUser;
    if (guest != null && guest.isAnonymous) {
      try {
        await guest.delete();
      } catch (_) {
        await _auth.signOut();
      }
    }
    final cred = await _auth.signInWithEmailAndPassword(email: emailOf(loginId), password: password);
    return cred.user!.uid;
  }

  Future<void> signOut() => _auth.signOut();

  /// 가입 중 프로필 저장이 실패했을 때 만들어 둔 계정을 지운다.
  /// 지우지 못하면(네트워크 등) 로그아웃이라도 해서 반쪽 계정으로 남아 있지 않게 한다.
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      await _auth.signOut();
    }
  }

  /// Firebase 오류를 화면에 보여 줄 한국어 문장으로 바꾼다.
  static String messageOf(Object e) {
    if (e is FirebaseException && e is! FirebaseAuthException) {
      return e.code == 'permission-denied' ? '입력한 내용 중 저장할 수 없는 값이 있어요. 길이와 형식을 확인해 주세요' : '저장하지 못했어요. 인터넷 연결을 확인해 주세요 (${e.code})';
    }
    if (e is! FirebaseAuthException) return '잠시 후 다시 시도해 주세요';
    return switch (e.code) {
      'email-already-in-use' || 'credential-already-in-use' => '이미 쓰는 아이디예요',
      'weak-password' => '비밀번호를 6자 이상으로 적어 주세요',
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' => '아이디 또는 비밀번호가 맞지 않아요',
      'too-many-requests' => '시도가 너무 많아요. 잠시 후 다시 해 주세요',
      'network-request-failed' => '인터넷 연결을 확인해 주세요',
      _ => '잠시 후 다시 시도해 주세요 (${e.code})',
    };
  }
}
