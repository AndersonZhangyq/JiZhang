import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:ji_zhang/common/datetime_extension.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/models/transactionList.dart';
import 'package:ji_zhang/widget/categorySelector.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';

class TransactionsWidget extends StatelessWidget {
  const TransactionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const TransactionListWidget();
  }
}

class TransactionListWidget extends StatefulWidget {
  const TransactionListWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TransactionListState();
}

class ListItem {
  late String type;
  late Object item;
}

class _TransactionListState extends State<TransactionListWidget> {
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateTime.now().month.toString();

  @override
  Widget build(BuildContext context) {
    final Map<num, CategoryItem> categories =
        Provider.of<CategoryList>(context, listen: false).itemsMap;
    final List<Transaction> transactions =
        context.watch<TransactionList>().items;
    var groupedTransaction = groupBy(transactions, (Transaction t) => t.date);
    List<ListItem> listItems = [];
    double totalIncome = 0;
    double totalExpense = 0;
    groupedTransaction.keys.sorted((a, b) => -a.compareTo(b)).forEach((date) {
      List<Transaction> transactions = groupedTransaction[date]!;
      double income = 0.0, expense = 0.0;
      List<ListItem> tmpTrans = [];
      for (var transaction in transactions) {
        switch (categories[transaction.categoryId]!.type) {
          case "expense":
            expense += transaction.money;
            break;
          case "income":
            income += transaction.money;
            break;
          default:
        }
        tmpTrans.add(ListItem()
          ..type = "transaction"
          ..item = transaction);
      }
      listItems.add(ListItem()
        ..type = "date"
        ..item = {"date": date, "total": income - expense});
      listItems.addAll(tmpTrans);
      totalIncome += income;
      totalExpense += expense;
    });
    return Expanded(
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(totalIncome, totalExpense),
            _buildTransactionList(listItems, categories),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(double totalIncome, double totalExpense) {
    return Padding(
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
                        DatabaseHelper.instance
                            .getTransactionsByMonth(date.year, date.month)
                            .then((transactions) {
                          Provider.of<TransactionList>(context, listen: false)
                              .removeAll();
                          Provider.of<TransactionList>(context, listen: false)
                              .setYearMonth(date.month, date.month);
                          Provider.of<TransactionList>(context, listen: false)
                              .addAll(transactions);
                        });
                      });
                    }
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    fontWeight: FontWeight.w300, fontSize: 12)),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.black)
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
                        const Text("Expense",
                            style: TextStyle(fontWeight: FontWeight.w300)),
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
                        const Text("Income",
                            style: TextStyle(fontWeight: FontWeight.w300)),
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
    );
  }

  Widget _buildTransactionList(
      List<ListItem> listItems, Map<num, CategoryItem> categories) {
    if (listItems.isEmpty) {
      return Expanded(
          child: Center(
              child: Text("No transactions found",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold))));
    }
    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: listItems.length,
        itemBuilder: (context, index) {
          switch (listItems[index].type) {
            case "transaction":
              Transaction curTransaction = listItems[index].item as Transaction;
              CategoryItem? curCategoryItem =
                  categories[curTransaction.categoryId];
              return Dismissible(
                key: Key(curTransaction.id.toString()),
                onDismissed: (direction) {
                  // Remove the item from the data source.
                  final transactionToRemove = curTransaction;
                  context.read<TransactionList>().remove(transactionToRemove);
                  // Then show a snackbar.
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: const Text('Transaction removed'),
                          action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                context
                                    .read<TransactionList>()
                                    .modify(transactionToRemove);
                              })))
                      .closed
                      .then((value) async {
                    if (value == SnackBarClosedReason.timeout ||
                        value == SnackBarClosedReason.remove) {
                      bool ret = await DatabaseHelper.instance
                          .deleteTransaction(transactionToRemove.id);
                      if (ret == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to delete transaction')));
                      }
                    }
                  });
                },
                background: Container(color: Colors.red),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ModifyTransactionsPage(
                              transaction: curTransaction)),
                    );
                  },
                  leading: FloatingActionButton.small(
                    child: Icon(
                      curCategoryItem!.icon,
                      color: Colors.white,
                    ),
                    backgroundColor: curCategoryItem.color,
                    elevation: 0,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) =>
                            const CategorySelectorWidget(),
                      ).then((value) async {
                        if (null != value) {
                          curTransaction.categoryId = value["id"] as int;
                          bool ret = await DatabaseHelper.instance
                              .updateTransaction(curTransaction);
                          if (false == ret) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Failed to update transaction')));
                          } else {
                            context
                                .read<TransactionList>()
                                .modify(curTransaction);
                          }
                        }
                      });
                    },
                  ),
                  title: Text(curTransaction.comment ?? curCategoryItem.name),
                  trailing: Text(
                      (curCategoryItem.type == "expense" ? "-" : "") +
                          curTransaction.money.toStringAsFixed(2),
                      style: curCategoryItem.type == "expense"
                          ? const TextStyle(color: Colors.red)
                          : const TextStyle(color: Colors.green)),
                ),
              );
            case "date":
              Map<String, dynamic> item =
                  listItems[index].item as Map<String, dynamic>;
              return Container(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          (item['date'] as DateTime).format("yyyy-MM-dd"),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text((item['total'] as double).toStringAsFixed(2),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12))
                            ])
                      ]),
                ),
              );
            default:
              return Container();
          }
        },
      ),
    );
  }
}
