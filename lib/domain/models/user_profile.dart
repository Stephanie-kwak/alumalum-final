enum UserRole {
  parent('학부모'),
  staff('학원 관계자'),
  student('학생');

  const UserRole(this.label);
  final String label;
}

/// 학부모가 등록한 자녀. 학생 계정이 연결되면 [studentUid] 가 채워진다.
class Kid {
  const Kid({required this.order, required this.grade, required this.birthYear, required this.sex, this.studentUid});

  /// 첫째 · 둘째 …
  final String order;

  /// 초1 ~ 고3
  final String grade;
  final int birthYear;

  /// 여 · 남
  final String sex;
  final String? studentUid;

  /// 홈 칩 등에 쓰는 짧은 이름. 예: 첫째 · 초3
  String get label => '$order · $grade';

  factory Kid.fromJson(Map<String, dynamic> j) => Kid(
    // 콘솔에서 손으로 고친 데이터에 칸이 빠져도 앱이 멈추지 않게 기본값을 쓴다.
    order: j['order'] as String? ?? '',
    grade: j['grade'] as String? ?? '',
    birthYear: (j['birthYear'] as num?)?.toInt() ?? 0,
    sex: j['sex'] as String? ?? '',
    studentUid: j['studentUid'] as String?,
  );

  Map<String, dynamic> toJson() => {'order': order, 'grade': grade, 'birthYear': birthYear, 'sex': sex, if (studentUid != null) 'studentUid': studentUid};
}

/// 회원 공개 정보. Firestore `users/{uid}`. 휴대폰 번호 · 이메일 · 서명 · 자녀 연결 코드는 `users/{uid}/private/info` 에 따로 둔다.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.loginId,
    required this.name,
    this.area = '',
    this.kids = const [],
    this.interests = const [],
    this.academyId,
    this.position,
    this.grade,
    this.parentUid,
    this.academyIds = const [],
    this.plus = false,
    this.verified = false,
  });

  final String uid;
  final UserRole role;
  final String loginId;

  /// 학부모는 닉네임(라운지 표시), 관계자 · 학생은 실명
  final String name;

  /// 우리 동네 (동안구 권역)
  final String area;

  // 학부모
  final List<Kid> kids;
  final List<String> interests;

  // 학원 관계자
  final String? academyId;
  final String? position;

  // 학생
  final String? grade;
  final String? parentUid;
  final List<String> academyIds;

  /// 월정액 플러스 (테스트 결제)
  final bool plus;

  /// 학원 관계자 서류 확인 여부. 앱에서는 바꿀 수 없고 운영자가 Firebase 콘솔에서 켠다.
  final bool verified;

  factory UserProfile.fromJson(String uid, Map<String, dynamic> j) => UserProfile(
    uid: uid,
    role: UserRole.values.byName(j['role'] as String),
    loginId: j['loginId'] as String? ?? '',
    name: j['name'] as String? ?? '',
    area: j['area'] as String? ?? '',
    kids: ((j['kids'] as List?) ?? const []).map((e) => Kid.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    interests: ((j['interests'] as List?) ?? const []).cast<String>(),
    academyId: j['academyId'] as String?,
    position: j['position'] as String?,
    grade: j['grade'] as String?,
    parentUid: j['parentUid'] as String?,
    academyIds: ((j['academyIds'] as List?) ?? const []).cast<String>(),
    plus: j['plus'] as bool? ?? false,
    verified: j['verified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'loginId': loginId,
    'name': name,
    'area': area,
    if (role == UserRole.parent) ...{'kids': kids.map((k) => k.toJson()).toList(), 'interests': interests},
    if (role == UserRole.staff) ...{'academyId': academyId, 'position': position, 'verified': verified},
    if (role == UserRole.student) ...{'grade': grade, 'parentUid': parentUid, 'academyIds': academyIds},
    'plus': plus,
  };
}
