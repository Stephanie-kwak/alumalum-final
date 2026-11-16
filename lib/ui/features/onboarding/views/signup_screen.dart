import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/academy_repository.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/academy.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/academy_tile.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/choices.dart';
import '../../../core/widgets/form_bits.dart';
import '../../home/view_models/academy_search_view_model.dart';
import '../view_models/signup_view_model.dart';
import 'signature_pad.dart';
import 'signup_progress.dart';

/// 피그마 1-2 기본 정보 · 1-3a/b/c 유형별 프로필 · 1-4 약관 동의 · 서명
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final body = switch (vm.step) {
      2 => const _BasicStep(),
      3 => switch (vm.role) {
        UserRole.parent => const _ParentStep(),
        UserRole.staff => const _StaffStep(),
        UserRole.student => const _StudentStep(),
      },
      _ => const _ConsentStep(),
    };
    return PopScope(
      canPop: vm.step == 2,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SignupProgress(step: vm.step, onBack: vm.step == 2 ? null : vm.back),
              Expanded(
                child: ListView(key: ValueKey(vm.step), padding: const EdgeInsets.fromLTRB(20, 22, 20, 28), children: [body, ErrorText(vm.errors['submit'])]),
              ),
              BottomAction(
                line: false,
                child: AppButton(
                  vm.busy
                      ? '처리 중…'
                      : switch (vm.step) {
                          2 => '인증하고 다음',
                          3 => '다음',
                          _ => '동의하고 가입 완료',
                        },
                  onPressed: vm.busy ? null : () => vm.next(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, this.lead, {this.badge});

  final String title;
  final String lead;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.priLight, borderRadius: BorderRadius.circular(999)),
            child: Text(
              badge!,
              style: const TextStyle(color: AppColors.pri, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(title, style: AppText.h1),
        const SizedBox(height: 6),
        Text(lead, style: AppText.lead),
        const SizedBox(height: 24),
      ],
    );
  }
}

const _gap = SizedBox(height: 22);

// ───────── 1-2 기본 정보 ─────────
class _BasicStep extends StatefulWidget {
  const _BasicStep();

  @override
  State<_BasicStep> createState() => _BasicStepState();
}

class _BasicStepState extends State<_BasicStep> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.read<SignupViewModel>().codeSentAt != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final e = vm.errors;
    final left = vm.codeSentAt == null ? 0 : (180 - DateTime.now().difference(vm.codeSentAt!).inSeconds).clamp(0, 180);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title('기본 정보를 입력해 주세요', '휴대폰 인증을 마친 회원만 활동할 수 있어요.', badge: '${vm.role.label}로 가입 중'),
        const FieldLabel('아이디'),
        AppTextField(
          fieldKey: const Key('loginId'),
          maxLength: 20,
          hint: '영문 · 숫자 4–20자 또는 한글 2–10자',
          initial: vm.loginId,
          error: e['loginId'],
          onChanged: (v) => vm.loginId = v,
        ),
        _gap,
        const FieldLabel('비밀번호'),
        AppTextField(
          fieldKey: const Key('password'),
          hint: '영문·숫자 포함 8자 이상',
          obscure: true,
          initial: vm.password,
          error: e['password'],
          onChanged: (v) => vm.password = v,
        ),
        const SizedBox(height: 10),
        AppTextField(
          fieldKey: const Key('password2'),
          hint: '비밀번호 확인',
          obscure: true,
          initial: vm.password2,
          error: e['password2'],
          onChanged: (v) => vm.password2 = v,
        ),
        _gap,
        const FieldLabel('휴대폰 번호'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                fieldKey: const Key('phone'),
                maxLength: 13,
                hint: '010-0000-0000',
                keyboard: TextInputType.phone,
                initial: vm.phone,
                error: e['phone'],
                onChanged: (v) => vm.phone = v,
              ),
            ),
            const SizedBox(width: 10),
            AppButton(vm.codeSentAt == null ? '인증 요청' : '재요청', tone: ButtonTone.dark, height: 50, expand: false, onPressed: vm.sendCode),
          ],
        ),
        if (vm.codeSentAt != null) ...[
          const SizedBox(height: 10),
          AppTextField(
            fieldKey: const Key('code'),
            hint: '인증번호 6자리',
            keyboard: TextInputType.number,
            maxLength: 6,
            initial: vm.code,
            error: e['code'],
            onChanged: (v) => vm.code = v,
            suffix: Padding(
              padding: const EdgeInsets.only(right: 16, top: 14),
              child: Text(
                '${'${left ~/ 60}'.padLeft(2, '0')}:${'${left % 60}'.padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text('데모: 아무 숫자 6자리면 통과해요. 실제 문자 발송은 옵션이에요.', style: AppText.small),
        ],
        _gap,
        const FieldLabel('이메일', hint: '(선택)'),
        AppTextField(
          hint: '상담노트·영수증 사본을 받을 이메일',
          maxLength: 100,
          keyboard: TextInputType.emailAddress,
          initial: vm.email,
          error: e['email'],
          onChanged: (v) => vm.email = v,
        ),
      ],
    );
  }
}

