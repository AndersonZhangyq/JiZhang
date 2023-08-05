import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/swip_detector.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/loading.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:ji_zhang/widget/transaction/transactionList.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';

class TransactionWidget extends StatefulWidget {
  const TransactionWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionWidget> {
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateTime.now().month.toString();
  late MyDatabase db;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, CategoryItem>>(
        stream: db.watchAllCategories()!.map<Map<int, CategoryItem>>((value) {
          Map<int, CategoryItem> ret = {};
          for (final item in value) {
            ret[item.id] = item;
          }
          return ret;
        }),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? {};
          return StreamBuilder<List<Transaction>>(
              stream: db.getTransactionsByMonth(
                  int.parse(selectedYear), int.parse(selectedMonth)),
              builder: (context, snapshot) {
                if (snapshot.hasData == false) {
                  return const Expanded(
                    child: LoadingWidget(),
                  );
                }
                List<Transaction> transactions =
                    snapshot.data ?? <Transaction>[];
                return Expanded(
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildTopBar(transactions, categories),
                        TransactionListWidget(
                            context: context,
                            db: db,
                            transactions: transactions,
                            categories: categories),
                      ],
                    ),
                  ),
                );
              });
        });
  }

  Widget _buildTopBar(
      List<Transaction> transactions, Map<int, CategoryItem> categories) {
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    for (var element in transactions) {
      if (categories[element.categoryId]!.type == "income") {
        totalIncome += element.amount;
      } else {
        totalExpense += element.amount;
      }
    }
    return SwipeDetector(
      onSwipeLeft: () {
        setState(() {
          selectedMonth = (int.parse(selectedMonth) - 1).toString();
          if (int.parse(selectedMonth) < 1) {
            selectedMonth = "12";
            selectedYear = (int.parse(selectedYear) - 1).toString();
          }
        });
      },
      onSwipeRight: () {
        setState(() {
          selectedMonth = (int.parse(selectedMonth) + 1).toString();
          if (int.parse(selectedMonth) > 12) {
            selectedMonth = "1";
            selectedYear = (int.parse(selectedYear) + 1).toString();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 18.0, 24.0, 12.0),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    showMonthPicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(3000),
                      initialDate: DateTime(
                          int.parse(selectedYear), int.parse(selectedMonth)),
                    ).then((date) {
                      if (date != null) {
                        setState(() {
                          selectedYear = date.year.toString();
                          selectedMonth = date.month.toString();
                        });
                      }
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        selectedYear + " 年",
                        style: const TextStyle(fontWeight: FontWeight.w300),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              flex: 2,
                              child: Text(
                                selectedMonth.padLeft(2, '0'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 24),
                              ),
                            ),
                            const Flexible(
                              flex: 1,
                              child: Text(" 月",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12)),
                            ),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.black)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: VerticalDivider(
                  width: 1,
                  indent: 6,
                  endIndent: 6,
                  thickness: 1,
                  color: Colors.grey[400],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.tab_Expense,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w300)),
                          Text(totalExpense.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal, fontSize: 18))
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context)!.tab_Income,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w300)),
                          Text(totalIncome.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal, fontSize: 18))
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
