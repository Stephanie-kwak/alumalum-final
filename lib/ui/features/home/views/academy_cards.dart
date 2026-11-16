import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/academy.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/academy_tile.dart';

/// 홈 가로 카드 (피그마 2-1 '초3에게 맞는 동네 학원')
class AcademyCard extends StatelessWidget {
  const AcademyCard(this.academy, {super.key});

  final Academy academy;

  @override
  Widget build(BuildContext context) {
    final a = academy;
    return SizedBox(
      width: 168,
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/academy/${a.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 96, color: _tileBg(a), alignment: Alignment.center, child: AcademyTile(a, size: 64)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a.dong} · ${a.subjects.isEmpty ? a.sizeText : a.subjects.take(2).join('·')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.shuttle == true ? '셔틀 운행' : a.ageText,
                      maxLines: 1,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: a.shuttle == true ? AppColors.green : AppColors.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 타일 뒤 넓은 면은 타일보다 한 단계 옅게: 타일 자체 색을 그대로 깔면 경계가 사라진다.
  static Color _tileBg(Academy a) => Color.alphaBlend(Colors.white.withValues(alpha: .45), _tileColorOf(a));
  static Color _tileColorOf(Academy a) => switch (a.mainSubject) {
    '수학' => AppColors.priMid,
    '영어' || '외국어' => const Color(0xFFD6F0E3),
    '국어' => const Color(0xFFFDE3DE),
    '과학' => const Color(0xFFE7E3FF),
    '논술' => const Color(0xFFFFE9C7),
    '미술' => const Color(0xFFFFE4F0),
    _ => AppColors.fill,
  };
}

/// 검색 결과 한 줄 (피그마 2-3)
class AcademyRow extends StatelessWidget {
  const AcademyRow(this.academy, {super.key});

  final Academy academy;

  @override
  Widget build(BuildContext context) {
    final a = academy;
    final facts = [a.ageText, a.sizeText, if (a.shuttle == true) '셔틀'].join(' · ');
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/academy/${a.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AcademyTile(a, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      '${a.dong}${a.subjects.isEmpty ? '' : ' · ${a.subjects.join('·')}'}',
                      style: const TextStyle(fontSize: 14, color: AppColors.ink3),
                    ),
                    const SizedBox(height: 3),
                    Text(facts, style: const TextStyle(fontSize: 13.5, color: AppColors.ink3)),
                    if (a.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        a.tags.take(2).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.ink2, height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
