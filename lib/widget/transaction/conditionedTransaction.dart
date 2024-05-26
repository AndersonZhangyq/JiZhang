import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:intl/intl.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:ji_zhang/widget/transaction/transactionList.dart';
import 'package:provider/provider.dart';
import "package:collection/collection.dart";
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

class ConditionedTransationPage extends StatefulWidget {
  ConditionedTransationPage(
      {Key? key,
      required this.dateTime,
      required this.dateRange,
      required this.categoryItem})
      : super(key: key);
  final DateTime dateTime;
  final String dateRange;
  final CategoryItem categoryItem;

  @override
  _ConditionedTransationPageState createState() =>
      _ConditionedTransationPageState();
}

class _ConditionedTransationPageState extends State<ConditionedTransationPage> {
  late MyDatabase db;
  late charts.TrackballBehavior _trackballBehavior;
  ValueNotifier<List<bool>> isSelectedOrderTypeNotifier =
      ValueNotifier([true, false]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    _trackballBehavior = charts.TrackballBehavior(
        // Enables the trackball
        enable: true,
        tooltipSettings: charts.InteractiveTooltip(
            // Formatting trackball tooltip text
            format: widget.dateTime.year.toString() + '-point.x : point.y'),
        activationMode: charts.ActivationMode.singleTap);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          (widget.dateRange == "month"
                  ? widget.dateTime.format('yyyy-MM')
                  : widget.dateTime.format('yyyy')) +
              "   ${widget.categoryItem.getDisplayName(context)}${widget.categoryItem.type == 'expense' ? AppLocalizations.of(context)!.tab_Expense : AppLocalizations.of(context)!.tab_Income}",
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
      body: Center(
        child: StreamBuilder<Map<int, CategoryItem>>(
            stream:
                db.watchAllCategories()!.map<Map<int, CategoryItem>>((value) {
              Map<int, CategoryItem> ret = {};
              for (final item in value) {
                ret[item.id] = item;
              }
              return ret;
            }),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? {};
              return StreamBuilder<List<Transaction>>(
                  stream: widget.dateRange == "month"
                      ? db.getTransactionsByMonthAndCategoryId(
                          widget.dateTime.year,
                          widget.dateTime.month,
                          widget.categoryItem.id)
                      : db.getTransactionsByYearAndCategoryId(
                          widget.dateTime.year, widget.categoryItem.id),
                  builder: (context, snapshot) {
                    final transactions = snapshot.data ?? [];
                    final seriesData = <DateTime, double>{};
                    if (widget.dateRange == "year") {
                      // initialize seriesData with 0.0
                      for (var i = 12; i >= 1; i--) {
                        seriesData[DateTime(widget.dateTime.year, i)] = 0.0;
                      }
                      var groupedTransactions = groupBy(
                          transactions, (Transaction t) => t.date.month);

                      for (var month in groupedTransactions.keys
                          .sorted((a, b) => -a.compareTo(b))) {
                        var total = 0.0;
                        for (var transaction
                            in (groupedTransactions[month] ?? [])) {
                          total += transaction.amount;
                        }
                        seriesData[DateTime(widget.dateTime.year, month)] =
                            total;
                      }
                    }
                    return Column(children: [
                      widget.dateRange == 'year'
                          ? SizedBox(
                              height: 200,
                              child: charts.SfCartesianChart(
                                  margin: const EdgeInsets.all(10),
                                  primaryYAxis: charts.NumericAxis(
                                      isVisible: false,
                                      majorGridLines:
                                          const charts.MajorGridLines(
                                              width: 0)),
                                  primaryXAxis: charts.DateTimeAxis(
                                    plotOffset: 15,
                                    interval: 1,
                                    labelAlignment:
                                        charts.LabelAlignment.center,
                                    majorGridLines:
                                        const charts.MajorGridLines(width: 0),
                                    dateFormat: DateFormat('MM'),
                                  ),
                                  trackballBehavior: _trackballBehavior,
                                  series: <charts.CartesianSeries>[
                                    charts.LineSeries<
                                            MapEntry<DateTime, double>,
                                            DateTime>(
                                        dataSource: seriesData.entries.toList(),
                                        xValueMapper: (row, _) => row.key,
                                        yValueMapper: (row, _) => row.value,
                                        markerSettings: charts.MarkerSettings(
                                            isVisible: true),
                                        pointColorMapper: (row, _) {
                                          return Colors.blue.withOpacity(0.3);
                                        }),
                                  ]),
                            )
                          : Container(),
                      ValueListenableBuilder<List<bool>>(
                          valueListenable: isSelectedOrderTypeNotifier,
                          builder: (context, isSelectedOrderType, _) {
                            return ToggleButtons(
                              constraints: const BoxConstraints(
                                maxHeight: 30,
                              ),
                              textStyle: const TextStyle(fontSize: 14),
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0, vertical: 6.0),
                                  child: Text(
                                      AppLocalizations.of(context)!.tab_ByDate),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0, vertical: 6.0),
                                  child: Text(AppLocalizations.of(context)!
                                      .tab_ByAmount),
                                )
                              ],
                              onPressed: (index) {
                                isSelectedOrderTypeNotifier.value[index] = true;
                                isSelectedOrderTypeNotifier.value[1 - index] =
                                    false;
                                isSelectedOrderTypeNotifier.notifyListeners();
                              },
                              isSelected: isSelectedOrderType,
                            );
                          }),
                      ValueListenableBuilder<List<bool>>(
                          valueListenable: isSelectedOrderTypeNotifier,
                          builder: (context, isSelectedOrderType, _) {
                            return TransactionListWidget(
                                context: context,
                                db: db,
                                transactions: transactions,
                                categories: categories,
                                isByDate: isSelectedOrderType[0]);
                          }),
                    ]);
                  });
            }),
      ),
    );
  }
}
