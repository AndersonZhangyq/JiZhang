import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ji_zhang/common/predefinedRecurrence.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/datetimeExtension.dart';

class BudgetItem {
  BudgetItem(this.budget);

  late final Budget budget;
  double used = 0.0;

  String get name {
    return budget.name;
  }

  double get amount {
    return budget.amount;
  }

  RECURRENCE_TYPE get recurrence {
    return budget.recurrence;
  }

  Set<int> get categoryIds {
    return Set<int>.from(budget.categoryIds);
  }
}

class BudgetWidget extends StatefulWidget {
  const BudgetWidget({Key? key}) : super(key: key);

  @override
  State<BudgetWidget> createState() => _BudgetWidgetState();
}

class _BudgetWidgetState extends State<BudgetWidget> {
  late MyDatabase db;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BudgetItem>>(
        stream: db.select(db.budgets).watch().map((value) {
          return value.map((budget) => BudgetItem(budget)).toList();
        }),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final budgets = snapshot.data!;
            DateTime now = DateTime.now().getDateOnly();
            int currentYear = now.year;
            int currentMonth = now.month;
            int currentDay = now.day;
            int currentWeek = now.weekday;
            List<Transaction>? curDayTransactions = null;
            List<Transaction>? curWeekTransactions = null;
            List<Transaction>? curBiWeekTransactions = null;
            List<Transaction>? curMonthTransactions = null;
            List<Transaction>? curYearTransactions = null;
            return FutureProvider<List<BudgetItem>?>(
                create: (_) async {
                  for (final budget in budgets) {
                    switch (budget.recurrence) {
                      case RECURRENCE_TYPE.daily:
                        break;
                      case RECURRENCE_TYPE.biweekly:
                        break;
                      case RECURRENCE_TYPE.weekly:
                        break;
                      case RECURRENCE_TYPE.monthly:
                        if (curMonthTransactions == null) {
                          DateTime startDate =
                              DateTime(currentYear, currentMonth);
                          DateTime endDate =
                              DateTime(currentYear, currentMonth + 1)
                                  .subtract(const Duration(days: 1));
                          curMonthTransactions = await (db
                                  .select(db.transactions)
                                ..where((t) => t.date.isBetween(
                                    drift.CustomExpression(
                                        (startDate.millisecondsSinceEpoch /
                                                1000)
                                            .toString(),
                                        precedence: drift.Precedence.primary),
                                    drift.CustomExpression(
                                        (endDate.millisecondsSinceEpoch / 1000)
                                            .toString(),
                                        precedence: drift.Precedence.primary)))
                                ..orderBy([
                                  (t) => drift.OrderingTerm(
                                      expression: t.id,
                                      mode: drift.OrderingMode.desc)
                                ]))
                              .get();
                        }
                        var totalExpenses = 0.0;
                        var categoryExpenses = budget.categoryIds;
                        for (final transaction in curMonthTransactions!) {
                          if (categoryExpenses
                              .contains(transaction.categoryId)) {
                            totalExpenses += transaction.amount;
                          }
                        }
                        budget.used = totalExpenses;
                        break;
                      case RECURRENCE_TYPE.yearly:
                        break;
                    }
                  }
                  return budgets;
                },
                initialData: null,
                child: Consumer<List<BudgetItem>?>(builder: (_, value, __) {
                  if (value != null) {
                    return Expanded(
                      child: ListView.builder(
                          itemBuilder: (context, index) {
                            final budget = budgets[index];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: Text(budget.name),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        budget.used.toStringAsFixed(2),
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      Text(
                                          " " +
                                              AppLocalizations.of(context)!
                                                  .budget_total +
                                              " ",
                                          style: const TextStyle(fontSize: 12)),
                                      Text(budget.amount.toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Stack(
                                    alignment: AlignmentDirectional.centerStart,
                                    children: [
                                      LinearProgressIndicator(
                                        value: budget.used / budget.amount,
                                        minHeight: 25,
                                        backgroundColor: Colors.grey[200],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.blue[100]!),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                            (budget.used / budget.amount * 100)
                                                    .toStringAsFixed(2) +
                                                "%",
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          itemCount: budgets.length),
                    );
                  } else {
                    return Expanded(
                        child: Center(
                            child: Text(
                                AppLocalizations.of(context)!
                                    .transactions_ListView_No_Transaction,
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[300],
                                    fontWeight: FontWeight.bold))));
                  }
                }));
          } else {
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
        });
  }
}
