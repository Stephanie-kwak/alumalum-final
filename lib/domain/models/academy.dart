/// 학원 한 곳. Firestore `academies/{학원ID}` 문서와 1:1.
/// 학원 엑셀(tools/import_academies)로 등록하고, 앱에서는 읽기만 한다.
class Academy {
  const Academy({
    required this.id,
    required this.name,
    required this.size,
    required this.subjects,
    required this.levels,
    required this.adult,
    required this.addr,
    required this.dong,
    required this.area,
    required this.phone,
    required this.web,
    required this.shuttle,
    required this.tags,
    required this.fee,
    required this.courses,
    required this.ratingAvg,
    required this.reviewCount,
  });

  final String id;
  final String name;

  /// 공부방·교습소 · 소형 · 중형 · 대형. 비어 있으면 미정.
  final String size;
  final List<String> subjects;

  /// 대상 나이 중 학생 구간(초1-2 · 초3-4 · 초5-6 · 중등 · 고등). 비어 있으면 미정.
  final List<String> levels;

  /// 성인(검정고시·입시) 대상. 학생 구간과 따로 둬서, 학생 구간이 미정인 학원이 학생 필터에서 빠지지 않게 한다.
  final bool adult;

  /// 비어 있으면 미정
  final String addr;
  final String dong;

  /// 저장 값은 권역(평촌 학원가 · 호계 · 관양·인덕원 · 비산). 화면에는 areaName() 으로 동 이름을 보인다.
  final String area;
  final String phone;
  final String web;

  /// true 운행 · null 미정
  final bool? shuttle;
  final List<String> tags;

  /// 교육청 등록 교습비(월 환산). 등록 정보가 없으면 null.
  final AcademyFee? fee;

  /// 교육청 등록 교습과정
  final List<Course> courses;

  /// 앱 안에서 쓴 리뷰 집계 (외부 사이트 후기는 쓰지 않는다)
  final double ratingAvg;
  final int reviewCount;

  factory Academy.fromJson(String id, Map<String, dynamic> j) {
    final stat = (j['stat'] as Map<String, dynamic>?) ?? const {};
    final fee = j['fee'] as Map<String, dynamic>?;
    List<String> list(String k) => ((j[k] as List?) ?? const []).cast<String>();
    return Academy(
      id: id,
      name: j['name'] as String? ?? '',
      size: j['size'] as String? ?? '',
      subjects: list('subjects'),
      // 이전 형식('초등')으로 저장된 문서도 읽는다
      levels: [for (final l in list('levels')) ...(l == '초등' ? const ['초1-2', '초3-4', '초5-6'] : [l])],
      adult: j['adult'] as bool? ?? false,
      addr: j['addr'] as String? ?? '',
      dong: j['dong'] as String? ?? '',
      area: j['area'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      web: j['web'] as String? ?? '',
      shuttle: j['shuttle'] as bool?,
      tags: list('tags'),
      fee: fee == null
          ? null
          : AcademyFee(
              min: (fee['min'] as num?)?.toInt(),
              max: (fee['max'] as num?)?.toInt(),
              date: fee['date'] as String? ?? '',
              extra: fee['extra'] as String? ?? '',
            ),
      courses: [for (final c in (j['courses'] as List?) ?? const []) Course.fromJson(c as Map<String, dynamic>)],
      ratingAvg: (stat['avg'] as num?)?.toDouble() ?? 0,
      reviewCount: (stat['n'] as num?)?.toInt() ?? 0,
    );
  }

  /// 카드에 쓰는 대상 나이. 초등 구간은 이어지면 하나로 줄인다. 예: 초등·중등·성인, 초3-6·중등
  String get ageText {
    const elem = ['초1-2', '초3-4', '초5-6'];
    final idx = [for (var i = 0; i < 3; i++) if (levels.contains(elem[i])) i];
    final contiguous = idx.isNotEmpty && idx.last - idx.first == idx.length - 1;
    final parts = [
      if (idx.length == 3)
        '초등'
      else if (contiguous)
        '초${idx.first * 2 + 1}-${idx.last * 2 + 2}'
      else
        ...levels.where(elem.contains),
      ...levels.where((l) => !elem.contains(l)),
      if (adult) '성인',
    ];
    return parts.isEmpty ? '나이 미정' : parts.join('·');
  }

  String get sizeText => size.isEmpty ? '규모 미정' : size;

  /// 대표 과목(타일 기호 · 색). 과목이 없으면 빈 값.
  String get mainSubject => subjects.firstOrNull ?? '';
}

class AcademyFee {
  const AcademyFee({required this.min, required this.max, required this.date, required this.extra});