// ───────── 1-3a 학부모 프로필 ─────────
class _ParentStep extends StatelessWidget {
  const _ParentStep();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final e = vm.errors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('학부모 프로필', '자녀 학년과 동네에 맞는 학원을 먼저 보여드려요.'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(color: AppColors.priLight, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: AppColors.pri, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('닉네임', hint: '· 라운지에 표시돼요'),
                  AppTextField(
                    fieldKey: const Key('nick'),
                    maxLength: 30,
                    hint: '예) 평촌동 초3맘',
                    initial: vm.nick,
                    error: e['nick'],
                    onChanged: (v) => vm.nick = v,
                  ),
                ],
              ),
            ),
          ],
        ),
        _gap,
        const FieldLabel('우리 동네', hint: '· 안양시 동안구'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final a in kAreas) OptionBox(areaName(a), pill: true, selected: vm.area == a, onTap: () => vm.update(() => vm.area = a))],
        ),
        ErrorText(e['area']),
        _gap,
        const FieldLabel('자녀 정보'),
        // 높이를 비율로 고정하면 글자 크기에 따라 카드가 넘친다. 가로만 반씩 나누고 높이는 내용에 맞춘다.
        if (vm.kids.isNotEmpty)
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (i, k) in vm.kids.indexed)
                  SizedBox(
                    width: (c.maxWidth - 10) / 2,
                    child: InkWell(
                      onTap: () => vm.removeKid(i),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.priLight,
                          border: Border.all(color: AppColors.pri, width: 2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              k.order,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.pri),
                            ),
                            Text(_gradeLong(k.grade), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            Text('${k.birthYear}년생 · ${k.sex}', style: const TextStyle(fontSize: 13.5, color: AppColors.ink3)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (vm.kids.isNotEmpty) const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: vm.kids.length >= SignupViewModel.maxKids ? null : () => _addKid(context, vm),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              vm.kids.length >= SignupViewModel.maxKids ? '자녀는 ${SignupViewModel.maxKids}명까지 등록할 수 있어요' : '자녀 추가',
              style: const TextStyle(fontSize: 15.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink2,
              side: const BorderSide(color: AppColors.line2, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (vm.kids.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('카드를 누르면 빠져요.', style: AppText.small),
          ),
        ErrorText(e['kids']),
        _gap,
        const FieldLabel('관심 과목', hint: '· 여러 개 선택'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in kSubjects) PillChip(s, selected: vm.interests.contains(s), onTap: () => vm.toggle(vm.interests, s))],
        ),
      ],
    );
  }

  static String _gradeLong(String g) =>
      '${switch (g[0]) {
        '초' => '초등',
        '중' => '중학',
        _ => '고등',
      }} ${g.substring(1)}학년';

  Future<void> _addKid(BuildContext context, SignupViewModel vm) async {
    hideKeyboard();
    final r = await showModalBottomSheet<(String, String)>(context: context, isScrollControlled: true, builder: (_) => const _KidSheet());
    if (r != null) vm.addKid(r.$1, r.$2);
  }
}

class _KidSheet extends StatefulWidget {
  const _KidSheet();

  @override
  State<_KidSheet> createState() => _KidSheetState();
}

