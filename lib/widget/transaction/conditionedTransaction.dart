import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:ji_zhang/widget/transaction/transactionList.dart';
import 'package:provider/provider.dart';

class ConditionedTransationPage extends StatefulWidget {
  const ConditionedTransationPage(
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.dateRange == "month"
              ? widget.dateTime.format('yyyy-MM')
              : widget.dateTime.format('yyyy') +
                  "${widget.categoryItem.getDisplayName(context)}${widget.categoryItem.type == 'expense' ? AppLocalizations.of(context)!.tab_Expense : AppLocalizations.of(context)!.tab_Income}",
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            StreamBuilder<Map<int, CategoryItem>>(
                stream: db
                    .watchAllCategories()!
                    .map<Map<int, CategoryItem>>((value) {
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
                        return TransactionListWidget(
                            context: context,
                            db: db,
                            transactions: transactions,
                            categories: categories);
                      });
                }),
          ],
        ),
      ),
    );
  }
}
