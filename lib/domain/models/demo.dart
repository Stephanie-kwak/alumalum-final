// 시연용 화면(라운지 · 상담 · 알림 · 알림장 · 리뷰)의 데이터 모양.
// 서버에 저장하지 않고 DemoStore 가 앱 메모리에만 들고 있다(앱을 다시 켜면 예시 데이터로 돌아간다).

class LoungePost {
  LoungePost({
    required this.id,
    required this.cat,
    required this.title,
    required this.author,
    required this.at,
    this.body = '',
    this.region = '',
    this.ad = false,
    this.likes = 0,
    this.event,
    this.expert,
    this.badge,
    this.highlight,
    this.ownerUid,
    List<Comment>? comments,
  }) : comments = comments ?? [];

  final String id, cat, title, author, body, region;
  final DateTime at;
  final bool ad;

  /// 이 휴대폰에서 쓴 글의 작성자 uid. 예시 글은 null.
  final String? ownerUid;

  /// 설명회 · 레벨테스트 · 특강의 일정 정보
  final EventInfo? event;

  /// 익명 커뮤니티의 전문가 답변(PLUS 회원에게 공개)
  final String? expert;

  /// 카드 오른쪽 위 글자(예: '잔여 4자리'). 없으면 몇 분 전.
  final String? badge;

  /// 카드 아래 색 글자(예: '첫 달 10% 할인')
  final String? highlight;
  int likes;
  bool liked = false, saved = false;
  final List<Comment> comments;
}

class EventInfo {
  EventInfo({required this.day, required this.when, required this.where, required this.target, required this.cost, required this.cap, required this.applied, this.steps = const []});

  final DateTime day;
  final String when, where, target, cost;
  final int cap;
  int applied;
  bool joined = false;
  final List<String> steps;
}

class Comment {
  Comment(this.name, this.text, this.at, {this.who = ''});

  final String name, text, who;
  final DateTime at;
}

class Job {
  const Job({required this.side, required this.kind, required this.title, required this.meta, required this.pay, required this.due});

  /// 구인 · 구직
  final String side, kind, title, meta, pay, due;
}

class ConsultCard {
  const ConsultCard({required this.kid, required this.prog, required this.worries, required this.how, required this.memo});

  final String kid, prog, how, memo;
  final List<String> worries;
}

class Thread {
  Thread({required this.id, required this.academy, required this.parent, required this.card, required this.at, this.status = '새 상담', this.incoming = false, this.ownerUid, List<Msg>? msgs}) : msgs = msgs ?? [];

  final String id, academy, parent;

  /// 다른 학부모가 보낸 상담(학원 관계자 상담함에만 보인다)
  final bool incoming;

  /// 상담 카드를 보낸 학부모 uid. 예시 상담은 null(누구에게나 보인다).
  final String? ownerUid;
  final ConsultCard card;
  DateTime at;
  String status;
  final List<Msg> msgs;
}

class Msg {
  Msg(this.fromStaff, this.text, this.at, {this.auto = false});

  final bool fromStaff;

  /// 시연용 자동 답장(실제 학원이 보낸 말이 아님)
  final bool auto;
  final String text;
  final DateTime at;
}

class Notice {
  Notice({required this.academy, required this.title, required this.body, required this.at, this.urgent = false});

  final String academy, title, body;
  final DateTime at;
  final bool urgent;
  bool acked = false;
}

/// 알림장의 숙제 · 선생님 코멘트
class Homework {
  Homework({required this.academy, required this.title, required this.at, this.due = '', this.comment = false, this.by = '', this.done = false});

  final String academy, title, due, by;
  final DateTime at;
  final bool comment;
  bool done;
}

class Qna {
  Qna({required this.academy, required this.q, required this.at, this.a, this.aBy = ''});

  final String academy, q, aBy;
  final DateTime at;
  String? a;
}

/// 주간 시간표 한 칸 묶음. days 는 1(월) ~ 7(일).
class Lesson {
  const Lesson({required this.academy, required this.label, required this.color, required this.days, required this.start, required this.end});

  final String academy, label, start, end;
  final int color;
  final List<int> days;
}

class AttendLog {
  const AttendLog({required this.time, required this.kind, required this.academy, required this.via, this.planned = false});

  final String time, kind, academy, via;
  final bool planned;
}

class Noti {
  Noti({required this.kind, required this.lead, required this.bold, required this.tail, required this.at});

  /// hw · chat · card · notice
  final String kind, lead, bold, tail;
  final DateTime at;
  bool read = false;
}

class Review {
  Review({required this.stars, required this.text, required this.nick, required this.at});

  final int stars;
  final String text, nick;
  final DateTime at;
}

/// 학원 관계자 화면의 원생(출결 입력 대상)
class Pupil {
  Pupil(this.name, this.grade);

  final String name, grade;
  String? inAt, outAt;
}

/// '12분 전' · '3시간 전' · '어제' · '10/14'
String ago(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays < 2) return '어제';
  return '${t.month}/${t.day}';
}

/// '10/24(토)'
String mdw(DateTime t) => '${t.month}/${t.day}(${'월화수목금토일'[t.weekday - 1]})';

String hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
