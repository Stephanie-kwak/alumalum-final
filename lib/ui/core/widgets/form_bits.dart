import 'package:flutter/material.dart';

import '../theme.dart';

/// 키보드를 내리고 입력칸 포커스를 푼다. 시트를 열기 전에 부르면 시트가 닫힐 때 포커스가 입력칸으로 되돌아가지 않는다.
void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

/// 입력칸 위 제목. [hint] 는 회색 보조 문구 (예: '닉네임 · 라운지에 표시돼요').
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: AppText.label,
          children: [
            if (hint != null)
              TextSpan(
                text: ' $hint',
                style: AppText.label.copyWith(fontWeight: FontWeight.w400, color: AppColors.ink3),
              ),
          ],
        ),
      ),
    );
  }
}

/// 한 줄 입력칸. 오류가 있으면 빨간 테두리와 아래 문장.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initial = '',
    this.error,
    this.obscure = false,
    this.keyboard,
    this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.fieldKey,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initial;
  final String? error;
  final bool obscure;
  final TextInputType? keyboard;
  final int? maxLength;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;

  /// 테스트에서 칸을 찾을 때 쓰는 키
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      initialValue: initial,
      onChanged: onChanged,
      // 휴대폰에서는 입력칸 밖을 눌러도 포커스가 남아 있어서 직접 푼다.
      onTapOutside: (_) => hideKeyboard(),
      obscureText: obscure,
      keyboardType: keyboard,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(hintText: hint, errorText: error, counterText: '', prefixIcon: prefix, suffixIcon: suffix, errorMaxLines: 2),
    );
  }
}

/// 회색 안내 상자.
class InfoBox extends StatelessWidget {
  const InfoBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: AppText.lead.copyWith(fontSize: 14.5)),
    );
  }
}

/// 칸 아래 빨간 오류 문장 (입력칸이 아닌 묶음용).
class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        text!,
        style: const TextStyle(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w600),
      ),
    );
  }
}
