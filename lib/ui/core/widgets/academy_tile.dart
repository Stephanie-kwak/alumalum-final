import 'package:flutter/material.dart';

import '../../../domain/models/academy.dart';
import '../theme.dart';

/// 과목별 학원 아이콘(피그마의 Σ · ABC · ♪ 타일). 학원 사진이 없는 데모라 과목 기호로 대신한다.
const _subjectLook = <String, (String, Color, Color)>{
  '수학': ('Σ', AppColors.priMid, AppColors.pri),
  '영어': ('ABC', Color(0xFFD6F0E3), AppColors.green),
  '국어': ('가', Color(0xFFFDE3DE), Color(0xFFB2412A)),
  '과학': ('∆', Color(0xFFE7E3FF), Color(0xFF5B3FD6)),
  '논술': ('✎', Color(0xFFFFE9C7), AppColors.amberText),
  '코딩': ('</>', Color(0xFFE5EDF7), Color(0xFF3B5B85)),
  '미술': ('Art', Color(0xFFFFE4F0), Color(0xFFB0306A)),
  '입시': ('A+', Color(0xFFFCE4EC), Color(0xFFA12A5E)),
  '외국어': ('Hi', Color(0xFFD6F0E3), AppColors.green),
};

class AcademyTile extends StatelessWidget {
  const AcademyTile(this.academy, {super.key, this.size = 64});

  final Academy academy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (glyph, bg, fg) = _subjectLook[academy.mainSubject] ?? ('학', AppColors.fill, AppColors.ink2);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .22)),
      child: Text(
        glyph,
        style: TextStyle(fontSize: size * (glyph.length > 2 ? .3 : .44), fontWeight: FontWeight.w800, color: fg, height: 1),
      ),
    );
  }
}

enum TagTone { blue, green, amber, gray, red, purple, dark }

/// 작은 네모 태그 (피그마 '위치 인증됨' · '업로드 완료' · 카테고리 표시).
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.tone = TagTone.blue});

  final String text;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TagTone.blue => (AppColors.priLight, AppColors.pri),
      TagTone.green => (AppColors.greenLight, AppColors.green),
      TagTone.amber => (AppColors.amberLight, AppColors.amberText),
      TagTone.gray => (AppColors.fill, AppColors.ink2),
      TagTone.red => (AppColors.redLight, AppColors.red),
      TagTone.purple => (AppColors.purpleLight, AppColors.purple),
      TagTone.dark => (AppColors.ink, Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// 내용이 없을 때 가운데 보여 주는 안내.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, required this.message, this.action});

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.priLight, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.pri, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppText.title, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppText.lead.copyWith(color: AppColors.ink3),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
