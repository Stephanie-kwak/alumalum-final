import 'package:flutter/material.dart';

import '../theme.dart';

/// 알약 모양 칩. 고르면 검정 바탕 흰 글자 (피그마 관심 과목 · 필터 칩). ghost 는 "+ 자녀 추가" 같은 보조 칩.
class PillChip extends StatelessWidget {
  const PillChip(this.label, {super.key, required this.selected, required this.onTap, this.icon, this.ghost = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.paper,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.ink : AppColors.line2, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 11 : 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: selected ? Colors.white : AppColors.ink),
              if (icon != null && label.isNotEmpty) const SizedBox(width: 5),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : (ghost ? AppColors.ink3 : AppColors.ink2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 선택 상자. 고르면 연한 블루 바탕 + 블루 테두리 (피그마 직책 · 대상 나이 · 학원 규모).
class OptionBox extends StatelessWidget {
  const OptionBox(this.label, {super.key, required this.selected, required this.onTap, this.sub, this.pill = false, this.height = 48});

  final String label;
  final String? sub;
  final bool selected;
  final bool pill;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = pill ? 999.0 : 12.0;
    return Material(
      color: selected ? AppColors.priLight : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: selected ? AppColors.pri : AppColors.line2, width: selected ? 2 : 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        // Container(alignment:) 는 줄바꿈 배치(Wrap) 안에서 가로를 꽉 채운다. 최소 높이만 주고 너비는 글자에 맞춘다.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: pill ? 38 : height),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: sub == null ? 0 : 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.pri : AppColors.ink2),
                ),
                if (sub != null) Text(sub!, style: TextStyle(fontSize: 12.5, color: selected ? AppColors.pri : AppColors.ink3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 회색 바탕 안에서 흰 알약이 움직이는 세그먼트 (피그마 학년 초등/중등/고등 · 월/주/일).
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.selected, required this.onChanged});

  final List<String> items;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.fill, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(it),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: it == selected ? AppColors.paper : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: it == selected ? const [BoxShadow(color: Color(0x1F151A23), blurRadius: 3, offset: Offset(0, 1))] : null,
                  ),
                  child: Text(
                    it,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: it == selected ? FontWeight.w700 : FontWeight.w500,
                      color: it == selected ? AppColors.ink : AppColors.ink3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
