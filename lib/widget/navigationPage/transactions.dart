import 'package:flutter/material.dart';
import "package:collection/collection.dart";
import 'package:ji_zhang/common/datetime_extension.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/models/transactionList.dart';
import 'package:ji_zhang/widget/categorySelector.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';
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
  @override
  Widget build(BuildContext context) {
    final Map<num, CategoryItem> categories =
        Provider.of<CategoryList>(context, listen: false).itemsMap;
    final List<Transaction> transactions =
        context.watch<TransactionList>().items;
    var groupedTransaction = groupBy(transactions, (Transaction t) => t.date);
    List<ListItem> listItems = [];
    groupedTransaction.forEach((date, transactions) {
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
        ..item = {"date": date, "income": income, "expense": expense});
      listItems.addAll(tmpTrans);
    });
    return Expanded(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: Column(
                  children: const [Text("2021"), Text("12")],
                )),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                        children: const [Text("Expense"), Text("12")],
                      )),
                      Expanded(
                          child: Column(
                        children: const [Text("Income"), Text("12")],
                      )),
                    ],
                  ),
                )
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  switch (listItems[index].type) {
                    case "transaction":
                      Transaction curTransaction =
                          listItems[index].item as Transaction;
                      CategoryItem? curCategoryItem =
                          categories[curTransaction.categoryId];
                      return Dismissible(
                        key: Key(curTransaction.id.toString()),
                        onDismissed: (direction) {
                          // Remove the item from the data source.
                          final transactionToRemove = curTransaction;
                          context
                              .read<TransactionList>()
                              .remove(transactionToRemove);

                          // Then show a snackbar.
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
                            if (value == SnackBarClosedReason.timeout) {
                              bool ret = await DatabaseHelper.instance
                                  .deleteTransaction(transactionToRemove.id);
                              if (ret == false) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Failed to delete transaction')));
                              }
                            }
                          });
                        },
                        background: Container(color: Colors.red),
                        child: ListTile(
                          onLongPress: () {
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
                                  curTransaction.categoryId =
                                      value["id"] as int;
                                  bool ret = await DatabaseHelper.instance
                                      .updateTransaction(curTransaction);
                                  if (false == ret) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Failed to update transaction')));
                                  } else {
                                    context
                                        .read<TransactionList>()
                                        .modify(curTransaction);
                                  }
                                }
                              });
                            },
                          ),
                          title: Text(
                              curTransaction.comment ?? curCategoryItem.name),
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
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  (item['date'] as DateTime)
                                      .format("yyyy-MM-dd"),
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                                Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      item['expense'] != 0
                                          ? Text(
                                              "Expense: " +
                                                  (item['expense'] as double)
                                                      .toStringAsFixed(2),
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12))
                                          : Container(),
                                      item['income'] != 0
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8.0),
                                              child: Text(
                                                  "Income: " +
                                                      (item['income'] as double)
                                                          .toStringAsFixed(2),
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12)),
                                            )
                                          : Container()
                                    ])
                              ]),
                        ),
                      );
                    default:
                      return Container();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