class _KidSheetState extends State<_KidSheet> {
  String? _grade, _sex;
  static const _grades = ['초1', '초2', '초3', '초4', '초5', '초6', '중1', '중2', '중3', '고1', '고2', '고3'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('자녀 추가', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              const FieldLabel('학년'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final g in _grades) OptionBox(g, pill: true, selected: _grade == g, onTap: () => setState(() => _grade = g))],
              ),
              const SizedBox(height: 18),
              const FieldLabel('성별'),
              Row(
                children: [
                  for (final s in ['여', '남']) ...[
                    Expanded(
                      child: OptionBox(s, selected: _sex == s, onTap: () => setState(() => _sex = s)),
                    ),
                    if (s == '여') const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              AppButton('추가하기', onPressed: _grade == null || _sex == null ? null : () => Navigator.pop(context, (_grade!, _sex!))),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────── 1-3b 학원 관계자 프로필 ─────────
class _StaffStep extends StatefulWidget {
  const _StaffStep();

  @override
  State<_StaffStep> createState() => _StaffStepState();
}

class _StaffStepState extends State<_StaffStep> {
  late final Future<List<Academy>> _academies;
  String _q = '';

  @override
  void initState() {
    super.initState();
    final repo = context.read<AcademyRepository>();
    _academies = context.read<AuthService>().ensureGuest().then((_) => repo.all());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final e = vm.errors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('학원 관계자 프로필', '학원 인증이 끝나면 학원 페이지·알림장·홍보를 직접 관리할 수 있어요.'),
        const FieldLabel('직책'),
        Row(
          children: [
            for (final (i, p) in ['원장', '강사', '실장·상담'].indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: OptionBox(p, selected: vm.position == p, onTap: () => vm.update(() => vm.position = p)),
              ),
            ],
          ],
        ),
        _gap,
        const FieldLabel('이름'),
        AppTextField(
          fieldKey: const Key('staffName'),
          maxLength: 30,
          hint: '예) 김도현',
          initial: vm.staffName,
          error: e['staffName'],
          onChanged: (v) => vm.staffName = v,
        ),
        _gap,
        const FieldLabel('우리 학원 찾기'),
        AppTextField(hint: '학원명 또는 동 이름 검색', prefix: const Icon(Icons.search), onChanged: (v) => setState(() => _q = v.trim())),
        const SizedBox(height: 10),
        FutureBuilder(
          future: _academies,
          builder: (context, snap) {
            if (snap.hasError) return const Text('학원 목록을 불러오지 못했어요', style: AppText.small);
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final picked = snap.data!.where((a) => a.id == vm.academyId);
            final found = _q.isEmpty ? const <Academy>[] : snap.data!.where((a) => a.id != vm.academyId && '${a.name} ${a.dong}'.contains(_q)).take(4);
            return Column(
              children: [
                for (final a in [...picked, ...found])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: AppColors.fill,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: vm.academyId == a.id ? const BorderSide(color: AppColors.pri, width: 2) : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => vm.update(() => vm.academyId = a.id),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              AcademyTile(a, size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    Text('안양시 동안구 ${a.dong}', style: AppText.small),
                                  ],
                                ),
                              ),
                              if (vm.academyId == a.id) const Icon(Icons.check_circle, color: AppColors.pri),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_q.isNotEmpty && found.isEmpty && picked.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('검색 결과가 없어요', style: AppText.small),
                  ),
              ],
            );
          },
        ),
        ErrorText(e['academy']),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('새 학원 등록 신청서가 열려요 (데모)'))),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              '우리 학원이 없나요? 새로 등록하기',
              style: TextStyle(color: AppColors.pri, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        _gap,
        const FieldLabel('운영 과목', hint: '· 여러 개 선택'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in kSubjects) PillChip(s, selected: vm.subjects.contains(s), onTap: () => vm.toggle(vm.subjects, s))],
        ),
        _gap,
        const FieldLabel('학원 인증 서류'),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line2, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (final (i, (k, n)) in [('biz', '사업자등록증'), ('reg', '학원 등록증 또는 교습소 신고증')].indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.line),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(n, style: const TextStyle(fontSize: 15))),
                      vm.docs.contains(k)
                          ? const Tag('업로드 완료', tone: TagTone.green)
                          : AppButton(
                              '촬영',
                              icon: Icons.photo_camera_outlined,
                              tone: ButtonTone.outline,
                              height: 40,
                              expand: false,
                              onPressed: () => vm.toggle(vm.docs, k),
                            ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 7),
        const Text("검토는 1영업일 안에 끝나요. 그 전까지는 학원 페이지에 '인증 대기'로 표시돼요. (데모: 촬영을 누르면 바로 올라가요)", style: AppText.small),
      ],
    );
  }
}

