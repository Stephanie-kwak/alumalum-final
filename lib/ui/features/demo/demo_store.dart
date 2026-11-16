import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/demo.dart';

/// 시연용 데이터와 동작. 서버 없이 앱 메모리에만 둔다(의뢰인 합의 261008: "보이는 것만 있으면 된다").
/// 예시 학원 이름(바른수학 · 리딩트리 영어 · 피아노 하우스 · 생각하는 수학교실)은 실제 동안구 학원 목록과 겹치지 않는 가상 이름이다.
class DemoStore extends ChangeNotifier {
  DemoStore({DateTime? now, this.replyDelay = const Duration(milliseconds: 1500)}) {
    _seed(now ?? DateTime.now());
  }

  /// 상담 채팅에서 학원 자동 답장까지 걸리는 시간(시연용)
  final Duration replyDelay;

  static const lounges = ['설명회', '레벨테스트', '특강', '지역·체험', '개강·모집', '교육팁', '홍보·소식', '구인구직', '익명 커뮤니티'];
  static const worries = ['서술형이 약해요', '연산 실수', '숙제 습관', '심화 도전', '학원 적응'];
  static const progs = ['학교 진도만', '한 학기 선행', '1년 이상 선행'];

  late final List<LoungePost> posts;
  late final List<Job> jobs;
  late final List<Thread> threads;
  late final List<Notice> notices;
  late final List<Homework> homework;
  late final List<Qna> qna;
  late final List<Lesson> lessons;
  late final List<AttendLog> attendance;
  late final List<Noti> notis;
  late final List<Pupil> pupils;
  final Map<String, List<Review>> reviews = {};
  final List<Timer> _timers = [];
  int _seq = 0;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _seed(DateTime now) {
    DateTime day(int n, [int h = 0, int m = 0]) => DateTime(now.year, now.month, now.day + n, h, m);
    const minute = Duration(minutes: 1), hour = Duration(hours: 1);
    posts = [
      LoungePost(
        id: 'p1',
        cat: '설명회',
        title: '2027 중등 수학 로드맵 설명회',
        author: '바른수학 학원',
        region: '평촌동',
        at: now.subtract(minute * 5),
        event: EventInfo(
          day: day(4, 10),
          when: '${mdw(day(4))} 오전 10:00–11:30',
          where: '바른수학 학원 3층 세미나실',
          target: '초5–중2 학부모',
          cost: '무료 · 자녀 동반 가능',
          cap: 40,
          applied: 23,
          steps: ['개정 교육과정과 중등 수학 흐름', '학년별 선행 · 심화 로드맵', '질의응답 · 희망자 개별 상담 예약'],
        ),
      ),
      LoungePost(
        id: 'p2',
        cat: '홍보·소식',
        ad: true,
        title: '피아노 하우스 가을 정기연주회',
        author: '피아노 하우스',
        body: '${mdw(day(6))} · 원생 가족 무료 · 당일 체험 레슨 신청 가능',
        at: now.subtract(hour * 3),
      ),
      LoungePost(
        id: 'p3',
        cat: '익명 커뮤니티',
        title: '초3 수학 선행, 다들 어느 정도 하고 계세요?',
        author: '초3 학부모',
        region: '평촌동',
        body: '학교 진도만 하다가 학원 상담을 받아보니 다들 1년은 앞서 있다고 해서 고민이에요. 아이는 수학을 좋아하는 편인데 서술형을 어려워해요. 선행보다 심화가 먼저일까요?',
        likes: 32,
        at: now.subtract(minute * 12),
        expert: '초3 시기에는 선행 속도보다 서술형 풀이 습관을 먼저 잡는 편이 이후 중등 수학에서 훨씬 유리합니다. 한 단원을 끝낼 때마다 서술형 2문제를 \'식 → 이유 → 답\' 순서로 말로 먼저 설명하게 해 보세요.',
        comments: [
          Comment('익명 1', '저희도 초3 때 심화 위주로 했는데 중학교 가서 서술형 점수가 확실히 안정적이었어요.', now.subtract(minute * 8), who: '중1 학부모'),
          Comment('익명 2', '같은 고민이에요. 레벨테스트 먼저 받아보시는 거 추천해요!', now.subtract(minute * 5), who: '초3 학부모'),
        ],
      ),
      LoungePost(
        id: 'p4',
        cat: '개강·모집',
        title: '11월 초3 사고력반 신규 개강',
        author: '바른수학 학원',
        body: '${mdw(day(12))} 개강 · 주 2회 화·목 16시',
        badge: '잔여 4자리',
        highlight: '첫 달 10% 할인',
        at: now.subtract(hour * 5),
      ),
      LoungePost(
        id: 'p5',
        cat: '레벨테스트',
        title: '초등 영어 무료 레벨테스트',
        author: '리딩트리 영어',
        region: '호계동',
        at: now.subtract(const Duration(days: 1)),
        event: EventInfo(
          day: day(7, 15),
          when: '${mdw(day(7))} 15:00–19:00',
          where: '리딩트리 영어 2층',
          target: '초1–초6',
          cost: '무료 · 예약제',
          cap: 30,
          applied: 12,
          steps: ['리딩 · 리스닝 평가 30분', '결과 상담 10분', '반 배정 안내'],
        ),
      ),
      LoungePost(
        id: 'p6',
        cat: '특강',
        title: '겨울방학 교구 사고력 특강 4주',
        author: '생각하는 수학교실',
        region: '관양동',
        at: now.subtract(const Duration(days: 2)),
        event: EventInfo(
          day: day(20, 10),
          when: '${mdw(day(20))}부터 매주 토 10시',
          where: '생각하는 수학교실',
          target: '초1–초4',
          cost: '4주 과정',
          cap: 12,
          applied: 5,
          steps: ['1주 도형 · 2주 규칙 · 3주 측정 · 4주 발표'],
        ),
      ),
      LoungePost(
        id: 'p7',
        cat: '교육팁',
        title: '초3 분수, 집에서 이렇게 봐 줬어요',
        author: '바른수학 학원',
        body: '피자 그림을 그려서 나눠 보게 했더니 훨씬 빨리 이해하더라고요. 문제집보다 그림이 먼저였어요.',
        likes: 41,
        at: now.subtract(const Duration(hours: 30)),
      ),
      LoungePost(
        id: 'p8',
        cat: '지역·체험',
        title: '동네 어린이 과학 체험 신청 열렸어요',
        author: '리딩트리 영어',
        body: '이번 주 금요일까지 신청이고 선착순이에요.',
        likes: 18,
        at: now.subtract(const Duration(days: 3)),
      ),
    ];
    jobs = [
      Job(side: '구인', kind: '영어 · 파트타임', title: '초등 영어 파트 강사 모집 (주 3일)', meta: '리딩트리 영어 · 호계동 · 월·수·금 15–20시', pay: '시급 협의', due: '마감 D-39'),
      Job(side: '구인', kind: '수학 · 정규직', title: '중등 수학 전임 강사 (내신 담당)', meta: '바른수학 학원 · 평촌동 · 주 5일', pay: '월급 협의 · 4대보험', due: '마감 D-21'),
      Job(side: '구인', kind: '상담 · 관리', title: '데스크 실장 (상담 · 출결 관리)', meta: '생각하는 수학교실 · 관양동 · 주 5일', pay: '월급 협의', due: '마감 D-10'),
      Job(side: '구직', kind: '수학 · 파트타임', title: '수학교육 전공 4학년, 초등 사고력 수업 가능', meta: '평촌 · 호계 · 평일 오후', pay: '희망 협의', due: '3일 전'),
      Job(side: '구직', kind: '미술 · 파트타임', title: '아동미술 경력 5년, 주 2–3회 가능', meta: '관양 · 비산 · 화·목', pay: '희망 협의', due: '1주 전'),
    ];
    threads = [
      Thread(
        id: 't1',
        academy: '바른수학 학원',
        parent: '평촌 초3맘',
        status: '상담 중',
        at: now.subtract(hour * 3),
        card: const ConsultCard(kid: '첫째 · 초3', prog: '한 학기 선행', worries: ['서술형이 약해요', '숙제 습관'], how: '채팅', memo: '문제는 잘 푸는데 풀이 과정을 안 써요.'),
        msgs: [
          Msg(true, '안녕하세요! 서술형은 초3 때 습관을 잡아두면 좋아요. 먼저 40분 레벨테스트로 풀이 습관을 같이 보면 어떨까요?', now.subtract(const Duration(days: 2))),
          Msg(false, '좋아요. 평일 저녁 7시에 가능할까요? 셔틀도 이용할 수 있나요?', now.subtract(const Duration(days: 2)).add(minute * 8)),
          Msg(true, '네, ${mdw(day(1))} 저녁 7시로 예약해 둘게요. 셔틀은 18:40에 단지 정문 앞을 지나요!', now.subtract(hour * 3)),
        ],
      ),
      Thread(
        id: 't2',
        academy: '바른수학 학원',
        parent: '호계동 초3맘',
        incoming: true,
        at: now.subtract(minute * 50),
        card: const ConsultCard(kid: '첫째 · 초3', prog: '학교 진도만', worries: ['연산 실수'], how: '전화', memo: '다니던 학원에서 옮기려고 해요. 초3 2학기 진도 반이 있을까요?'),
      ),
    ];
    notices = [
      Notice(urgent: true, academy: '리딩트리 영어', title: '내일 ${mdw(day(1))} 강풍 예보로 휴원합니다', body: '보강은 이번 주 토요일 오전 10시에 진행돼요.', at: now.subtract(hour * 2)),
    ];
    homework = [
      Homework(academy: '바른수학', title: '사고력 교재 p.24–27', due: '목요일 수업 전까지', done: true, at: now.subtract(hour * 6)),
      Homework(academy: '바른수학', title: '서술형 3문제 — 풀이 과정 꼭 쓰기', due: '목요일 수업 전까지', at: now.subtract(hour * 6)),
      Homework(
        academy: '바른수학',
        comment: true,
        by: '이수아 강사',
        title: '오늘 도형 단원 집중력이 아주 좋았어요. 서술형은 답만 쓰는 습관이 남아 있어서, 집에서도 "왜 그렇게 생각했어?"라고 한 번만 물어봐 주세요.',
        at: now.subtract(hour * 5),
      ),
      Homework(academy: '피아노 하우스', title: '연습곡 체크 — 소나티네 1악장', due: '금요일 레슨 전까지', at: now.subtract(const Duration(days: 1))),
    ];
    qna = [Qna(academy: '바른수학', q: '27쪽 5번에서 왜 넓이를 2로 나눠요?', a: '삼각형은 같은 크기 직사각형의 절반이라서 그래! 목요일에 그림으로 다시 보여줄게.', aBy: '이수아 강사', at: now.subtract(hour * 4))];
    lessons = const [
      Lesson(academy: '리딩트리 영어', label: '영어', color: 2, days: [1, 3, 5], start: '15:00', end: '16:00'),
      Lesson(academy: '바른수학', label: '수학', color: 0, days: [2, 4], start: '16:00', end: '17:30'),
      Lesson(academy: '피아노 하우스', label: '피아노', color: 1, days: [2, 5], start: '18:20', end: '19:10'),
      Lesson(academy: '리딩트리 영어', label: '보강', color: 2, days: [6], start: '10:00', end: '11:00'),
    ];
    attendance = const [
      AttendLog(time: '15:58', kind: '등원', academy: '바른수학', via: '지문 인증 · 셔틀 하차'),
      AttendLog(time: '17:32', kind: '하원', academy: '바른수학', via: '선생님 입력 · 셔틀 탑승'),
      AttendLog(time: '18:20', kind: '등원 예정', academy: '피아노 하우스', via: '10분 지나도 미등원이면 알려드려요', planned: true),
    ];
    notis = [
      Noti(kind: 'hw', lead: '바른수학 ', bold: '숙제 2개', tail: '가 등록됐어요', at: now.subtract(minute * 40)),
      Noti(kind: 'chat', lead: '바른수학에서 ', bold: '상담에 답장', tail: '했어요', at: now.subtract(hour * 3)),
    ];
    pupils = [Pupil('김지우', '초3'), Pupil('이서준', '초3'), Pupil('최하윤', '초3'), Pupil('정도윤', '중3')];
  }

