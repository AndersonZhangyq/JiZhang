import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/widget/modifyTransaction.dart';
import 'package:ji_zhang/widget/navigationPage/account.dart';
import 'package:ji_zhang/widget/navigationPage/budget.dart';
import 'package:ji_zhang/widget/navigationPage/chart.dart';
import 'package:ji_zhang/widget/navigationPage/transactions.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<CategoryList>(
      create: (context) {
        CategoryList categoryList = CategoryList();
        DatabaseHelper.instance.getAllCategories().then((ret) {
          List<CategoryItem> retItem = [];
          for (var element in ret) {
            retItem.add(CategoryItem(element));
            // print(element.name);
          }
          categoryList.addAll(retItem);
        });
        return categoryList;
      },
    ),
    ChangeNotifierProvider<TransactionList>(
      create: (context) {
        TransactionList transactionList = TransactionList();
        DatabaseHelper.instance
            .getTransactionsByMonth(DateTime.now().year, DateTime.now().month)
            .then((ret) {
          List<Transaction> retItem = [];
          for (var element in ret) {
            retItem.add(element);
            // print(element.id);
          }
          transactionList.addAll(retItem);
        });
        return transactionList;
      },
    ),
    ChangeNotifierProvider<EventList>(
      create: (context) {
        EventList eventList = EventList();
        DatabaseHelper.instance.getAllEvents().then((ret) {
          List<Event> retItem = [];
          for (var element in ret) {
            retItem.add(element);
            // print(element.id);
          }
          eventList.addAll(retItem);
        });
        return eventList;
      },
    ),
    ChangeNotifierProvider<TagList>(
      create: (context) {
        TagList tagList = TagList();
        DatabaseHelper.instance.getAllTags().then((ret) {
          List<Tag> retItem = [];
          for (var element in ret) {
            retItem.add(element);
            // print(element.id);
          }
          tagList.addAll(retItem);
        });
        return tagList;
      },
    )
  ], child: const MyApp()));
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
    const TransactionsWidget(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[_children[_currentIndex]],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'add_transaction',
        elevation: 4.0,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const ModifyTransactionsPage(transaction: null)),
          );
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
