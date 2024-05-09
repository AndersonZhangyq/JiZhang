import 'dart:core';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/loading.dart';
import 'package:ji_zhang/widget/transaction/conditionedTransaction.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

class TrendChartWidget extends StatefulWidget {
  const TrendChartWidget({Key? key}) : super(key: key);

  @override
  _TrendChartWidgetState createState() => _TrendChartWidgetState();
}

class _TrendChartWidgetState extends State<TrendChartWidget> {
  late MyDatabase db;
  ValueNotifier<String> dateRangeNotifier = ValueNotifier<String>("month");
  ValueNotifier<String> categoryTypeNotifier = ValueNotifier<String>("expense");
  ValueNotifier<DateTime> selectedDateNotifier =
      ValueNotifier<DateTime>(DateTime.now().getDateTillMonth());
  ValueNotifier<List<bool>> isSelectedCategoryTypeNotifier =
      ValueNotifier<List<bool>>([true, false]);
  ValueNotifier<List<bool>> isSelectedDateRangeNotifier =
      ValueNotifier<List<bool>>([true, false]);
  Map<DateTime, double> seriesData = {};
  final ItemScrollController _scrollController = ItemScrollController();
  final _trackballBehavior = charts.TrackballBehavior(
      // Enables the trackball
      enable: true,
      activationMode: charts.ActivationMode.singleTap);
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildTopBar(context),
      Expanded(
        child: ValueListenableBuilder(
            valueListenable: categoryTypeNotifier,
            builder: (context, value, _) {
              return ValueListenableBuilder(
                valueListenable: selectedDateNotifier,
                builder: (context, value, _) {
                  return StreamBuilder<List<CategoryItem>>(
                      stream:
                          db.watchCategoriesByType(categoryTypeNotifier.value),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            !snapshot.hasData) {
                          return const LoadingWidget();
                        }
                        final categoryItems = <int, CategoryItem>{};
                        for (var element in snapshot.data!) {
                          categoryItems.putIfAbsent(element.id, () => element);
                        }
                        return StreamBuilder<List<Transaction>>(
                            stream: dateRangeNotifier.value == "month"
                                ? db.getTransactionsByMonth(
                                    selectedDateNotifier.value.year,
                                    selectedDateNotifier.value.month)
                                : db.getTransactionsByYear(
                                    selectedDateNotifier.value.year),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  !snapshot.hasData) {
                                return const LoadingWidget();
                              }
                              final transactions = snapshot.data!;
                              transactions.removeWhere((element) =>
                                  !categoryItems
                                      .containsKey(element.categoryId));
                              var columnChildren = <Widget>[];
                              columnChildren.add(_buildBarChart());
                              columnChildren.add(_buildTotal(transactions));
                              columnChildren.addAll(_buildPieAndList(
                                  transactions, categoryItems));
                              return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: ScrollConfiguration(
                                    behavior: const ScrollBehavior()
                                        .copyWith(overscroll: false),
                                    child: SingleChildScrollView(
                                      child: Column(children: columnChildren),
                                    ),
                                  ));
                            });
                      });
                },
              );
            }),
      )
    ]);
  }

  Widget _buildTopBar(BuildContext context) {
    return StreamBuilder<DateTimeRange>(
        stream: db.getTransactionRange(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const LoadingWidget();
          }
          final transactionRange = snapshot.data!;
          return SizedBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                              valueListenable: isSelectedDateRangeNotifier,
                              builder: (context, isSelectedDateRange, _) {
                                return ToggleButtons(
                                  constraints: const BoxConstraints(
                                    maxHeight: 30,
                                  ),
                                  textStyle: const TextStyle(fontSize: 14),
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18.0, vertical: 6.0),
                                      child: Text(AppLocalizations.of(context)!
                                          .chart_Top_DataRange_Month),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18.0, vertical: 6.0),
                                      child: Text(AppLocalizations.of(context)!
                                          .chart_Top_DataRange_Year),
                                    )
                                  ],
                                  onPressed: (index) {
                                    dateRangeNotifier.value =
                                        index == 0 ? "month" : "year";
                                    if (dateRangeNotifier.value == "year") {
                                      selectedDateNotifier.value =
                                          DateTime.now().getDateTillYear();
                                    } else {
                                      selectedDateNotifier.value =
                                          DateTime.now().getDateTillMonth();
                                    }
                                    isSelectedDateRangeNotifier.value[index] =
                                        true;
                                    isSelectedDateRangeNotifier
                                        .value[1 - index] = false;
                                    isSelectedDateRangeNotifier
                                        .notifyListeners();
                                  },
                                  isSelected: isSelectedDateRange,
                                );
                              }),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                              valueListenable: isSelectedCategoryTypeNotifier,
                              builder: (context, isSelectedCategoryType, _) {
                                return ToggleButtons(
                                  constraints: const BoxConstraints(
                                    maxHeight: 30,
                                  ),
                                  textStyle: const TextStyle(fontSize: 14),
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18.0, vertical: 6.0),
                                      child: Text(AppLocalizations.of(context)!
                                          .tab_Expense),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18.0, vertical: 6.0),
                                      child: Text(AppLocalizations.of(context)!
                                          .tab_Income),
                                    )
                                  ],
                                  onPressed: (index) {
                                    categoryTypeNotifier.value =
                                        index == 0 ? "expense" : "income";
                                    isSelectedCategoryTypeNotifier
                                        .value[index] = true;
                                    isSelectedCategoryTypeNotifier
                                        .value[1 - index] = false;
                                    isSelectedCategoryTypeNotifier
                                        .notifyListeners();
                                  },
                                  isSelected: isSelectedCategoryType,
                                );
                              }),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                    child: ValueListenableBuilder(
                        valueListenable: dateRangeNotifier,
                        builder: (context, value, _) {
                          final List<DateTime> dateList = [];
                          // add date to the dateList in reverse order
                          switch (dateRangeNotifier.value) {
                            case "month":
                              DateTime cur =
                                  transactionRange.end.getDateTillMonth();
                              DateTime start = DateTime(
                                      transactionRange.start.year,
                                      transactionRange.start.month - 1)
                                  .getDateTillMonth();
                              while (cur.isAfter(start)) {
                                dateList.add(cur);
                                cur = DateTime(cur.year, cur.month - 1);
                              }
                              break;
                            case "year":
                              DateTime cur =
                                  transactionRange.end.getDateTillYear();
                              DateTime start =
                                  DateTime(transactionRange.start.year - 1)
                                      .getDateTillYear();
                              while (cur.isAfter(start)) {
                                dateList.add(cur);
                                cur = DateTime(cur.year - 1);
                              }
                              break;
                          }
                          if (selectedDateNotifier.value
                              .isBefore(transactionRange.start)) {
                            if (dateRangeNotifier.value == "month") {
                              selectedDateNotifier.value =
                                  transactionRange.start.getDateTillMonth();
                            } else {
                              selectedDateNotifier.value =
                                  transactionRange.start.getDateTillYear();
                            }
                          } else if (selectedDateNotifier.value
                              .isAfter(transactionRange.end)) {
                            if (dateRangeNotifier.value == "month") {
                              selectedDateNotifier.value =
                                  transactionRange.end.getDateTillMonth();
                            } else {
                              selectedDateNotifier.value =
                                  transactionRange.end.getDateTillYear();
                            }
                          }
                          return ScrollablePositionedList.builder(
                              itemScrollController: _scrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: dateList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return SizedBox(
                                  height: double.infinity,
                                  width: 100,
                                  child: InkWell(
                                      // contentPadding:
                                      //     const EdgeInsets.symmetric(horizontal: 8.0),
                                      onTap: () {
                                        _scrollController.scrollTo(
                                            index: max(index - 1, 0),
                                            duration: const Duration(
                                                milliseconds: 500),
                                            curve: Curves.easeInOut);
                                        selectedDateNotifier.value =
                                            dateList[index];
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ValueListenableBuilder(
                                            valueListenable:
                                                selectedDateNotifier,
                                            builder: (context, value, _) {
                                              return Text(
                                                dateList[index].format(
                                                    dateRangeNotifier.value ==
                                                            "month"
                                                        ? "yyyy-MM"
                                                        : "yyyy"),
                                                style: (selectedDateNotifier
                                                                .value ==
                                                            dateList[index]) ||
                                                        (dateRangeNotifier
                                                                    .value ==
                                                                "year" &&
                                                            selectedDateNotifier
                                                                    .value
                                                                    .year ==
                                                                dateList[index]
                                                                    .year)
                                                    ? const TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      )
                                                    : null,
                                              );
                                            },
                                          ),
                                        ],
                                      )),
                                );
                              });
                        }),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: StreamBuilder<Map<DateTime, double>>(
        stream: dateRangeNotifier.value == "month"
            ? db.getMonthlySum(categoryTypeNotifier.value)
            : db.getYearlySum(categoryTypeNotifier.value),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return Container();
          }
          final range = snapshot.data!.keys.toList();
          range.sort();
          seriesData.clear();
          if (dateRangeNotifier.value == 'year') {
            var iterDatetime = range.last;
            if (selectedDateNotifier.value
                    .copyWith(year: selectedDateNotifier.value.year + 2)
                    .compareTo(range.last) <=
                0) {
              iterDatetime = selectedDateNotifier.value
                  .copyWith(year: selectedDateNotifier.value.year + 2);
            }
            while (iterDatetime.compareTo(range.first) >= 0) {
              seriesData[iterDatetime] = snapshot.data![iterDatetime] ?? 0.0;
              iterDatetime = iterDatetime.copyWith(year: iterDatetime.year - 1);
              if (seriesData.length >= 5) {
                break;
              }
            }
          } else {
            var iterDatetime = range.last;
            if (selectedDateNotifier.value
                    .copyWith(month: selectedDateNotifier.value.month + 6)
                    .compareTo(range.last) <=
                0) {
              iterDatetime = selectedDateNotifier.value
                  .copyWith(month: selectedDateNotifier.value.month + 6);
            }
            while (iterDatetime.compareTo(range.first) >= 0) {
              seriesData[iterDatetime] = snapshot.data![iterDatetime] ?? 0.0;
              iterDatetime =
                  iterDatetime.copyWith(month: iterDatetime.month - 1);
              if (seriesData.length >= 12) {
                break;
              }
            }
          }
          int initialSelectedIndex = seriesData.keys.toList().indexOf(
              dateRangeNotifier.value == 'year'
                  ? DateTime.now().getDateTillYear()
                  : DateTime.now().getDateTillMonth());
          return charts.SfCartesianChart(
              margin: const EdgeInsets.all(10),
              onSelectionChanged: (selectionArgs) {
                final selectedTime = seriesData.keys
                    .toList()
                    .elementAt(selectionArgs.pointIndex);
                print(selectedTime);
                selectedDateNotifier.value = selectedTime;
              },
              primaryYAxis: charts.NumericAxis(
                  isVisible: false,
                  majorGridLines: const charts.MajorGridLines(width: 0)),
              primaryXAxis: charts.DateTimeAxis(
                labelAlignment: charts.LabelAlignment.end,
                majorGridLines: const charts.MajorGridLines(width: 0),
                dateFormat: dateRangeNotifier.value == 'year'
                    ? DateFormat('yyyy')
                    : DateFormat('yy-MM'),
              ),
              trackballBehavior: _trackballBehavior,
              series: <charts.ColumnSeries>[
                charts.ColumnSeries<MapEntry<DateTime, double>, DateTime>(
                  dataSource: seriesData.entries.toList(),
                  xValueMapper: (row, _) => row.key,
                  yValueMapper: (row, _) => row.value,
                  pointColorMapper: (row, _) {
                    if (dateRangeNotifier.value == 'year' &&
                        row.key.year == selectedDateNotifier.value.year) {
                      return Colors.redAccent;
                    }
                    if (row.key ==
                        selectedDateNotifier.value.getDateTillMonth()) {
                      return Colors.redAccent;
                    }
                    return Colors.green.withOpacity(0.3);
                  },
                  // color: Colors.greenAccent,
                  // Width of the columns
                  // width: 0.5,
                  // Spacing between the columns
                  // spacing: 0.2,
                )
              ]);
        },
      ),
    );
  }

  Widget _buildTotal(
    List<Transaction> transactions,
  ) {
    double total = 0.0;
    for (var element in transactions) {
      total += element.amount;
    }
    if (total == 0.0) {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        categoryTypeNotifier.value == 'expense'
            ? Text((dateRangeNotifier.value == 'year'
                    ? selectedDateNotifier.value.format("yyyy")
                    : selectedDateNotifier.value.format("yyyy-MM")) +
                " " +
                AppLocalizations.of(context)!.chart_Title_TotalExpense)
            : Text((dateRangeNotifier.value == 'year'
                    ? selectedDateNotifier.value.format("yyyy")
                    : selectedDateNotifier.value.format("yyyy-MM")) +
                " " +
                AppLocalizations.of(context)!.chart_Title_TotalIncome),
        Text(
          total.toStringAsFixed(2),
          style: const TextStyle(fontSize: 24),
        ),
      ],
    );
  }

  List<Widget> _buildPieAndList(
      List<Transaction> transactions, Map<int, CategoryItem> categoryItems) {
    if (transactions.isEmpty) {
      return [
        Center(
            child: Text(AppLocalizations.of(context)!.listView_Empty,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.bold)))
      ];
    }
    var amountPerCategory = <int, double>{};
    double total = 0.0;
    for (var element in transactions) {
      amountPerCategory[element.categoryId] =
          (amountPerCategory[element.categoryId] ?? 0) + element.amount;
      total += element.amount;
    }
    var sortedAmountPerCategory = amountPerCategory.entries.toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    var maxAmount = sortedAmountPerCategory[0].value;
    var widgetList = <Widget>[];
    widgetList.add(SizedBox(
      width: double.infinity,
      child: AspectRatio(
          aspectRatio: 16 / 9,
          child: charts.SfCircularChart(series: <charts.CircularSeries>[
            charts.PieSeries<MapEntry<int, double>, String>(
                animationDuration: 500,
                dataSource: sortedAmountPerCategory,
                xValueMapper: (row, _) => row.key.toString(),
                yValueMapper: (row, _) => row.value,
                dataLabelMapper: (row, _) =>
                    '${categoryItems[row.key]?.getDisplayName(context)}',
                dataLabelSettings: const charts.DataLabelSettings(
                  isVisible: true,
                  labelPosition: charts.ChartDataLabelPosition.outside,
                ))
          ])),
    ));
    widgetList.addAll(_buildCumulatedTransactionList(
        sortedAmountPerCategory, categoryItems, maxAmount, total));
    return widgetList;
  }

  List<Widget> _buildCumulatedTransactionList(
      List<MapEntry<int, double>> sortedAmountPerCategory,
      Map<int, CategoryItem> categoryItems,
      double maxAmount,
      double total) {
    var accumulatedTransactionList = <Widget>[];
    for (var entry in sortedAmountPerCategory) {
      accumulatedTransactionList.add(ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ConditionedTransationPage(
                    dateTime: selectedDateNotifier.value,
                    dateRange: dateRangeNotifier.value,
                    categoryItem: categoryItems[entry.key]!)),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        style: ListTileStyle.drawer,
        title: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(categoryItems[entry.key] == null
                ? ""
                : categoryItems[entry.key]!.getDisplayName(context)),
            Text(
              entry.value.toStringAsFixed(2),
              textAlign: TextAlign.end,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: entry.value / maxAmount,
              backgroundColor: Colors.grey[200],
            ),
            Text(
              (entry.value / total * 100).toStringAsFixed(1) + "%",
              style: const TextStyle(fontSize: 12),
            )
          ],
        ),
        leading: Icon(
          categoryItems[entry.key]!.icon,
          color: categoryItems[entry.key]!.color,
        ),
        trailing: const Icon(Icons.chevron_right),
      ));
    }
    return accumulatedTransactionList;
  }
}
