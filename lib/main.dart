import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/budget/modifyBudget.dart';
import 'package:ji_zhang/widget/navigationPage/settings.dart';
import 'package:ji_zhang/widget/navigationPage/budget.dart';
import 'package:ji_zhang/widget/navigationPage/chart.dart';
import 'package:ji_zhang/widget/navigationPage/transaction.dart';
import 'package:ji_zhang/widget/ocr/textRecognition.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  WidgetsFlutterBinding.ensureInitialized();
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
        useMaterial3: false,
        // This is the theme of your application.
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        }),
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
    const SettingsWidget()
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _children[_currentIndex],
        ],
      ),
      floatingActionButton: () {
        switch (_currentIndex) {
          case 1:
          case 3:
            return null;
          case 0:
            return IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'add_transaction_manual',
                    elevation: 4.0,
                    child: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ModifyTransactionsPage(
                                  transaction: null,
                                  category: null,
                                )),
                      );
                    },
                  ),
                  FloatingActionButton.small(
                    heroTag: 'add_transaction_ocr',
                    elevation: 4.0,
                    child: const Icon(Icons.camera_alt_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TextRecognitionWidget()),
                      );
                    },
                  ),
                ],
              ),
            );
          case 2:
            return FloatingActionButton.small(
              heroTag: 'add_transaction',
              elevation: 4.0,
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ModifyBudgetPage(budget: null)),
                );
              },
            );
        }
        return null;
      }(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: AppLocalizations.of(context)!.bottomNav_Transactions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insert_chart_outlined),
            label: AppLocalizations.of(context)!.bottomNav_Chart,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.attach_money_rounded),
            label: AppLocalizations.of(context)!.bottomNav_Budgets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: AppLocalizations.of(context)!.bottomNav_Settings,
          ),
        ],
      ),
    );
  }
}
