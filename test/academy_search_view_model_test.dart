import 'package:alumalum/data/repositories/academy_repository.dart';
import 'package:alumalum/ui/features/home/view_models/academy_search_view_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AcademySearchViewModel> _vmWith(List<(String, Map<String, dynamic>)> docs) async {
  final db = FakeFirebaseFirestore();
  for (final (id, d) in docs) {
    await db.collection('academies').doc(id).set({
      'subjects': <String>[],
      'levels': <String>[],
      'tags': <String>[],
      'addr': '',
      'dong': '',
      'size': '소형',
      ...d,
    });
  }
  final vm = AcademySearchViewModel(AcademyRepository(db));
  await vm.load();
  return vm;
}

void main() {
  late AcademySearchViewModel vm;

  setUp(() async {
    vm = await _vmWith([
      (
        'A001',
        {
          'name': '가온수학',
          'area': '평촌 학원가',
          'subjects': ['수학'],
          'levels': ['초1-2', '초3-4', '초5-6'],
          'shuttle': true,
          'addr': '평촌대로 1',
        },
      ),
      (
        'A002',
        {
          'name': '나래영어',
          'area': '호계',
          'subjects': ['영어'],
          'adult': true,
        },
      ),
      (
        'A003',
        {
          'name': '다온수학',
          'area': '평촌 학원가',
          'subjects': ['수학'],
          'levels': ['고등'],
        },
      ),
      (
        'A004',
        {
          'name': '라온교습소',
          'area': '비산',
          'size': '공부방·교습소',
          'tags': ['소수정예'],
        },
      ),
    ]);
  });

  test('불러오기', () {
    expect(vm.loading, isFalse);
    expect(vm.results, hasLength(4));
  });

  test('권역 필터', () {
    vm.toggleArea('평촌 학원가');
    expect(vm.results.map((a) => a.id), unorderedEquals(['A001', 'A003']));
    expect(vm.filterCount, 1);
  });

  test('대상 나이 필터는 학교급이 확인되지 않은 학원을 빼지 않고 뒤로 보낸다', () {
    vm.setAge('초3-4');
    final ids = vm.results.map((a) => a.id).toList();
    expect(ids, isNot(contains('A003')));
    expect(ids.first, 'A001');
    expect(ids, containsAll(['A002', 'A004']));
  });

  test('성인은 성인 대상으로 표시된 학원만 보인다 (학교급 미확인이어도 빠진다)', () {
    vm.setAge('성인');
    expect(vm.results.map((a) => a.id), ['A002']);
  });

  test('카드의 대상 나이 표기: 초등 세 구간은 초등으로 줄인다', () {
    final byId = {for (final a in vm.results) a.id: a};
    expect(byId['A001']!.ageText, '초등');
    expect(byId['A002']!.ageText, '성인');
    expect(byId['A004']!.ageText, '나이 미정');
  });

  test('이전 형식(초등)으로 저장된 학원도 초등 구간 필터에 나온다', () async {
    final old = await _vmWith([
      ('B001', {'name': '옛형식', 'area': '호계', 'levels': ['초등', '중등']}),
    ]);
    old.setAge('초5-6');
    expect(old.results.single.ageText, '초등·중등');
  });

  test('카드 나이 표기: 이어진 초등 구간은 하나로', () async {
    final v = await _vmWith([
      ('C1', {'name': 'a', 'area': '호계', 'levels': ['초3-4', '초5-6', '중등'], 'adult': true}),
      ('C2', {'name': 'b', 'area': '호계', 'levels': ['초1-2', '초5-6']}),
    ]);
    final byId = {for (final a in v.results) a.id: a};
    expect(byId['C1']!.ageText, '초3-6·중등·성인');
    expect(byId['C2']!.ageText, '초1-2·초5-6');
  });

  test('같은 값을 다시 고르면 필터가 풀린다', () {
    vm.setSubject('수학');
    expect(vm.results, hasLength(2));
    vm.setSubject('수학');
    expect(vm.results, hasLength(4));
  });

  test('셔틀 · 규모 · 검색어', () {
    vm.toggleShuttle();
    expect(vm.results.single.id, 'A001');
    vm.toggleShuttle();
    vm.setSize('공부방·교습소');
    expect(vm.results.single.id, 'A004');
    vm.clear();
    vm.setQuery('소수정예');
    expect(vm.results.single.id, 'A004');
  });

  test('이름순 정렬', () {
    vm.setSort('이름순');
    expect(vm.sort, '이름순');
    expect(vm.results.map((a) => a.name).toList(), ['가온수학', '나래영어', '다온수학', '라온교습소']);
  });

  test('홈 추천: 학년이 맞는 학원이 먼저, 다른 학교급은 제외', () {
    final picks = vm.recommendFor(area: '평촌 학원가', kidGrade: '초3', interests: const ['수학']);
    expect(picks.map((a) => a.id), ['A001']);
    expect(ageOfGrade('초3'), '초3-4');
    expect(ageOfGrade('초6'), '초5-6');
    expect(ageOfGrade('중1'), '중등');
  });

  test('계정이 바뀌면 이전 계정의 필터가 남지 않는다 (실기기에서 학생 계정에 학부모 동네가 남던 문제)', () {
    vm.startFor('parent', '평촌 학원가');
    vm.setSubject('수학');
    expect(vm.areas, {'평촌 학원가'});
    vm.startFor('parent', '평촌 학원가');
    expect(vm.subject, '수학', reason: '같은 계정이면 그대로 둔다');
    vm.startFor('student', '');
    expect(vm.areas, isEmpty);
    expect(vm.subject, isNull);
  });
}
