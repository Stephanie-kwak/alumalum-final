import 'package:flutter/foundation.dart';

import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/user_profile.dart';
import '../../session/session_view_model.dart';

/// 가입 2~4단계(기본 정보 → 유형별 프로필 → 약관 · 서명). 1단계(유형 선택)에서 [role] 을 받는다.
class SignupViewModel extends ChangeNotifier {
  SignupViewModel({required this.role, required this._auth, required this._users, required this._session});

  final UserRole role;
  final AuthService _auth;
  final UserRepository _users;
  final SessionViewModel _session;

  int step = 2;
  Map<String, String> errors = {};
  bool busy = false;

  // 2단계 기본 정보
  String loginId = '', password = '', password2 = '', phone = '', code = '', email = '';
  DateTime? codeSentAt;

  // 3단계 학부모
  String nick = '', area = '';
  final List<Kid> kids = [];
  final Set<String> interests = {};

  // 3단계 관계자
  String position = '원장', staffName = '';
  String? academyId;
  final Set<String> subjects = {};
  final Set<String> docs = {};

  // 3단계 학생
  String studentName = '', level = '초등', linkCode = '';
  int gradeNum = 0;
  ({String uid, String name})? linkedParent;

  // 4단계 약관 · 서명
  final Set<String> agreed = {};
  Uint8List? signature;
  static const required = ['terms', 'privacy', 'child'];
  static const all = ['terms', 'privacy', 'child', 'location', 'event'];

  void update(VoidCallback f) {
    f();
    notifyListeners();
  }

  void toggle<T>(Set<T> set, T v) => update(() => set.contains(v) ? set.remove(v) : set.add(v));

  void sendCode() {
    if (!RegExp(r'^01[0-9]-?\d{3,4}-?\d{4}$').hasMatch(phone.trim())) {
      update(() => errors = {'phone': '010-0000-0000 형식으로 적어 주세요'});
      return;
    }
    update(() {
      codeSentAt = DateTime.now();
      errors = {};
    });
  }

  static const maxKids = 5;

