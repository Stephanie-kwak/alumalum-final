import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// 시연 화면 위에 붙이는 한 줄 안내. 예시 데이터라는 것과 저장되지 않는다는 것을 알린다.
class DemoNote extends StatelessWidget {
  const DemoNote({super.key, this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 12), this.text});

  final EdgeInsets padding;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.ink4),
          const SizedBox(width: 5),
          Expanded(child: Text(text ?? '시연용 예시 화면이에요. 앱을 다시 열면 처음 상태로 돌아가요.', style: AppText.small)),
        ],
      ),
    );
  }
}

/// 탭 첫 화면의 큰 제목 앱바 (MY · 내 학원과 같은 모양)
AppBar bigTitleBar(String title, {List<Widget>? actions}) => AppBar(
  title: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
  titleSpacing: 20,
  automaticallyImplyLeading: false,
  actions: actions,
);

/// 화면 아래 입력줄 (댓글 · 채팅 · 질문)
class ComposeBar extends StatefulWidget {
  const ComposeBar({super.key, required this.hint, required this.onSend, this.fieldKey});

  final String hint;
  final ValueChanged<String> onSend;
  final Key? fieldKey;

  @override
  State<ComposeBar> createState() => _ComposeBarState();
}

class _ComposeBarState extends State<ComposeBar> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    widget.onSend(t);
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: widget.fieldKey,
                controller: _c,
                maxLength: 300,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.line2, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.line2, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.pri, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: '보내기',
              onPressed: _send,
              style: IconButton.styleFrom(backgroundColor: AppColors.pri, foregroundColor: Colors.white, fixedSize: const Size(46, 46)),
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

/// 흰 카드 (라운지 글 · 알림장 묶음)
class WhiteCard extends StatelessWidget {
  const WhiteCard({super.key, required this.child, this.onTap, this.border, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final VoidCallback? onTap;
  final Color? border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: border == null ? BorderSide.none : BorderSide(color: border!, width: 2),
    );
    return Material(
      color: AppColors.paper,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