  String _id(String p) => '$p${++_seq}';

  // ── 라운지 ──
  LoungePost post(String id) => posts.firstWhere((p) => p.id == id);

  void toggleLike(LoungePost p) {
    p.liked = !p.liked;
    p.likes += p.liked ? 1 : -1;
    notifyListeners();
  }

  void toggleSave(LoungePost p) {
    p.saved = !p.saved;
    notifyListeners();
  }

  void toggleJoin(EventInfo e) {
    e.joined = !e.joined;
    e.applied += e.joined ? 1 : -1;
    notifyListeners();
  }

  void addComment(LoungePost p, String name, String text) {
    p.comments.add(Comment(name, text, DateTime.now()));
    notifyListeners();
  }

  void addPost({required String cat, required String title, required String body, required String author, required String? ownerUid, EventInfo? event}) {
    posts.insert(0, LoungePost(id: _id('p'), cat: cat, title: title, body: body, author: author, at: DateTime.now(), ownerUid: ownerUid, event: event));
    notifyListeners();
  }

  void addJob(Job j) {
    jobs.insert(0, j);
    notifyListeners();
  }

  // ── 상담 ──
  Thread thread(String id) => threads.firstWhere((t) => t.id == id);

  /// 상담 카드를 보내면 학원마다 상담방이 하나씩 생긴다. 첫 번째 방 ID 를 돌려준다.
  String sendCard({required List<String> academies, required String parent, required ConsultCard card, String? ownerUid}) {
    final now = DateTime.now();
    final made = [for (final a in academies) Thread(id: _id('t'), academy: a, parent: parent, card: card, at: now, ownerUid: ownerUid)];
    threads.insertAll(0, made);
    notifyListeners();
    for (final t in made) {
      _reply(t, '상담 카드 잘 받았어요. ${card.kid.split('·').last.trim()} 아이 맞춤으로 레벨테스트와 반을 안내해 드릴게요. 편하신 시간을 알려주세요!');
    }
    return made.first.id;
  }

