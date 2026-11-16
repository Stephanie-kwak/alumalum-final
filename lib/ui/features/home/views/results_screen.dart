import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/academy_tile.dart';
import '../../../core/widgets/choices.dart';
import '../../../core/widgets/form_bits.dart';
import '../view_models/academy_search_view_model.dart';
import 'academy_cards.dart';
import 'filter_sheet.dart';
import '../../../core/widgets/back_or_home.dart';

/// 피그마 2-3 검색 결과
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, this.focusSearch = false});

  /// 홈 검색창을 눌러 들어온 경우에만 키보드를 바로 띄운다.
  final bool focusSearch;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademySearchViewModel>();
    final list = vm.results;
    final chips = [if (vm.areas.isNotEmpty) vm.areas.map(areaName).join('·'), ?vm.age, ?vm.subject, ?vm.size, if (vm.shuttleOnly) '셔틀'];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const BackOrHome(),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextFormField(
            key: const Key('search'),
            initialValue: vm.query,
            autofocus: focusSearch,
            onChanged: vm.setQuery,
            onTapOutside: (_) => hideKeyboard(),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: '학원명, 과목, 동 이름 검색',
              prefixIcon: Icon(Icons.search, color: AppColors.ink2),
              fillColor: AppColors.fill,
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(14))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(14))),
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              children: [
                PillChip('필터 ${vm.filterCount}', icon: Icons.tune, selected: true, onTap: () => showFilterSheet(context)),
                for (final c in chips) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(c),
                    onPressed: () => showFilterSheet(context),
                    backgroundColor: AppColors.priLight,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: const TextStyle(color: AppColors.pri, fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
          ? EmptyView(
              icon: Icons.wifi_off,
              title: vm.error!,
              message: '인터넷 연결을 확인하고 다시 시도해 주세요',
              action: FilledButton(onPressed: () => vm.load(refresh: true), child: const Text('다시 불러오기')),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        Text('${list.length}곳', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        // 누르면 정렬 목록이 펼쳐지고, 지금 정렬에 체크가 붙는다.
                        PopupMenuButton<String>(
                          initialValue: vm.sort,
                          onSelected: vm.setSort,
                          tooltip: '정렬',
                          position: PopupMenuPosition.under,
                          color: AppColors.paper,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          itemBuilder: (_) => [
                            for (final s in kSorts)
                              PopupMenuItem(
                                value: s,
                                height: 46,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: s == vm.sort ? FontWeight.w700 : FontWeight.w500,
                                          color: s == vm.sort ? AppColors.pri : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (s == vm.sort) const Icon(Icons.check, size: 20, color: AppColors.pri),
                                  ],
                                ),
                              ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(vm.sort, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                const Icon(Icons.expand_more, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (list.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyView(
                      icon: Icons.search_off,
                      title: '조건에 맞는 학원이 없어요',
                      message: '필터를 줄이거나 다른 이름으로 찾아 보세요',
                      action: OutlinedButton(onPressed: vm.clear, child: const Text('필터 초기화')),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => AcademyRow(list[i]),
                    ),
                  ),
              ],
            ),
    );
  }
}