  final int? min, max;

  /// 교육청 교습비 최근 적용일 (YYYY-MM-DD)
  final String date;

  /// 차량비 · 모의고사비 같은 기타경비 안내
  final String extra;
}

/// 교육청에 등록된 교습과정 한 줄
class Course {
  const Course({required this.name, required this.level, required this.subject, required this.cap, required this.minutes, required this.monthly});

  final String name, level, subject;
  final int? cap, minutes, monthly;

  factory Course.fromJson(Map<String, dynamic> j) => Course(
    name: j['name'] as String? ?? '',
    level: j['level'] as String? ?? '',
    subject: j['subject'] as String? ?? '',
    cap: (j['cap'] as num?)?.toInt(),
    minutes: (j['minutes'] as num?)?.toInt(),
    monthly: (j['monthly'] as num?)?.toInt(),
  );
}

/// 반의 대상 학년. 반 추가 화면의 선택지이자 목록 정렬 순서.
const kClassGrades = ['초1', '초2', '초3', '초4', '초5', '초6', '중1', '중2', '중3', '고1', '고2', '고3', '성인'];

/// 학원장이 앱에서 직접 등록하는 반별 수강료. Firestore `academies/{학원ID}/classes/{자동 ID}`.
class AcademyClass {
  const AcademyClass({
    required this.id,
    required this.grade,
    required this.name,
    required this.subject,
    required this.perWeek,
    required this.minutes,
    required this.fee,
    required this.cap,
    this.updatedAt,
  });

  final String id;

  /// 대상 학년. 예: 초3 · 중1 · 성인
  final String grade;
  final String name;
  final String subject;

  /// 주당 수업 횟수
  final int perWeek;

  /// 1회 수업 시간(분)
  final int minutes;

  /// 월 수강료(원)
  final int fee;

  /// 정원(명)
  final int cap;
  final DateTime? updatedAt;

  factory AcademyClass.fromJson(String id, Map<String, dynamic> j) => AcademyClass(
    id: id,
    grade: j['grade'] as String? ?? '',
    name: j['name'] as String? ?? '',
    subject: j['subject'] as String? ?? '',
    perWeek: (j['perWeek'] as num?)?.toInt() ?? 0,
    minutes: (j['minutes'] as num?)?.toInt() ?? 0,
    fee: (j['fee'] as num?)?.toInt() ?? 0,
    cap: (j['cap'] as num?)?.toInt() ?? 0,
    updatedAt: j['updatedAt'] as DateTime?,
  );

  Map<String, dynamic> toJson() => {'grade': grade, 'name': name, 'subject': subject, 'perWeek': perWeek, 'minutes': minutes, 'fee': fee, 'cap': cap};
}

/// 금액을 '24만원' · '24만 5천원' 처럼 읽기 쉽게. 천 원 단위로 떨어지지 않으면 반올림하지 않고 '245,500원'.
String won(int v) {
  final man = v ~/ 10000, rest = v % 10000;
  if (v >= 10000 && rest == 0) return '$man만원';
  if (v >= 10000 && rest % 1000 == 0) return '$man만 ${rest ~/ 1000}천원';
  return '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',')}원';
}