  void send(Thread t, String text, {required bool asStaff}) {
    t.msgs.add(Msg(asStaff, text, DateTime.now()));
    t.at = DateTime.now();
    if (asStaff) t.status = '상담 중';
    notifyListeners();
    if (!asStaff) _reply(t, '확인했어요. 담당 선생님이 곧 자세히 안내드릴게요.');
  }

  /// 시연용 학원 자동 답장
  void _reply(Thread t, String text) {
    _timers.add(
      Timer(replyDelay, () {
        t.msgs.add(Msg(true, text, DateTime.now(), auto: true));
        t.status = '상담 중';
        t.at = DateTime.now();
        notis.insert(0, Noti(kind: 'chat', lead: '${t.academy}에서 ', bold: '상담에 답장', tail: '했어요 (시연용 자동 답장)', at: DateTime.now()));
        notifyListeners();
      }),
    );
  }

  // ── 알림 · 알림장 ──
  int get unread => notis.where((n) => !n.read).length + notices.where((n) => n.urgent && !n.acked).length;

  void markAllRead() {
    for (final n in notis) {
      n.read = true;
    }
    notifyListeners();
  }

  void ack(Notice n) {
    n.acked = true;
    notifyListeners();
  }

  void toggleHomework(Homework h) {
    h.done = !h.done;
    notifyListeners();
  }

