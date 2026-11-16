import 'package:flutter/material.dart';

import '../../../domain/models/academy.dart';
import '../../core/theme.dart';

/// 피그마 3-2 반별 수강료 표. 학원 상세는 보기만, '내 학원'은 줄을 눌러 고친다([onTap]).
class ClassFeeTable extends StatelessWidget {
  const ClassFeeTable(this.classes, {super.key, this.onTap});

  final List<AcademyClass> classes;
  final ValueChanged<AcademyClass>? onTap;

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink2);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            color: AppColors.fill,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: const Row(
              children: [
                Expanded(child: Text('반 · 수업', style: head)),
                Text('월 수강료', style: head),
              ],
            ),
          ),
          for (final (i, c) in classes.indexed)
            InkWell(
              onTap: onTap == null ? null : () => onTap!(c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: i == 0 ? null : const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c.grade} ${c.name}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('주 ${c.perWeek}회 · ${c.minutes}분', style: const TextStyle(fontSize: 14.5, color: AppColors.ink2)),
                          Text('${c.subject} · 정원 ${c.cap}명', style: AppText.small),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      won(c.fee),
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    if (onTap != null) const Icon(Icons.chevron_right, size: 20, color: AppColors.ink4),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
