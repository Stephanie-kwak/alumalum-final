import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/choices.dart';
import '../../core/widgets/form_bits.dart';
import '../demo/demo_store.dart';
import '../demo/demo_widgets.dart';
import '../../core/widgets/back_or_home.dart';

/// 학원 관계자 출결 입력(시연). 누르면 등원, 한 번 더 누르면 하원 시각이 찍힌다.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(leading: const BackOrHome(), title: const Text('오늘 출결')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const DemoNote(padding: EdgeInsets.fromLTRB(4, 4, 4, 12)),
          for (final p in store.pupils)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WhiteCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.priLight,
                      child: Text(
                        p.name[0],
                        style: const TextStyle(color: AppColors.pri, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p.name} · ${p.grade}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                          Text(
                            [if (p.inAt != null) '등원 ${p.inAt}', if (p.outAt != null) '하원 ${p.outAt}'].join(' · ').ifEmpty('아직 안 왔어요'),
                            style: AppText.small,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      p.inAt == null ? '등원' : (p.outAt == null ? '하원' : '완료'),
                      tone: p.inAt == null ? ButtonTone.green : ButtonTone.dark,
                      height: 38,
                      expand: false,
                      onPressed: p.outAt == null ? () => store.checkIn(p) : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

/// 학원 관계자가 알림장 · 긴급 안내를 보내는 화면(시연). 보낸 내용은 같은 휴대폰의 알림 · 알림장에 바로 보인다.
class SendNoticeScreen extends StatefulWidget {
  const SendNoticeScreen({super.key, required this.academy});

  final String academy;

  @override
  State<SendNoticeScreen> createState() => _SendNoticeScreenState();
}

class _SendNoticeScreenState extends State<SendNoticeScreen> {
  String _kind = '숙제', _title = '', _body = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final (titleHint, bodyLabel, bodyHint) = switch (_kind) {
      '긴급 안내' => ('예) 내일 강풍 예보로 휴원합니다', '자세한 안내', '예) 보강은 토요일 오전 10시에 진행해요'),
      '숙제' => ('예) 교재 p.24–27', '기한', '예) 목요일 수업 전까지'),
      _ => ('예) 오늘 도형 단원 집중력이 좋았어요', '', ''),
    };
    void submit() {
      if (_title.trim().isEmpty) {
        setState(() => _error = '내용을 적어 주세요');
        return;
      }
      context.read<DemoStore>().sendFromAcademy(academy: widget.academy, kind: _kind, title: _title.trim(), body: _body.trim());
      hideKeyboard();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보냈어요. 학부모 · 학생 화면에 바로 보여요')));
      context.pop();
    }

    return Scaffold(
      appBar: AppBar(leading: const BackOrHome(), title: const Text('알림장 · 안내 보내기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const FieldLabel('종류'),
          Row(
            children: [
              for (final (i, k) in ['숙제', '선생님 코멘트', '긴급 안내'].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: OptionBox(
                    k,
                    selected: _kind == k,
                    onTap: () => setState(() {
                      _kind = k;
                      _title = _body = '';
                      _error = null;
                    }),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          const FieldLabel('내용'),
          AppTextField(
            key: ValueKey(_kind),
            fieldKey: const Key('noticeTitle'),
            hint: titleHint,
            maxLength: 200,
            maxLines: _kind == '선생님 코멘트' ? 4 : 1,
            error: _error,
            onChanged: (v) => _title = v,
          ),
          if (bodyLabel.isNotEmpty) ...[
            const SizedBox(height: 22),
            FieldLabel(bodyLabel),
            AppTextField(key: ValueKey('b$_kind'), fieldKey: const Key('noticeBody'), hint: bodyHint, maxLength: 200, onChanged: (v) => _body = v),
          ],
        ],
      ),
      bottomNavigationBar: BottomAction(
        note: _kind == '긴급 안내' ? '학부모 알림 맨 위에 빨간 카드로 보여요.' : '학부모 · 학생 알림장에 보여요.',
        child: AppButton('보내기', tone: _kind == '긴급 안내' ? ButtonTone.red : ButtonTone.primary, onPressed: submit),
      ),
    );
  }
}
