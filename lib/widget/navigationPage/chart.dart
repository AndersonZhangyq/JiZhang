// import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/transaction/conditionedTransaction.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;

class ChartWidget extends StatefulWidget {
  const ChartWidget({Key? key}) : super(key: key);

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  late MyDatabase db;
  DateTime selectedDate = DateTime.now();
  String categoryType = "expense";
  List<bool> isSelected = [true, false];

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SafeArea(
            child: StreamBuilder<DateTimeRange>(
                stream: db.getTransactionRange(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        "Loading...",
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  final dateRange = snapshot.data!;
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context, dateRange),
                        Expanded(
                          child: StreamBuilder<List<CategoryItem>>(
                              stream: db.watchCategoriesByType(categoryType),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Center(
                                      child: Text(
                                    "Loading...",
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ));
                                }
                                final categoryItems = <int, CategoryItem>{};
                                for (var element in snapshot.data!) {
                                  categoryItems.putIfAbsent(
                                      element.id, () => element);
                                }
                                return StreamBuilder<List<Transaction>>(
                                    stream: db.getTransactionsByMonth(
                                        selectedDate.year, selectedDate.month),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Center(
                                            child: Text(
                                          "Loading...",
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ));
                                      }
                                      final transactions = snapshot.data!;
                                      transactions.removeWhere((element) =>
                                          !categoryItems
                                              .containsKey(element.categoryId));
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children:
                                                    _buildTotal(transactions),
                                              ),
                                              Expanded(
                                                  child: Column(
                                                children: _buildPieAndList(
                                                    transactions,
                                                    categoryItems),
                                              ))
                                            ]),
                                      );
                                    });
                              }),
                        )
                      ]);
                })));
  }

  Widget _buildTopBar(BuildContext context, DateTimeRange snapshot) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showMonthPicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: snapshot.start,
                          lastDate: snapshot.end)
                      .then((value) {
                    if (value != null) {
                      setState(() {
                        selectedDate = value;
                      });
                    }
                  });
                },
                child: Row(
                  children: [
                    Text(
                      selectedDate.format('yyyy-MM'),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.date_range,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                  ],
                )),
            const Spacer(),
            ToggleButtons(
              constraints: const BoxConstraints(
                maxHeight: 30,
              ),
              textStyle: const TextStyle(fontSize: 14),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 6.0),
                  child: Text(AppLocalizations.of(context)!.tab_Expense),
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
                  isSelected[index] = true;
                  isSelected[1 - index] = false;
                });
              },
              isSelected: isSelected,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTotal(
    List<Transaction> transactions,
  ) {
    double total = 0.0;
    for (var element in transactions) {
      total += element.amount;
    }
    return [
      categoryType == 'expense'
          ? Text(AppLocalizations.of(context)!.chart_Title_TotalExpense)
          : Text(AppLocalizations.of(context)!.chart_Title_TotalIncome),
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Text(
          total.toStringAsFixed(2),
          style: const TextStyle(fontSize: 28),
        ),
      )
    ];
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
    return [
      SizedBox(
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
      ),
      Expanded(
        child: ListView.builder(
            itemCount: sortedAmountPerCategory.length,
            itemBuilder: (context, index) {
              var entry = sortedAmountPerCategory[index];
              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConditionedTransationPage(
                            dateTime: selectedDate,
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
              );
            }),
      )
    ];
  }
}
