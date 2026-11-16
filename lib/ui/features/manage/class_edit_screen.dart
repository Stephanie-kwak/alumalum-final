import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/academy_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/models/academy.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/choices.dart';
import '../../core/widgets/form_bits.dart';
import '../home/view_models/academy_search_view_model.dart';
import '../session/session_view_model.dart';
import '../../core/widgets/back_or_home.dart';

/// 반 하나 등록 · 수정 (의뢰인 예시 '반별 수강료 관리' 화면). [initial] 이 있으면 수정.
/// 학원은 로그인한 관계자의 소속 학원이다.
class ClassEditScreen extends StatefulWidget {
  const ClassEditScreen({super.key, this.initial});

  final AcademyClass? initial;

  @override
  State<ClassEditScreen> createState() => _ClassEditScreenState();
}

class _ClassEditScreenState extends State<ClassEditScreen> {
  late String _grade = widget.initial?.grade ?? '', _name = widget.initial?.name ?? '', _subject = widget.initial?.subject ?? '';
  late int _perWeek = widget.initial?.perWeek ?? 0;
  late String _minutes = _numText(widget.initial?.minutes), _fee = _numText(widget.initial?.fee), _cap = _numText(widget.initial?.cap);
  Map<String, String> _errors = {};
  bool _busy = false;
  late final _repo = context.read<AcademyRepository>();
  late final _academyId = context.read<SessionViewModel>().profile?.academyId ?? '';
  late final _id = widget.initial?.id ?? _repo.newClassId(_academyId);

  static String _numText(int? v) => v == null ? '' : '$v';
  static int? _int(String v) => int.tryParse(v.replaceAll(RegExp(r'[,\s원분명]'), ''));

  AcademyClass? _validate() {
    final minutes = _int(_minutes), fee = _int(_fee), cap = _int(_cap);
    final e = <String, String>{
      if (_grade.isEmpty) 'grade': '대상 학년을 골라 주세요',
      if (_name.trim().isEmpty) 'name': '반 이름을 적어 주세요',
      if (_subject.isEmpty) 'subject': '과목을 골라 주세요',
      if (_perWeek == 0) 'perWeek': '주당 수업 횟수를 골라 주세요',
      if (minutes == null || minutes < 10 || minutes > 600) 'minutes': '10~600분',
      if (cap == null || cap < 1 || cap > 200) 'cap': '1~200명',
      if (fee == null || fee < 0 || fee > 10000000) 'fee': '월 수강료를 숫자로 적어 주세요 (1천만 원 이하)',
    };
    setState(() => _errors = e);
    if (e.isNotEmpty) return null;
    return AcademyClass(id: _id, grade: _grade, name: _name.trim(), subject: _subject, perWeek: _perWeek, minutes: minutes!, fee: fee!, cap: cap!);
  }

  /// 서버 확인을 기다리되, 오래 걸리면(연결이 끊김) 휴대폰에 저장된 상태로 닫고 연결되면 올라간다고 알린다.
  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    hideKeyboard();
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await task().timeout(const Duration(seconds: 8));
    } on TimeoutException {
      messenger.showSnackBar(const SnackBar(content: Text('인터넷이 연결되면 반영돼요')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(AuthService.messageOf(e))));
      return;
    }
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/manage');
  }

  Future<void> _save() async {
    if (_busy) return;
    final c = _validate();
    if (c != null) await _run(() => _repo.saveClass(_academyId, c));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 반을 지울까요?'),
        content: Text('${widget.initial!.grade} ${widget.initial!.name} 수강료가 학원 상세에서도 사라져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지우기', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _run(() => _repo.deleteClass(_academyId, _id));
  }

  @override
  Widget build(BuildContext context) {
    final feePreview = _int(_fee);
    Widget pills(List<String> items, String selected, ValueChanged<String> onTap) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final it in items) OptionBox(it, pill: true, selected: selected == it, onTap: () => setState(() => onTap(it)))],
    );
    const gap = SizedBox(height: 24);
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(),
        title: Text(widget.initial == null ? '반 추가' : '반 수정'),
        actions: [if (widget.initial != null) IconButton(tooltip: '반 지우기', onPressed: _busy ? null : _delete, icon: const Icon(Icons.delete_outline))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const FieldLabel('대상 학년'),
          pills(kClassGrades, _grade, (v) => _grade = v),
          ErrorText(_errors['grade']),
          gap,
          const FieldLabel('반 이름'),
          AppTextField(fieldKey: const Key('className'), hint: '예: 사고력반', initial: _name, maxLength: 20, error: _errors['name'], onChanged: (v) => _name = v),
          gap,
          const FieldLabel('과목'),
          pills([...kSubjects, '기타'], _subject, (v) => _subject = v),
          ErrorText(_errors['subject']),
          gap,
          const FieldLabel('주당 수업 횟수'),
          pills([for (var i = 1; i <= 7; i++) '주 $i회'], _perWeek == 0 ? '' : '주 $_perWeek회', (v) => _perWeek = int.parse(v.replaceAll(RegExp(r'\D'), ''))),
          ErrorText(_errors['perWeek']),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('1회 수업 시간'),
                    AppTextField(
                      fieldKey: const Key('minutes'),
                      hint: '90',
                      initial: _minutes,
                      keyboard: TextInputType.number,
                      maxLength: 3,
                      suffix: const _Unit('분'),
                      error: _errors['minutes'],
                      onChanged: (v) => _minutes = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('정원'),
                    AppTextField(
                      fieldKey: const Key('cap'),
                      hint: '8',
                      initial: _cap,
                      keyboard: TextInputType.number,
                      maxLength: 3,
                      suffix: const _Unit('명'),
                      error: _errors['cap'],
                      onChanged: (v) => _cap = v,
                    ),
                  ],
                ),
              ),
            ],
          ),
          gap,
          FieldLabel('월 수강료', hint: feePreview == null ? null : '· ${won(feePreview)}'),
          AppTextField(
            fieldKey: const Key('fee'),
            hint: '240000',
            initial: _fee,
            keyboard: TextInputType.number,
            maxLength: 11,
            suffix: const _Unit('원'),
            error: _errors['fee'],
            onChanged: (v) => setState(() => _fee = v),
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        note: '저장하면 학원 상세의 가격 탭에 바로 보여요.',
        child: AppButton(_busy ? '저장 중…' : '저장', onPressed: _busy ? null : _save),
      ),
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Align(
      widthFactor: 1,
      child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.ink3)),
    ),
  );
}
