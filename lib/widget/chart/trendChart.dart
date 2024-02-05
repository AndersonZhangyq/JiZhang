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
  DateTime selectedDate = DateTime.now().getDateTillMonth();
  String categoryType = "expense";
  String dateRange = "month";
  late Map<DateTime, double> seriesData;
  List<bool> isSelectedCategoryType = [true, false];
  List<bool> isSelectedDateRange = [true, false];
  final ItemScrollController _scrollController = ItemScrollController();
  final _tooltipBehavior = charts.TooltipBehavior(enable: true, header: '');
  final _zoomPanBehavior = charts.ZoomPanBehavior(
    enableSelectionZooming: false,
    enablePinching: false,
    zoomMode: charts.ZoomMode.x,
    enablePanning: true,
  );
  final _selectionBehavior = charts.SelectionBehavior(
      enable: true, unselectedOpacity: 0.4, selectedOpacity: 1.0);
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTimeRange>(
        stream: db.getTransactionRange(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingWidget();
          }
          final transactionRange = snapshot.data!;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(context, transactionRange),
                Expanded(
                  child: StreamBuilder<List<CategoryItem>>(
                      stream: db.watchCategoriesByType(categoryType),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LoadingWidget();
                        }
                        final categoryItems = <int, CategoryItem>{};
                        for (var element in snapshot.data!) {
                          categoryItems.putIfAbsent(element.id, () => element);
                        }
                        return StreamBuilder<List<Transaction>>(
                            stream: this.dateRange == "month"
                                ? db.getTransactionsByMonth(
                                    selectedDate.year, selectedDate.month)
                                : db.getTransactionsByYear(selectedDate.year),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
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
                      }),
                )
              ]);
        });
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: StreamBuilder<Map<DateTime, double>>(
        stream: this.dateRange == "month"
            ? db.getMonthlySum(categoryType)
            : db.getYearlySum(categoryType),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingWidget();
          }
          seriesData = snapshot.data!;
          int initialSelectedIndex = seriesData.keys.toList().indexOf(
              this.dateRange == 'year'
                  ? DateTime.now().getDateTillYear()
                  : DateTime.now().getDateTillMonth());
          return charts.SfCartesianChart(
              onSelectionChanged: (selectionArgs) {
                final selectedTime = seriesData.keys
                    .toList()
                    .elementAt(selectionArgs.pointIndex);
                print(selectedTime);
                setState(() {
                  selectedDate = selectedTime;
                });
              },
              primaryYAxis: charts.NumericAxis(isVisible: false),
              primaryXAxis: charts.DateTimeAxis(
                // isInversed: true,
                visibleMinimum: this.dateRange == 'year'
                    ? selectedDate.copyWith(year: selectedDate.year - 2)
                    : selectedDate.copyWith(month: selectedDate.month - 6),
                visibleMaximum: this.dateRange == 'year'
                    ? selectedDate.copyWith(year: selectedDate.year + 2)
                    : selectedDate.copyWith(month: selectedDate.month + 5),
                // X axis labels will be rendered based on the below format
                dateFormat: this.dateRange == 'year'
                    ? DateFormat('yyyy')
                    : DateFormat('yy-MM'),
              ),
              tooltipBehavior: _tooltipBehavior,
              zoomPanBehavior: _zoomPanBehavior,
              series: <charts.ColumnSeries>[
                charts.ColumnSeries<MapEntry<DateTime, double>, DateTime>(
                    dataSource: seriesData.entries.toList(),
                    xValueMapper: (row, _) => row.key,
                    yValueMapper: (row, _) => row.value,
                    color: Colors.green,
                    // Width of the columns
                    // width: 0.5,
                    // Spacing between the columns
                    // spacing: 0.2,
                    initialSelectedDataIndexes: [initialSelectedIndex],
                    selectionBehavior: _selectionBehavior,
                    dataLabelSettings: const charts.DataLabelSettings(
                        labelAlignment: charts.ChartDataLabelAlignment.outer,
                        isVisible: true))
              ]);
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, DateTimeRange snapshot) {
    final List<DateTime> dateList = [];
    // add date to the dateList in reverse order
    switch (dateRange) {
      case "month":
        DateTime cur = snapshot.end.getDateTillMonth();
        DateTime start = DateTime(snapshot.start.year, snapshot.start.month - 1)
            .getDateTillMonth();
        while (cur.isAfter(start)) {
          dateList.add(cur);
          cur = DateTime(cur.year, cur.month - 1);
        }
        break;
      case "year":
        DateTime cur = snapshot.end.getDateTillYear();
        DateTime start = DateTime(snapshot.start.year - 1).getDateTillYear();
        while (cur.isAfter(start)) {
          dateList.add(cur);
          cur = DateTime(cur.year - 1);
        }
        break;
    }
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
                    ToggleButtons(
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
                        setState(() {
                          dateRange = index == 0 ? "month" : "year";
                          isSelectedDateRange[index] = true;
                          isSelectedDateRange[1 - index] = false;
                        });
                      },
                      isSelected: isSelectedDateRange,
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ToggleButtons(
                      constraints: const BoxConstraints(
                        maxHeight: 30,
                      ),
                      textStyle: const TextStyle(fontSize: 14),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 6.0),
                          child:
                              Text(AppLocalizations.of(context)!.tab_Expense),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18.0, vertical: 6.0),
                          child: Text(AppLocalizations.of(context)!.tab_Income),
                        )
                      ],
                      onPressed: (index) {
                        setState(() {
                          categoryType = index == 0 ? "expense" : "income";
                          isSelectedCategoryType[index] = true;
                          isSelectedCategoryType[1 - index] = false;
                        });
                      },
                      isSelected: isSelectedCategoryType,
                    ),
                  ],
                ),
              ],
            ),
            // SizedBox(
            //   height: 40,
            //   child: ScrollablePositionedList.builder(
            //       itemScrollController: _scrollController,
            //       scrollDirection: Axis.horizontal,
            //       itemCount: dateList.length,
            //       itemBuilder: (BuildContext context, int index) {
            //         return SizedBox(
            //           height: double.infinity,
            //           width: 110,
            //           child: ListTile(
            //               contentPadding:
            //                   const EdgeInsets.symmetric(horizontal: 8.0),
            //               onTap: () => {
            //                     setState(() {
            //                       selectedDate = dateList[index];
            //                       _scrollController.scrollTo(
            //                           index: max(index - 1, 0),
            //                           duration:
            //                               const Duration(milliseconds: 500),
            //                           curve: Curves.easeInOut);
            //                       _selectionBehavior.selectDataPoints(index);
            //                     })
            //                   },
            //               title: Row(
            //                 mainAxisAlignment: MainAxisAlignment.center,
            //                 children: [
            //                   Text(
            //                     dateList[index].format(
            //                         dateRange == "month" ? "yyyy-MM" : "yyyy"),
            //                     style: (selectedDate == dateList[index]) ||
            //                             (dateRange == "year" &&
            //                                 selectedDate.year ==
            //                                     dateList[index].year)
            //                         ? const TextStyle(
            //                             color: Colors.green,
            //                             fontWeight: FontWeight.bold,
            //                             fontSize: 18,
            //                           )
            //                         : null,
            //                   ),
            //                 ],
            //               )),
            //         );
            //       }),
            // ),
          ],
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        categoryType == 'expense'
            ? Text((dateRange == 'year'
                    ? selectedDate.format("yyyy")
                    : selectedDate.format("yyyy-MM")) +
                " " +
                AppLocalizations.of(context)!.chart_Title_TotalExpense)
            : Text((dateRange == 'year'
                    ? selectedDate.format("yyyy")
                    : selectedDate.format("yyyy-MM")) +
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
        Expanded(
          child: Center(
              child: Text(AppLocalizations.of(context)!.listView_Empty,
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold))),
        )
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
                    dateTime: selectedDate,
                    dateRange: dateRange,
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
