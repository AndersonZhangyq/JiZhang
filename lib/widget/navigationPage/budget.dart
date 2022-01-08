import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/animation_progress_bar.dart';
import 'package:ji_zhang/common/predefinedRecurrence.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/budget/modifyBudget.dart';
import 'package:provider/provider.dart';

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
  List<BudgetItem>? budgets = null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 50,
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.of(context)!.budget_AppBarTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Divider(
              height: 2,
              thickness: 1,
              color: Colors.grey[300],
            ),
            Expanded(
              child: FutureBuilder<List<BudgetItem>>(
                  future: db.getBudgetItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      var budgets = snapshot.data;
                      if (budgets!.isEmpty) {
                        return Expanded(
                            child: Center(
                                child: Text(
                                    AppLocalizations.of(context)!
                                        .transactions_ListView_No_Transaction,
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[300],
                                        fontWeight: FontWeight.bold))));
                      } else {
                        return ListView.builder(
                            itemBuilder: (context, index) {
                              final budget = budgets[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ModifyBudgetPage(
                                              budget: budget.budget,
                                            )),
                                  ).then((value) => setState(() {}));
                                },
                                child: Column(
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
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          Text(budget.amount.toStringAsFixed(2),
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: FAProgressBar(
                                        currentValue:
                                            (budget.used / budget.amount * 100)
                                                .toInt(),
                                        size: 25,
                                        backgroundColor: Colors.grey[200]!,
                                        progressColor: Colors.blue[300]!,
                                        displayText: '%',
                                        displayTextStyle: (budget.used /
                                                    budget.amount *
                                                    100) <
                                                10
                                            ? const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12)
                                            : const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            itemCount: budgets.length);
                      }
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
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
