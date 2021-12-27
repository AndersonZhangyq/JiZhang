import 'package:flutter/material.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/models/transactionList.dart';
import 'package:ji_zhang/widget/addTransaction.dart';
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

class _TransactionListState extends State<TransactionListWidget> {
  @override
  Widget build(BuildContext context) {
    final Map<num, CategoryItem> categories =
        Provider.of<CategoryList>(context, listen: false).itemsMap;
    final List<Transaction> transactions =
        context.watch<TransactionList>().items;
    return Expanded(
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          CategoryItem? cur = categories[transactions[index].categoryId];
          return Dismissible(
            key: Key(transactions[index].id.toString()),
            onDismissed: (direction) {
              // Remove the item from the data source.
              final transactionToRemove = transactions[index];
              context.read<TransactionList>().remove(transactionToRemove);

              // Then show a snackbar.
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(
                      content: const Text('Transaction removed'),
                      action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            context
                                .read<TransactionList>()
                                .add(transactionToRemove, position: index);
                          })))
                  .closed
                  .then((value) async {
                if (value == SnackBarClosedReason.dismiss) {
                  if ((await DatabaseHelper.instance
                          .deleteTransaction(transactionToRemove.id)) ==
                      false) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Failed to delete transaction')));
                  }
                }
              });
            },
            background: Container(color: Colors.red),
            child: ListTile(
              leading: Icon(cur!.icon, color: cur.color),
              title: Text(cur.name),
              trailing: Text(
                  (cur.type == "expense" ? "-" : "") +
                      transactions[index].money.toString(),
                  style: cur.type == "expense"
                      ? const TextStyle(color: Colors.red)
                      : const TextStyle(color: Colors.green)),
            ),
          );
        },
      ),
    );
  }
}
