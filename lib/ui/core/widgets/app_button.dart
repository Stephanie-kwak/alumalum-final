import 'package:flutter/material.dart';

import '../theme.dart';

enum ButtonTone { primary, dark, outline, strongOutline, amber, green, red }

/// 앱 공통 버튼. 큰 버튼(56)은 화면 아래 확인 버튼, md(48)·sm(40)은 카드 안 버튼.
class AppButton extends StatelessWidget {
  const AppButton(this.label, {super.key, required this.onPressed, this.tone = ButtonTone.primary, this.icon, this.height = 56, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      ButtonTone.primary => (AppColors.pri, Colors.white, null),
      ButtonTone.dark => (AppColors.ink, Colors.white, null),
      ButtonTone.outline => (AppColors.paper, AppColors.ink, AppColors.line2),
      ButtonTone.strongOutline => (AppColors.paper, AppColors.ink, AppColors.ink),
      ButtonTone.amber => (AppColors.amber, AppColors.amberText, null),
      ButtonTone.green => (AppColors.green, Colors.white, null),
      ButtonTone.red => (AppColors.red, Colors.white, null),
    };
    final small = height < 50;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: small ? 18 : 20), const SizedBox(width: 6)],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: .35),
          disabledForegroundColor: fg.withValues(alpha: .8),
          padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
          textStyle: TextStyle(fontFamily: 'Pretendard', fontSize: small ? 14.5 : 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(small ? 10 : AppRadius.button),
            side: border == null ? BorderSide.none : BorderSide(color: border, width: tone == ButtonTone.strongOutline ? 2 : 1.5),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 화면 맨 아래 고정 버튼 영역. 위에 얇은 선이 있고 키보드가 올라오면 함께 올라간다.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child, this.note, this.line = true});

  final Widget child;
  final String? note;
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: line ? const Border(top: BorderSide(color: AppColors.line)) : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(note!, textAlign: TextAlign.center, style: AppText.small),
              ),
            child,
          ],
        ),
      ),
    );
  }
}
