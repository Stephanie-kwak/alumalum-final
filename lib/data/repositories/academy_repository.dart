import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/academy.dart';

/// 학원 목록. 동안구 200여 곳이라 한 번에 받아 두고 검색 · 필터는 휴대폰 안에서 한다.
class AcademyRepository {
  AcademyRepository(this._db);

  final FirebaseFirestore _db;
  List<Academy>? _cache;

  Future<List<Academy>> all({bool refresh = false}) async {
    if (_cache != null && !refresh) return _cache!;
    final snap = await _db.collection('academies').get();
    return _cache = snap.docs.map((d) => Academy.fromJson(d.id, d.data())).toList();
  }

  Future<Academy?> byId(String id) async => (await all()).where((a) => a.id == id).firstOrNull;

  CollectionReference<Map<String, dynamic>> _classes(String academyId) => _db.collection('academies').doc(academyId).collection('classes');

  /// 학원장이 등록한 반별 수강료. 학원 상세와 '내 학원'이 함께 본다. 학년 순 → 반 이름 순.
  Stream<List<AcademyClass>> classesOf(String academyId) => _classes(academyId).limit(50).snapshots().map((s) {
    final list = [
      for (final d in s.docs) AcademyClass.fromJson(d.id, {...d.data(), 'updatedAt': (d.data()['updatedAt'] as Timestamp?)?.toDate()}),
    ];
    int order(AcademyClass c) => kClassGrades.contains(c.grade) ? kClassGrades.indexOf(c.grade) : kClassGrades.length;
    return list..sort((a, b) => order(a) != order(b) ? order(a) - order(b) : a.name.compareTo(b.name));
  });

  /// 새 반의 문서 ID. 화면을 열 때 한 번 정해 두면, 저장을 다시 눌러도 같은 문서에 덮어써서 반이 두 번 생기지 않는다.
  String newClassId(String academyId) => _classes(academyId).doc().id;

  Future<void> saveClass(String academyId, AcademyClass c) => _classes(academyId).doc(c.id).set({...c.toJson(), 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteClass(String academyId, String id) => _classes(academyId).doc(id).delete();
}