  void addKid(String grade, String sex) {
    if (kids.length >= maxKids) return;
    const orders = ['첫째', '둘째', '셋째', '넷째', '다섯째'];
    final n = int.tryParse(grade.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final age = grade.startsWith('초')
        ? 6 + n
        : grade.startsWith('중')
        ? 12 + n
        : 15 + n;
    update(() => kids.add(Kid(order: orders[kids.length.clamp(0, 4)], grade: grade, birthYear: DateTime.now().year - age, sex: sex)));
  }

  void removeKid(int i) => update(() {
    kids.removeAt(i);
    const orders = ['첫째', '둘째', '셋째', '넷째', '다섯째'];
    for (var k = 0; k < kids.length; k++) {
      final o = kids[k];
      kids[k] = Kid(order: orders[k], grade: o.grade, birthYear: o.birthYear, sex: o.sex);
    }
  });

  Future<void> linkParent() async {
    if (busy) return;
    if (!RegExp(r'^\d{6}$').hasMatch(linkCode)) {
      update(() => errors = {'link': '6자리 숫자를 적어 주세요'});
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _auth.ensureGuest();
      linkedParent = await _users.findParentByLinkCode(linkCode);
      errors = linkedParent == null ? {'link': '코드에 맞는 보호자가 없어요. 보호자 앱 MY에서 다시 확인해 주세요'} : {};
    } catch (_) {
      errors = {'link': '확인하지 못했어요. 인터넷 연결을 확인해 주세요'};
    }
    busy = false;
    notifyListeners();
  }

  bool get allAgreed => all.every(agreed.contains);
  void toggleAll() => update(() => allAgreed ? agreed.clear() : agreed.addAll(all));

  /// 현재 단계 입력을 확인한다. 문제가 있으면 [errors] 에 칸별 문장을 넣고 false.
  bool validate() {
    final e = <String, String>{};
    if (step == 2) {
      if (!AuthService.isValidLoginId(loginId)) e['loginId'] = '영문 · 숫자 4–20자, 한글은 2–10자로 적어 주세요';
      if (password.length < 8 || !RegExp(r'[a-zA-Z]').hasMatch(password) || !RegExp(r'\d').hasMatch(password)) {
        e['password'] = '영문과 숫자를 섞어 8자 이상으로 적어 주세요';
      } else if (password != password2) {
        e['password2'] = '비밀번호가 서로 달라요';
      }
      if (!RegExp(r'^01[0-9]-?\d{3,4}-?\d{4}$').hasMatch(phone.trim())) {
        e['phone'] = '010-0000-0000 형식으로 적어 주세요';
      } else if (codeSentAt == null) {
        e['phone'] = '휴대폰 번호를 적고 인증 요청을 눌러 주세요';
      } else if (!RegExp(r'^\d{6}$').hasMatch(code)) {
        e['code'] = '인증번호 6자리를 적어 주세요';
      }
      if (email.isNotEmpty && (!email.contains('@') || email.length > 100)) e['email'] = '이메일 형식을 확인해 주세요';
    } else if (step == 3) {
      switch (role) {
        case UserRole.parent:
          if (nick.trim().isEmpty) e['nick'] = '닉네임을 적어 주세요';
          if (area.isEmpty) e['area'] = '우리 동네를 골라 주세요';
          if (kids.isEmpty) e['kids'] = '자녀를 한 명 이상 추가해 주세요';
          if (kids.length > maxKids) e['kids'] = '자녀는 $maxKids명까지 등록할 수 있어요';
        case UserRole.staff:
          if (staffName.trim().isEmpty) e['staffName'] = '이름을 적어 주세요';
          if (academyId == null) e['academy'] = '우리 학원을 골라 주세요';
        case UserRole.student:
          if (studentName.trim().isEmpty) e['studentName'] = '이름을 적어 주세요';
          if (level != '성인' && gradeNum == 0) e['grade'] = '학년을 골라 주세요';
      }
    } else {
      if (!required.every(agreed.contains)) e['agree'] = '필수 항목 세 개에 동의해 주세요';
      if (signature == null) e['signature'] = '서명 칸에 서명해 주세요';
    }
    errors = e;
    notifyListeners();
    return e.isEmpty;
  }

  /// 다음 단계로. 마지막 단계면 가입을 마치고 true.
  Future<bool> next() async {
    if (!validate()) return false;
    if (step < 4) {
      update(() => step++);
      return false;
    }
    return _submit();
  }

  void back() => update(() => step--);

  Future<bool> _submit() async {
    if (busy) return false;
    busy = true;
    notifyListeners();
    _session.signingUp = true;
    String? uid;
    try {
      // 모든 역할이 임시 계정에서 출발하게 해서 제출 중에 uid 가 바뀌지 않게 한다.
      await _auth.ensureGuest();
      uid = await _auth.signUp(loginId, password);
      final linkCode = role == UserRole.parent ? await _users.freeLinkCode() : null;
      final profile = UserProfile(
        uid: uid,
        role: role,
        loginId: AuthService.keyOf(loginId),
        name: switch (role) {
          UserRole.parent => nick.trim(),
          UserRole.staff => staffName.trim(),
          UserRole.student => studentName.trim(),
        },
        area: area,
        kids: kids,
        interests: interests.toList(),
        academyId: academyId,
        position: position,
        grade: level == '성인' ? '성인' : '${level[0]}$gradeNum',
        parentUid: linkedParent?.uid,
      );
      await _users.create(
        profile,
        private: {
          'phone': phone.trim(),
          'email': email.trim(),
          'agreed': agreed.toList(),
          'signaturePng': signature,
          if (linkedParent != null) 'linkCode': this.linkCode,
        },
        linkCode: linkCode,
      );
      return true;
    } catch (e) {
      if (uid != null) await _auth.deleteCurrentUser();
      errors = {'submit': AuthService.messageOf(e)};
      if (errors['submit']!.contains('아이디')) step = 2;
      return false;
    } finally {
      busy = false;
      _session.signingUp = false;
      notifyListeners();
    }
  }
}
