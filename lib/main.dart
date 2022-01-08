import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/budget/modifyBudget.dart';
import 'package:ji_zhang/widget/navigationPage/account.dart';
import 'package:ji_zhang/widget/navigationPage/budget.dart';
import 'package:ji_zhang/widget/navigationPage/chart.dart';
import 'package:ji_zhang/widget/navigationPage/transaction.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    Provider<MyDatabase>(
      create: (context) => MyDatabase(),
      child: const MyApp(),
      dispose: (context, db) => db.close(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        // This is the theme of your application.
        primaryColor: const Color(0xFF68a1e8),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  int _currentIndex = 0;
  final List _children = [
    const TransactionWidget(),
    const ChartWidget(),
    const BudgetWidget(),
    const AccountWidget()
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _children[_currentIndex],
      ),
      floatingActionButton: _currentIndex == 1 || _currentIndex == 3
          ? null
          : FloatingActionButton.small(
              heroTag: 'add_transaction',
              elevation: 4.0,
              child: const Icon(Icons.add),
              onPressed: () {
                switch (_currentIndex) {
                  case 0:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ModifyTransactionsPage(transaction: null)),
                    );
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ModifyBudgetPage(budget: null)),
                    );
                    break;
                }
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: AppLocalizations.of(context)!.bottomNav_Transactions,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: AppLocalizations.of(context)!.bottomNav_Chart,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            label: AppLocalizations.of(context)!.bottomNav_Budgets,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: AppLocalizations.of(context)!.bottomNav_Account,
          ),
        ],
      ),
    );
  }
}
