import 'package:flutter/material.dart';
import 'package:ji_zhang/common/dbHelper.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:ji_zhang/models/eventList.dart';
import 'package:ji_zhang/models/index.dart';
import 'package:ji_zhang/models/labelList.dart';
import 'package:ji_zhang/models/transactionList.dart';
import 'package:ji_zhang/widget/addTransaction.dart';
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
        DatabaseHelper.instance.queryCategory().then((ret) {
          List<CategoryItem> retItem = [];
          for (var element in ret) {
            retItem.add(CategoryItem(element));
            print(element.name);
          }
          categoryList.addAll(retItem);
        });
        return categoryList;
      },
    ),
    ChangeNotifierProvider<TransactionList>(
      create: (context) {
        TransactionList transactionList = TransactionList();
        DatabaseHelper.instance.queryTransaction().then((ret) {
          List<Transaction> retItem = [];
          for (var element in ret) {
            retItem.add(element);
            print(element.id);
          }
          transactionList.addAll(retItem);
        });
        return transactionList;
      },
    ),
    ChangeNotifierProvider<EventList>(
      create: (context) {
        EventList eventList = EventList();
        DatabaseHelper.instance.queryEvent().then((ret) {
          List<Event> retItem = [];
          for (var element in ret) {
            retItem.add(element);
            print(element.id);
          }
          eventList.addAll(retItem);
        });
        return eventList;
      },
    ),
    ChangeNotifierProvider<LabelList>(
      create: (context) {
        LabelList labelList = LabelList();
        DatabaseHelper.instance.queryLabel().then((ret) {
          List<Label> retItem = [];
          for (var element in ret) {
            retItem.add(element);
            print(element.id);
          }
          labelList.addAll(retItem);
        });
        return labelList;
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
      title: 'Flutter Demo',
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
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[_children[_currentIndex]],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        elevation: 4.0,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddTransactionsWidget()),
          );
        },
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_rounded),
            label: 'Budgets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
