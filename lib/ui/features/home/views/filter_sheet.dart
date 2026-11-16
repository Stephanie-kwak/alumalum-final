import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/choices.dart';
import '../../../core/widgets/form_bits.dart';
import '../view_models/academy_search_view_model.dart';

/// 피그마 2-2 상세 필터. '집에서 거리'는 학원 리스트에 좌표가 없어 권역 선택으로 대신한다(설계안 §1).
/// 닫힐 때 true 를 돌려주면 '학원 n곳 보기'를 누른 것.
Future<bool?> showFilterSheet(BuildContext context) {
  final vm = context.read<AcademySearchViewModel>();
  hideKeyboard();
  return showModalBottomSheet<bool>(
    context: context,
    // 탭 안 내비게이터에 열면 하단 탭 바가 시트 아래에 남는다. 피그마 2-2 처럼 화면 전체를 덮는다.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider.value(value: vm, child: const _FilterSheet()),
  );
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademySearchViewModel>();
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .86,
      maxChildSize: .95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('필터', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: '닫기'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                title('지역 · 안양시 동안구'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final a in kAreas) OptionBox(areaName(a), pill: true, selected: vm.areas.contains(a), onTap: () => vm.toggleArea(a))],
                ),
                title('대상 나이'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final l in kAges) OptionBox(l, pill: true, selected: vm.age == l, onTap: () => vm.setAge(l))],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('초·중·고 구간을 고르면 나이가 미정인 학원도 함께 보여요.', style: AppText.small),
                ),
                title('과목'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final s in kSubjects) OptionBox(s, pill: true, selected: vm.subject == s, onTap: () => vm.setSubject(s))],
                ),
                title('학원 규모'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  // 비율로 높이를 정하면 글자를 키운 휴대폰에서 두 줄이 넘친다
                  mainAxisExtent: 68,
                  children: [for (final (s, sub) in kSizes) OptionBox(s, sub: sub, selected: vm.size == s, onTap: () => vm.setSize(s))],
                ),
                title('편의'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OptionBox('셔틀 운행', pill: true, selected: vm.shuttleOnly, onTap: vm.toggleShuttle),
                ),
              ],
            ),
          ),
          BottomAction(
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: AppButton('초기화', icon: Icons.refresh, tone: ButtonTone.outline, onPressed: vm.clear),
                ),
                const SizedBox(width: 10),
                Expanded(child: AppButton('학원 ${vm.results.length}곳 보기', onPressed: () => Navigator.pop(context, true))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
