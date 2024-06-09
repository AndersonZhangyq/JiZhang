import 'dart:core';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/chart/monthYearPicker.dart';
import 'package:ji_zhang/widget/loading.dart';
import 'package:ji_zhang/widget/transaction/conditionedTransaction.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

class CompareChartWidget extends StatefulWidget {
  const CompareChartWidget({Key? key}) : super(key: key);

  @override
  _CompareChartWidgetState createState() => _CompareChartWidgetState();
}

class _CompareChartWidgetState extends State<CompareChartWidget> {
  late MyDatabase db;
  ValueNotifier<DateTime?> leftDateNotifier = ValueNotifier<DateTime?>(null);
  ValueNotifier<DateTime?> rightDateNotifier = ValueNotifier<DateTime?>(null);
  bool isLeftMonth = false, isRightMonth = false;
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  String? getSelectedDateStr(bool isMonth, DateTime? date) {
    if (date == null) {
      return null;
    }
    if (isMonth) {
      return DateFormat('yyyy-MM').format(date);
    } else {
      return DateFormat('yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder(
                        valueListenable: leftDateNotifier,
                        builder: (context, date, _) {
                          return TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  isScrollControlled: false,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CustomDatePickerDialog(
                                    disabledMonths: [],
                                    onConfirm: (isMonth, args) {
                                      isLeftMonth = isMonth;
                                      if (isMonth) {
                                        leftDateNotifier.value = DateTime.now()
                                            .copyWith(
                                                year: args['year'],
                                                month: args['month'],
                                                day: 1);
                                      } else {
                                        leftDateNotifier.value = DateTime.now()
                                            .copyWith(
                                                year: args['year'],
                                                month: 1,
                                                day: 1);
                                      }
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                    color: leftDateNotifier.value == null
                                        ? Colors.transparent
                                        : Colors.blueAccent,
                                    width: 2.0, // Underline thickness
                                  )),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    getSelectedDateStr(isLeftMonth,
                                            leftDateNotifier.value) ??
                                        AppLocalizations.of(context)!
                                            .compareChart_SelectDate,
                                    style: leftDateNotifier.value == null
                                        ? null
                                        : TextStyle(
                                            color: Colors.black,
                                          ),
                                  ),
                                ),
                              ));
                        })
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ValueListenableBuilder(
                        valueListenable: rightDateNotifier,
                        builder: (context, date, _) {
                          return TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  isScrollControlled: false,
                                  context: context,
                                  builder: (BuildContext context) =>
                                      CustomDatePickerDialog(
                                    disabledMonths: [],
                                    onConfirm: (isMonth, args) {
                                      isRightMonth = isMonth;
                                      if (isMonth) {
                                        rightDateNotifier.value = DateTime.now()
                                            .copyWith(
                                                year: args['year'],
                                                month: args['month'],
                                                day: 1);
                                      } else {
                                        rightDateNotifier.value = DateTime.now()
                                            .copyWith(
                                                year: args['year'],
                                                month: 1,
                                                day: 1);
                                      }
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                    color: rightDateNotifier.value == null
                                        ? Colors.transparent
                                        : Colors.blueAccent,
                                    width: 2.0, // Underline thickness
                                  )),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    getSelectedDateStr(isRightMonth,
                                            rightDateNotifier.value) ??
                                        AppLocalizations.of(context)!
                                            .compareChart_SelectDate,
                                    style: rightDateNotifier.value == null
                                        ? null
                                        : TextStyle(
                                            color: Colors.black,
                                          ),
                                  ),
                                ),
                              ));
                        })
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<CategoryItem>>(
                stream: db.watchAllCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return const LoadingWidget();
                  }
                  final categoryItems = <int, CategoryItem>{};
                  for (var element in snapshot.data!) {
                    categoryItems.putIfAbsent(element.id, () => element);
                  }
                  return Container(
                    width: double.infinity,
                    child: ValueListenableBuilder(
                        valueListenable: leftDateNotifier,
                        builder: (context, left_date, _) {
                          return ValueListenableBuilder(
                              valueListenable: rightDateNotifier,
                              builder: (context, right_date, _) {
                                if (left_date != null && right_date != null) {
                                  return Row(children: [
                                    Expanded(
                                        child:
                                            _buildCompareColumn(categoryItems)),
                                  ]);
                                }
                                return Container();
                              });
                        }),
                  );
                }),
          )
        ],
      ),
    );
  }

  Map<int, double> aggregateTransactions(List<Transaction> transactions) {
    final Map<int, double> aggregated = {};

    for (var transaction in transactions) {
      if (aggregated.containsKey(transaction.categoryId)) {
        aggregated[transaction.categoryId] =
            aggregated[transaction.categoryId]! + transaction.amount;
      } else {
        aggregated[transaction.categoryId] = transaction.amount;
      }
    }

    return aggregated;
  }

  Widget _buildCompareColumn(Map<int, CategoryItem> categoryItems) {
    return StreamBuilder<List<Transaction>>(
        stream: isLeftMonth
            ? db.getTransactionsByMonth(
                leftDateNotifier.value!.year, leftDateNotifier.value!.month)
            : db.getTransactionsByYear(leftDateNotifier.value!.year),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const LoadingWidget();
          }
          final transactionsLeft = snapshot.data!;
          return StreamBuilder<List<Transaction>>(
              stream: isRightMonth
                  ? db.getTransactionsByMonth(rightDateNotifier.value!.year,
                      rightDateNotifier.value!.month)
                  : db.getTransactionsByYear(rightDateNotifier.value!.year),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return const LoadingWidget();
                }
                final transactionsRight = snapshot.data!;
                if (transactionsRight.isEmpty && transactionsLeft.isEmpty) {
                  return Center(
                      child:
                          Text(AppLocalizations.of(context)!.listView_Empty));
                }
                final aggregatedLeft = aggregateTransactions(transactionsLeft);
                final aggregatedRight =
                    aggregateTransactions(transactionsRight);
                var allCategories = List.from(aggregatedLeft.keys)
                  ..addAll(aggregatedRight.keys);
                allCategories = allCategories.toSet().toList();
                allCategories.sort(((a, b) {
                  if (categoryItems[a]!.type != categoryItems[b]!.type) {
                    if (categoryItems[a]!.type == 'expense') {
                      return -1;
                    } else {
                      return 1;
                    }
                  } else {
                    return categoryItems[a]!.id.compareTo(categoryItems[b]!.id);
                  }
                }));
                final leftMaxAmount = transactionsLeft.isEmpty
                    ? 0
                    : aggregatedLeft.values.reduce(max);
                final leftTotal = transactionsLeft.isEmpty
                    ? 0
                    : aggregatedLeft.values
                        .reduce((value, element) => value + element);
                final rightMaxAmount = transactionsRight.isEmpty
                    ? 0
                    : aggregatedRight.values.reduce(max);
                final rightTotal = transactionsRight.isEmpty
                    ? 0
                    : aggregatedRight.values
                        .reduce((value, element) => value + element);
                return ListView(
                  children: allCategories.map((category) {
                    final costLeft = aggregatedLeft[category] ?? 0.0;
                    final costRight = aggregatedRight[category] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 8.0),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(
                                flex: 2,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ConditionedTransationPage(
                                                  dateTime:
                                                      leftDateNotifier.value!,
                                                  dateRange: isLeftMonth
                                                      ? "month"
                                                      : "year",
                                                  categoryItem: categoryItems[
                                                      category]!)),
                                    );
                                  },
                                  child: CompareItemWidget(
                                    cost: costLeft,
                                    maxAmount: leftMaxAmount,
                                    total: leftTotal,
                                    isLeft: true,
                                  ),
                                )),
                            Flexible(
                              flex: 1,
                              child: Column(
                                children: [
                                  Icon(
                                    categoryItems[category]!.icon,
                                    color: categoryItems[category]!.color,
                                  ),
                                  Text(
                                    categoryItems[category]!
                                        .getDisplayName(context),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 2,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ConditionedTransationPage(
                                                dateTime:
                                                    rightDateNotifier.value!,
                                                dateRange: isRightMonth
                                                    ? "month"
                                                    : "year",
                                                categoryItem:
                                                    categoryItems[category]!)),
                                  );
                                },
                                child: CompareItemWidget(
                                    cost: costRight,
                                    maxAmount: rightMaxAmount,
                                    total: rightTotal,
                                    isLeft: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              });
        });
  }
}

class CompareItemWidget extends StatelessWidget {
  const CompareItemWidget({
    super.key,
    required this.cost,
    required this.maxAmount,
    required this.total,
    required this.isLeft,
  });

  final double cost;
  final num maxAmount;
  final num total;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    var childWidgets = <Widget>[
      Text(
        (cost / (total == 0 ? 1 : total) * 100).toStringAsFixed(2) + "%",
        style: const TextStyle(
            fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
      ),
      Text(
        cost.toStringAsFixed(2),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ];
    if (isLeft) {
      childWidgets = childWidgets.reversed.toList();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: isLeft ? 2 : 0,
          child: LinearProgressIndicator(
            value: cost / (maxAmount == 0 ? 1 : maxAmount),
            backgroundColor: Colors.grey[200],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: childWidgets,
        )
      ],
    );
  }
}
