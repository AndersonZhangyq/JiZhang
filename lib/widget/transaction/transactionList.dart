import 'package:flutter/material.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/categorySelector.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import "package:collection/collection.dart";
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;

class ListItem {
  late String type;
  late Object item;
}

class TransactionListWidget extends StatelessWidget {
  const TransactionListWidget(
      {Key? key,
      required this.context,
      required this.db,
      required this.transactions,
      required this.categories,
      this.isByDate = true})
      : super(key: key);

  final BuildContext context;
  final MyDatabase db;
  final List<Transaction> transactions;
  final Map<int, CategoryItem> categories;
  final bool isByDate;

  Widget _buildTransactionListByDate() {
    var groupedTransaction =
        groupBy(transactions, (Transaction t) => t.date.getDateOnly());
    List<ListItem> listItems = [];
    groupedTransaction.keys.sorted((a, b) => -a.compareTo(b)).forEach((date) {
      List<Transaction> transactions = groupedTransaction[date]!;
      double income = 0.0, expense = 0.0;
      List<ListItem> tmpTrans = [];
      for (var transaction in transactions) {
        switch (categories[transaction.categoryId]!.type) {
          case "expense":
            expense += transaction.amount;
            break;
          case "income":
            income += transaction.amount;
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
    });
    if (listItems.isEmpty) {
      return Expanded(
          child: Center(
              child: Text(AppLocalizations.of(context)!.listView_Empty,
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
                background: Container(color: Colors.redAccent),
                onDismissed: (direction) async {
                  // Remove the item from the data source.
                  final transactionToRemove = curTransaction;
                  int ret = await (db.delete(db.transactions)
                        ..where((t) => t.id.equals(transactionToRemove.id)))
                      .go();
                  if (ret == 0) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .transactions_SnackBar_failed_to_delete_transaction)));
                  } else {
                    // Then show a snackbar.
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .transactions_SnackBar_Remove_Transaction),
                        action: SnackBarAction(
                            label: AppLocalizations.of(context)!
                                .snackBarAction_Undo,
                            onPressed: () async {
                              await db
                                  .into(db.transactions)
                                  .insertOnConflictUpdate(transactionToRemove);
                            })));
                  }
                },
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ModifyTransactionsPage(
                                transaction: curTransaction,
                                category: curCategoryItem,
                              )),
                    );
                  },
                  leading: Stack(alignment: Alignment.bottomRight, children: [
                    FloatingActionButton.small(
                      heroTag: "transaction_category_$index",
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
                            int ret = await (db.update(db.transactions)
                                  ..where(
                                      (t) => t.id.equals(curTransaction.id)))
                                .write(TransactionsCompanion(
                                    categoryId:
                                        drift.Value(value["id"] as int)));
                            if (0 == ret) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(AppLocalizations.of(context)!
                                      .transactions_SnackBar_failed_to_update_transaction)));
                            }
                          }
                        });
                      },
                    ),
                    if (curCategoryItem.parentId != null)
                      Container(
                        decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            )),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            curCategoryItem.getTrueName(context),
                            style: TextStyle(color: Colors.black, fontSize: 8),
                          ),
                        ),
                      )
                  ]),
                  title: Text(curTransaction.comment ??
                      curCategoryItem.getDisplayName(context)),
                  trailing: Text(
                      (curCategoryItem.type == "expense" ? "-" : "") +
                          curTransaction.amount.toStringAsFixed(2),
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

  Widget _buildTransactionListByAmount() {
    var sortedTransction = transactions.toList()
      ..sort((a, b) => -a.amount.compareTo(b.amount));
    return Expanded(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: sortedTransction.length,
        itemBuilder: (context, index) {
          Transaction curTransaction = sortedTransction[index];
          CategoryItem? curCategoryItem = categories[curTransaction.categoryId];
          return Dismissible(
            key: Key(curTransaction.id.toString()),
            background: Container(color: Colors.redAccent),
            onDismissed: (direction) async {
              // Remove the item from the data source.
              final transactionToRemove = curTransaction;
              int ret = await (db.delete(db.transactions)
                    ..where((t) => t.id.equals(transactionToRemove.id)))
                  .go();
              if (ret == 0) {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .transactions_SnackBar_failed_to_delete_transaction)));
              } else {
                // Then show a snackbar.
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .transactions_SnackBar_Remove_Transaction),
                    action: SnackBarAction(
                        label:
                            AppLocalizations.of(context)!.snackBarAction_Undo,
                        onPressed: () async {
                          await db
                              .into(db.transactions)
                              .insertOnConflictUpdate(transactionToRemove);
                        })));
              }
            },
            child: ListTile(
              dense: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ModifyTransactionsPage(
                            transaction: curTransaction,
                            category: curCategoryItem,
                          )),
                );
              },
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  FloatingActionButton.small(
                    heroTag: "transaction_category_$index",
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
                          int ret = await (db.update(db.transactions)
                                ..where((t) => t.id.equals(curTransaction.id)))
                              .write(TransactionsCompanion(
                                  categoryId: drift.Value(value["id"] as int)));
                          if (0 == ret) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .transactions_SnackBar_failed_to_update_transaction)));
                          }
                        }
                      });
                    },
                  ),
                  if (curCategoryItem.parentId != null)
                    Container(
                      decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          )),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          curCategoryItem.getTrueName(context),
                          style: TextStyle(color: Colors.black, fontSize: 8),
                        ),
                      ),
                    )
                ],
              ),
              title: Text(curTransaction.comment ??
                  curCategoryItem.getDisplayName(context)),
              subtitle: Text(curTransaction.date.format("yyyy-MM-dd"),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              trailing: Text(
                  (curCategoryItem.type == "expense" ? "-" : "") +
                      curTransaction.amount.toStringAsFixed(2),
                  style: curCategoryItem.type == "expense"
                      ? const TextStyle(color: Colors.red)
                      : const TextStyle(color: Colors.green)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isByDate) {
      return _buildTransactionListByDate();
    } else {
      return _buildTransactionListByAmount();
    }
  }
}
