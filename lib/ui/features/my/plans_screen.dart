import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/back_or_home.dart';

/// 알음알음 요금제 안내(의뢰인 확정 문구 261022). 안내만 하고 결제는 없다.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final TextEditingController _inviteController = TextEditingController();

  void _checkInviteCode() {
    final code = _inviteController.text.trim().toUpperCase();

    if (code == 'ALUM-PLUS-A123') {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🎉 초대코드 확인 완료!'),
          content: const Text(
            '알음알음 PLUS 1개월 무료 이벤트 대상입니다!\n\n'
            '월 4,900원 상당의 혜택을 경험해 보세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바르지 않은 초대코드입니다.')));
    }
  }

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('🎉 알음알음 BIZ 출시 기념'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '첫 3개월 50% 할인!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '정상가 월 99,000원',
                style: TextStyle(decoration: TextDecoration.lineThrough),
              ),
              SizedBox(height: 8),
              Text(
                '이벤트가 월 49,500원',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              SizedBox(height: 16),
              Text('첫 3개월 할인 적용'),
              Text('4개월 차부터 월 99,000원'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('혜택 확인하기'),
            ),
          ],
        ),
      );
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackOrHome(),
        title: const Text('알음알음 요금제'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _Plan(
            name: '알음알음 PLUS',
            target: '학부모 회원',
            price: '월 4,900원',
            accent: AppColors.pri,
            tint: AppColors.priLight,
            items: [
              'AI 상담노트',
              'AI 맞춤 학원 추천',
              '맞춤 알림 서비스',
              '학원 이벤트 정보 제공',
              '제휴 학원 등록 시 교재비 총 1회 지원(추후 영수증 제출)',
              '제휴 학원 동시 등록시 학원 등록비 1회 10% 할인 쿠폰 제공',
            ],
          ),

          const SizedBox(height: 14),

          // 학부모 PLUS 초대코드 이벤트
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎁 PLUS 1개월 무료 이벤트',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('초대코드를 입력하면 PLUS 1개월 무료 혜택!'),
                const SizedBox(height: 16),
                TextField(
                  controller: _inviteController,
                  decoration: const InputDecoration(
                    labelText: 'PLUS 초대코드',
                    hintText: '초대코드를 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkInviteCode,
                    child: const Text('초대코드 등록하기'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _Plan(
            name: '알음알음 BIZ',
            target: '학원 사업자',
            price: '첫 3개월 월 49,500원 (이후 월 99,000원)',
            accent: AppColors.green,
            tint: AppColors.greenLight,
            items: [
              '검색 결과 상단 노출',
              '학원 상세페이지 홍보',
              '학원 이벤트 홍보',
              '학부모 및 학생 학원정보 팝업 노출',
              '조회 수 및 상담 클릭 성과 확인',
            ],
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '🎉 BIZ 출시 기념 할인은 가입 후 첫 3개월에 적용되며, '
              '4개월 차부터 정상 요금 월 99,000원이 적용됩니다.',
              style: AppText.small,
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({
    required this.name,
    required this.target,
    required this.price,
    required this.accent,
    required this.tint,
    required this.items,
  });

  final String name, target, price;
  final Color accent, tint;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: AppText.title.copyWith(fontSize: 18)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  target,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check, size: 18, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      it,
                      style: const TextStyle(fontSize: 15, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
