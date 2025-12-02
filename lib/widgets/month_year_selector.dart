import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/controllers/expense_provider.dart';
import 'package:personal_finance/helper/app_formater.dart';

enum SelectorPlacement { appBar, body }

class MonthYearSelector extends ConsumerWidget {
  final SelectorPlacement placement;

  const MonthYearSelector({Key? key, this.placement = SelectorPlacement.body})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonthYear = ref.watch(selectedMonthYearProvider);
    final currentYear = DateTime.now().year;
    final List<int> years = List.generate(5, (index) => currentYear - index);

    final monthDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMonthYear.month,
          items: List.generate(12, (index) {
            final month = index + 1;
            return DropdownMenuItem(
              value: month,
              child: Text(
                AppFormatters.getMonthName(month),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            );
          }),
          onChanged: (int? newMonth) {
            if (newMonth != null) {
              ref.read(selectedMonthYearProvider.notifier).state = DateTime(
                selectedMonthYear.year,
                newMonth,
                selectedMonthYear.day,
              );
            }
          },
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );

    final yearDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMonthYear.year,
          items: years
              .map(
                (year) => DropdownMenuItem(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              )
              .toList(),
          onChanged: (int? newYear) {
            if (newYear != null) {
              ref.read(selectedMonthYearProvider.notifier).state = DateTime(
                newYear,
                selectedMonthYear.month,
                selectedMonthYear.day,
              );
            }
          },
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: placement == SelectorPlacement.appBar
          ? MainAxisAlignment.end
          : MainAxisAlignment.center,
      children: [
        monthDropdown,
        const SizedBox(width: 10),
        yearDropdown,
      ],
    );
  }
}
