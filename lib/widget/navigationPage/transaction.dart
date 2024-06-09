import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/swip_detector.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/account/modifyAccount.dart';
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
    return StreamBuilder<List<Account>>(
        stream: db.watchAccounts(),
        builder: (context, snapshot) {
          if (snapshot.hasData == false ||
              snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }
          List<Account> accounts = snapshot.data!;
          return StreamBuilder<Map<int, CategoryItem>>(
              stream:
                  db.watchAllCategories()!.map<Map<int, CategoryItem>>((value) {
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
                      if (snapshot.hasData == false ||
                          snapshot.connectionState == ConnectionState.waiting) {
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
                              _buildTopBar(transactions, categories, accounts),
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
        });
  }

  Widget _buildTopBar(List<Transaction> transactions,
      Map<int, CategoryItem> categories, List<Account> accounts) {
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
        padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 12.0),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.account_circle_rounded,
                            color: Colors.lightBlue.withOpacity(0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(15),
                                        topLeft: Radius.circular(15))),
                                context: context,
                                builder: (context) {
                                  List<Row> rows = [];
                                  for (int i = 0; i < accounts.length; i += 2) {
                                    rows.add(Row(
                                      children: [
                                        Flexible(
                                            flex: 1,
                                            child: AccountGridViewItemWidget(
                                              account: accounts[i],
                                              isSelected: accounts[i].id ==
                                                  db.currentAccountId,
                                              onPressed: () {
                                                db.currentAccountId =
                                                    accounts[i].id;
                                                setState(() {});
                                                Navigator.pop(context);
                                              },
                                            )),
                                        Flexible(
                                            flex: 1,
                                            child: (i + 1 < accounts.length)
                                                ? AccountGridViewItemWidget(
                                                    account: accounts[i + 1],
                                                    isSelected:
                                                        accounts[i + 1].id ==
                                                            db.currentAccountId,
                                                    onPressed: () {
                                                      db.currentAccountId =
                                                          accounts[i + 1].id;
                                                      setState(() {});
                                                      Navigator.pop(context);
                                                    },
                                                  )
                                                : Container())
                                      ],
                                    ));
                                  }
                                  return AccountSwitchDialog(
                                      db: db, rows: rows, accounts: accounts);
                                });
                          },
                          child: Text(
                            accounts
                                .firstWhere((element) =>
                                    element.id == db.currentAccountId)
                                .name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        showMonthPicker(
                          context: context,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(3000),
                          initialDate: DateTime(int.parse(selectedYear),
                              int.parse(selectedMonth)),
                        ).then((date) {
                          if (date != null) {
                            setState(() {
                              selectedYear = date.year.toString();
                              selectedMonth = date.month.toString();
                            });
                          }
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            flex: 2,
                            child: Text(
                              selectedYear +
                                  '-' +
                                  selectedMonth.padLeft(2, '0'),
                              // style: const TextStyle(
                              //     fontWeight: FontWeight.bold,
                              //     fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.black)
                        ],
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: Container())
                ],
              ),
            ),
            IntrinsicHeight(
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountSwitchDialog extends StatefulWidget {
  AccountSwitchDialog({
    super.key,
    required this.db,
    required this.rows,
    required this.accounts,
  });

  final MyDatabase db;
  final List<Row> rows;
  final List<Account> accounts;

  @override
  State<AccountSwitchDialog> createState() => _AccountSwitchDialogState();
}

class _AccountSwitchDialogState extends State<AccountSwitchDialog> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .transactions_BottomSheet_Title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ModifyAccountPage(
                                  accounts: widget.accounts,
                                  db: widget.db,
                                )),
                      ).then((value) {
                        setState(() {});
                      });
                    },
                    child: Text(
                      AppLocalizations.of(context)!
                          .transactions_BottomSheet_ManageAccounts,
                    ),
                  ),
                ],
              ),
            ),
            ...widget.rows,
          ]),
        ),
      ),
    );
  }
}

class AccountGridViewItemWidget extends StatelessWidget {
  AccountGridViewItemWidget(
      {super.key,
      required this.account,
      required this.isSelected,
      required this.onPressed});

  final Account account;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TextButton(
          onPressed: onPressed,
          child: SizedBox(width: double.infinity, child: Text(account.name)),
        ),
        isSelected
            ? const Positioned(
                right: 5,
                child: Icon(
                  Icons.check_circle_outlined,
                  color: Colors.green,
                ),
              )
            : Container(),
      ],
    );
  }
}
