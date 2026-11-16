import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// 가입 화면 맨 위 '로고 또는 뒤로 · n / 4 · 진행 막대'.
class SignupProgress extends StatelessWidget {
  const SignupProgress({super.key, required this.step, this.showLogo = false, this.onBack});

  final int step;
  final bool showLogo;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (showLogo) ...[
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.pri, borderRadius: BorderRadius.circular(9)),
                    child: const Text(
                      '알',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('알음알음', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                ] else
                  IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    tooltip: '뒤로',
                  ),
                const Spacer(),
                Text('$step / 4', style: const TextStyle(fontSize: 15, color: AppColors.ink3)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: step / 4),
              duration: const Duration(milliseconds: 350),
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 5, backgroundColor: AppColors.line, color: AppColors.pri),
            ),
          ),
        ],
      ),
    );
  }
}