// ───────── 1-3c 학생 프로필 ─────────
class _StudentStep extends StatelessWidget {
  const _StudentStep();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final e = vm.errors;
    final max = vm.level == '초등' ? 6 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('학생 프로필', '보호자와 연결하면 알림장과 출결을 함께 볼 수 있어요.'),
        const FieldLabel('이름', hint: '· 선생님에게만 보여요'),
        AppTextField(
          fieldKey: const Key('studentName'),
          maxLength: 30,
          hint: '실명을 입력해 주세요',
          initial: vm.studentName,
          error: e['studentName'],
          onChanged: (v) => vm.studentName = v,
        ),
        _gap,
        const FieldLabel('학년'),
        Segmented(
          items: kLevels,
          selected: vm.level,
          onChanged: (v) => vm.update(() {
            vm.level = v;
            vm.gradeNum = 0;
          }),
        ),
        // 성인은 학년이 없다
        if (vm.level != '성인') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= 6; i++) ...[
                if (i > 1) const SizedBox(width: 8),
                Expanded(
                  child: Visibility(
                    visible: i <= max,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: OptionBox('$i', selected: vm.gradeNum == i, onTap: () => vm.update(() => vm.gradeNum = i)),
                  ),
                ),
              ],
            ],
          ),
          ErrorText(e['grade']),
        ],
        _gap,
        const FieldLabel('보호자 연결', hint: '(선택)'),
        if (vm.linkedParent != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(12)),
            child: Text(
              '${vm.linkedParent!.name}님과 연결돼요',
              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(hint: '보호자 연결 코드 6자리', keyboard: TextInputType.number, maxLength: 6, error: e['link'], onChanged: (v) => vm.linkCode = v),
              ),
              const SizedBox(width: 10),
              AppButton('연결', tone: ButtonTone.dark, height: 50, expand: false, onPressed: vm.busy ? null : vm.linkParent),
            ],
          ),
          const SizedBox(height: 7),
          const Text('보호자 앱 MY › 자녀 연결에서 코드를 확인할 수 있어요.', style: AppText.small),
        ],
      ],
    );
  }
}

// ───────── 1-4 약관 동의 · 서명 ─────────
class _ConsentStep extends StatefulWidget {
  const _ConsentStep();

  @override
  State<_ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<_ConsentStep> {
  final _pad = GlobalKey<SignaturePadState>();

  static const _items = [
    ('terms', true, '서비스 이용약관'),
    ('privacy', true, '개인정보 수집·이용 동의'),
    ('child', true, '자녀(아동) 개인정보 처리 동의'),
    ('location', false, '위치기반 서비스 이용'),
    ('event', false, '이벤트·혜택 알림 수신'),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('약관에 동의해 주세요', '자녀 정보와 출결 기록을 다루기 때문에 꼭 필요한 항목만 받아요.'),
        Material(
          color: AppColors.priLight,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: vm.toggleAll,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: vm.allAgreed ? AppColors.pri : AppColors.line2, size: 26),
                  const SizedBox(width: 14),
                  const Text('전체 동의', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final (k, req, name) in _items)
          InkWell(
            onTap: () => vm.toggle(vm.agreed, k),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.check, color: vm.agreed.contains(k) ? AppColors.pri : AppColors.line2, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: req ? '[필수] ' : '[선택] ',
                            style: TextStyle(fontWeight: FontWeight.w700, color: req ? AppColors.pri : AppColors.ink2),
                          ),
                          TextSpan(text: name),
                        ],
                      ),
                      style: const TextStyle(fontSize: 15.5),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.ink4),
                ],
              ),
            ),
          ),
        ErrorText(vm.errors['agree']),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(vm.role == UserRole.staff ? '본인 전자서명' : '보호자 전자서명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () => _pad.currentState?.clear(),
                    child: const Text('다시 쓰기', style: TextStyle(color: AppColors.ink3, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SignaturePad(key: _pad, onChanged: (b) => vm.update(() => vm.signature = b)),
              const SizedBox(height: 8),
              Text('${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} · 서명 시각과 기기 정보가 함께 저장돼요', style: AppText.small),
              ErrorText(vm.errors['signature']),
              const SizedBox(height: 6),
              const Text('만 14세 미만 학생 계정은 연결된 보호자의 서명이 있어야 활성화돼요.', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
            ],
          ),
        ),
      ],
    );
  }
}