  void ask(String academy, String q) {
    qna.insert(0, Qna(academy: academy, q: q, at: DateTime.now()));
    notifyListeners();
  }

  // ── 리뷰 ──
  List<Review> reviewsOf(String academyId) => reviews[academyId] ?? const [];

  void addReview(String academyId, Review r) {
    (reviews[academyId] ??= []).insert(0, r);
    notifyListeners();
  }

  // ── 학원 관계자 ──
  void checkIn(Pupil p) {
    final t = hm(DateTime.now());
    if (p.inAt == null) {
      p.inAt = t;
    } else {
      p.outAt ??= t;
    }
    notifyListeners();
  }

  /// 관계자가 보낸 긴급 안내 · 숙제 · 코멘트는 같은 휴대폰의 학부모 · 학생 화면(알림 · 알림장)에 바로 보인다.
  void sendFromAcademy({required String academy, required String kind, required String title, String body = ''}) {
    final now = DateTime.now();
    switch (kind) {
      case '긴급 안내':
        notices.insert(0, Notice(urgent: true, academy: academy, title: title, body: body, at: now));
      case '숙제':
        homework.insert(0, Homework(academy: academy, title: title, due: body, at: now));
        notis.insert(0, Noti(kind: 'hw', lead: '$academy ', bold: '숙제', tail: '가 등록됐어요', at: now));
      default:
        homework.insert(0, Homework(academy: academy, title: title, comment: true, by: '$academy 선생님', at: now));
        notis.insert(0, Noti(kind: 'hw', lead: '$academy ', bold: '선생님 코멘트', tail: '가 왔어요', at: now));
    }
    notifyListeners();
  }
}
