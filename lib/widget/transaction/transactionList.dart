import 'package:flutter/material.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/categorySelector.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import "package:collection/collection.dart";
import 'package:ji_zhang/common/datetimeExtension.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart'; // Import the intl package

class ListItem {
  late String type;
  late Object item;
}

class TransactionListWidget extends StatelessWidget {
  const TransactionListWidget(
      {super.key,
      required this.context,
      required this.db,
      required this.transactions,
      required this.categories,
      this.isByDate = true});

  final BuildContext context;
  final MyDatabase db;
  final List<Transaction> transactions;
  final Map<int, CategoryItem> categories;
  final bool isByDate;

  Widget _buildTransactionListByDate() {
    var groupedTransaction =
        groupBy(transactions, (Transaction t) => t.date.getDateOnly());
    final sortedDates = groupedTransaction.keys.toList()
      ..sort((a, b) => -a.compareTo(b));
    Locale locale = Localizations.localeOf(context);

    if (sortedDates.isEmpty) {
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
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final transactionsOfDate = groupedTransaction[date]!;
          double income = 0.0, expense = 0.0;
          for (var transaction in transactionsOfDate) {
            if (categories[transaction.categoryId]?.type == "income") {
              income += transaction.amount;
            } else {
              expense += transaction.amount;
            }
          }
          double total = income - expense;
          return Card.outlined(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date.format("yyyy-MM-dd E", locale.toString()),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        (total > 0 ? "+" : "") + total.toStringAsFixed(2),
                        style: TextStyle(
                          color: total < 0 ? Colors.red : Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...transactionsOfDate.map((curTransaction) {
                    final curCategoryItem =
                        categories[curTransaction.categoryId];
                    return Dismissible(
                      key: Key(curTransaction.id.toString()),
                      background: Container(color: Colors.redAccent),
                      onDismissed: (direction) async {
                        final transactionToRemove = curTransaction;
                        int ret = await (db.delete(db.transactions)
                              ..where(
                                  (t) => t.id.equals(transactionToRemove.id)))
                            .go();
                        if (ret == 0) {
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLocalizations.of(context)!
                                  .transactions_SnackBar_failed_to_delete_transaction)));
                        } else {
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
                                        .insertOnConflictUpdate(
                                            transactionToRemove);
                                  })));
                        }
                      },
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
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
                              heroTag:
                                  "transaction_category_${curTransaction.id}",
                              backgroundColor: curCategoryItem!.color,
                              elevation: 0,
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      const CategorySelectorWidget(),
                                ).then((value) async {
                                  if (null != value) {
                                    int ret = await (db.update(db.transactions)
                                          ..where((t) =>
                                              t.id.equals(curTransaction.id)))
                                        .write(TransactionsCompanion(
                                            categoryId: drift.Value(
                                                value["id"] as int)));
                                    if (0 == ret) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(AppLocalizations.of(
                                                      context)!
                                                  .transactions_SnackBar_failed_to_update_transaction)));
                                    }
                                  }
                                });
                              },
                              child: Icon(
                                curCategoryItem!.icon,
                                color: Colors.white,
                              ),
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
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 8),
                                  ),
                                ),
                              )
                          ],
                        ),
                        title: Text(curTransaction.comment ??
                            curCategoryItem.getDisplayName(context)),
                        trailing: Text(
                            (curCategoryItem.type == "expense" ? "-" : "+") +
                                curTransaction.amount.toStringAsFixed(2),
                            style: curCategoryItem.type == "expense"
                                ? const TextStyle(color: Colors.red)
                                : const TextStyle(color: Colors.green)),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
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
                    backgroundColor: curCategoryItem!.color,
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
                    child: Icon(
                      curCategoryItem!.icon,
                      color: Colors.white,
                    ),
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
                          style:
                              const TextStyle(color: Colors.black, fontSize: 8),
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
