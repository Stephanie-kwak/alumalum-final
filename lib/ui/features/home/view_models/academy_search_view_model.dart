import 'package:flutter/foundation.dart';

import '../../../../data/repositories/academy_repository.dart';
import '../../../../domain/models/academy.dart';

/// 동안구 권역. 학원 리스트(CSV)의 '권역' 열과 같은 이름이어야 한다.
/// 저장 값은 권역 그대로 두고(회원 정보 · 보안 규칙이 이 값을 쓴다) 화면에는 동 이름으로 보인다(의뢰인 요청 261014).
const kAreas = ['평촌 학원가', '호계', '관양·인덕원', '비산'];
const _areaNames = {'평촌 학원가': '평촌동', '호계': '호계동', '관양·인덕원': '관양동', '비산': '비산동'};
String areaName(String area) => _areaNames[area] ?? area;
/// 대상 나이 필터(의뢰인 확정 261014). 학원 리스트의 '대상 학교급' 칸에서 만든다(tools/import_academies).
const kAges = ['초1-2', '초3-4', '초5-6', '중등', '고등', '성인'];

/// 학생 가입 때 고르는 학교급(성인은 학년 없음)
const kLevels = ['초등', '중등', '고등', '성인'];
const kSubjects = ['국어', '영어', '수학', '과학', '미술', '논술', '코딩', '외국어', '입시'];
/// 학원 엑셀 '분류기준' 시트의 규모 기준
const kSizes = [('공부방·교습소', '1인 운영 · 소규모'), ('소형', '한 호실'), ('중형', '한 층 · 2~4호실'), ('대형', '여러 층 · 대형 브랜드')];
const kSorts = ['추천순', '리뷰 많은 순', '이름순'];

/// 자녀 · 학생 학년(초3 · 중1 …)을 대상 나이 구간(초3-4 · 중등 …)으로 바꾼다.
String? ageOfGrade(String grade) => switch (grade.isEmpty ? '' : grade[0]) {
  '초' => switch (int.tryParse(grade.substring(1)) ?? 0) {
    1 || 2 => '초1-2',
    3 || 4 => '초3-4',
    5 || 6 => '초5-6',
    _ => null,
  },
  '중' => '중등',
  '고' => '고등',
  '성' => '성인',
  _ => null,
};

/// 대상 나이가 맞는지. 학생 구간은 학교급 미확인 학원도 맞는 것으로 본다(뒤로 보낸다).
bool _ageMatches(Academy a, String age) => age == '성인' ? a.adult : a.levels.isEmpty || a.levels.contains(age);

/// 홈 · 검색 결과가 함께 쓰는 학원 목록과 필터.
class AcademySearchViewModel extends ChangeNotifier {
  AcademySearchViewModel(this._repo);

  final AcademyRepository _repo;

  List<Academy> _all = const [];
  bool loading = true;
  String? error;

  final Set<String> areas = {};
  String? age, subject, size;
  bool shuttleOnly = false;
  String query = '';
  String sort = kSorts.first;

  Future<void> load({bool refresh = false}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _repo.all(refresh: refresh);
    } catch (_) {
      error = '학원 목록을 불러오지 못했어요';
    }
    loading = false;
    notifyListeners();
  }

  String? _ownerUid;

  /// 계정이 바뀌면 이전 계정의 필터 · 검색어를 지우고, 내 동네를 기본 지역으로 건다.
  void startFor(String uid, String homeArea) {
    if (_ownerUid == uid) return;
    _ownerUid = uid;
    areas.clear();
    age = subject = size = null;
    shuttleOnly = false;
    query = '';
    sort = kSorts.first;
    if (homeArea.isNotEmpty) areas.add(homeArea);
  }

  int get filterCount => (areas.isEmpty ? 0 : 1) + [age, subject, size].whereType<String>().length + (shuttleOnly ? 1 : 0);

  void toggleArea(String a) => _set(() => areas.contains(a) ? areas.remove(a) : areas.add(a));
  void setAge(String? v) => _set(() => age = age == v ? null : v);
  void setSubject(String? v) => _set(() => subject = subject == v ? null : v);
  void setSize(String? v) => _set(() => size = size == v ? null : v);
  void toggleShuttle() => _set(() => shuttleOnly = !shuttleOnly);
  void setQuery(String v) => _set(() => query = v.trim());
  void setSort(String v) => _set(() => sort = v);
  void clear() => _set(() {
    areas.clear();
    age = subject = size = null;
    shuttleOnly = false;
  });

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  /// 나이가 미정인 학원은 학생 구간 필터에서 빼지 않고 뒤로 보낸다.
  List<Academy> get results {
    final q = query;
    final list = _all.where((a) {
      if (areas.isNotEmpty && !areas.contains(a.area)) return false;
      if (age != null && !_ageMatches(a, age!)) return false;
      if (subject != null && !a.subjects.contains(subject)) return false;
      if (size != null && a.size != size) return false;
      if (shuttleOnly && a.shuttle != true) return false;
      if (q.isNotEmpty && !'${a.name} ${a.subjects.join(' ')} ${a.dong} ${a.area} ${a.tags.join(' ')}'.contains(q)) return false;
      return true;
    }).toList();
    int byName(Academy x, Academy y) => x.name.compareTo(y.name);
    int score(Academy a) =>
        (age != null && (a.levels.contains(age) || (age == '성인' && a.adult)) ? 8 : 0) + (a.addr.isNotEmpty ? 2 : 0) + (a.subjects.isNotEmpty ? 1 : 0) + (a.tags.isNotEmpty ? 1 : 0);
    list.sort(switch (sort) {
      '리뷰 많은 순' => (x, y) => y.reviewCount.compareTo(x.reviewCount) != 0 ? y.reviewCount.compareTo(x.reviewCount) : byName(x, y),
      '이름순' => byName,
      _ => (x, y) => score(y).compareTo(score(x)) != 0 ? score(y).compareTo(score(x)) : byName(x, y),
    });
    return list;
  }

  /// 홈 '○○에게 맞는 동네 학원': 우리 동네 + 학교급이 맞거나 미확인 + 관심 과목 우선.
  List<Academy> recommendFor({required String area, String? kidGrade, required List<String> interests, int max = 10}) {
    final lv = kidGrade == null ? null : ageOfGrade(kidGrade);
    final list = _all.where((a) => (area.isEmpty || a.area == area) && (lv == null || _ageMatches(a, lv))).toList();
    int score(Academy a) => (lv != null && a.levels.contains(lv) ? 4 : 0) + (a.subjects.any(interests.contains) ? 2 : 0) + (a.addr.isNotEmpty ? 1 : 0);
    list.sort((x, y) => score(y).compareTo(score(x)) != 0 ? score(y).compareTo(score(x)) : x.name.compareTo(y.name));
    return list.take(max).toList();
  }
}
