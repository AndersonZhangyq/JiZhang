import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/addCategory.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';

class ModifyCategoryWidget extends StatefulWidget {
  const ModifyCategoryWidget({Key? key, required this.tabName})
      : super(key: key);
  final String tabName;

  @override
  State<StatefulWidget> createState() => _ModifyCategoryState();
}

class _ModifyCategoryState extends State<ModifyCategoryWidget> {
  late MyDatabase db;
  List<CategoryItem> expenseCategory = [];
  List<CategoryItem> incomeCategory = [];
  int expenseChanged = 0;
  int incomeChanged = 0;

  @override
  void initState() {
    super.initState();
    expenseCategory.clear();
    incomeCategory.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  void _saveList() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    // save category change
    if (expenseChanged > 0) {
      for (int i = 0; i < expenseCategory.length; i++) {
        CategoryItem element = expenseCategory[i];
        db.update(db.categories).replace(CategoriesCompanion(
              id: drift.Value(element.id),
              index: drift.Value(element.index),
            ));
      }
    }
    if (incomeChanged > 0) {
      for (int i = 0; i < incomeCategory.length; i++) {
        CategoryItem element = incomeCategory[i];
        db.update(db.categories).replace(CategoriesCompanion(
              id: drift.Value(element.id),
              index: drift.Value(element.index),
            ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryItem>>(
        stream: db.getAllCategories(),
        initialData: const <CategoryItem>[],
        builder: (context, snapshot) {
          final categories = snapshot.data!;
          for (var item in categories) {
            if (item.type == "expense") {
              expenseCategory.add(item);
            } else {
              incomeCategory.add(item);
            }
          }
          return WillPopScope(
            onWillPop: () {
              _saveList();
              return Future<bool>.value(true);
            },
            child: Scaffold(
                appBar: AppBar(
                  title:
                      Text(AppLocalizations.of(context)!.modifyCategory_Title),
                  leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _saveList();
                        Navigator.of(context, rootNavigator: true).pop(context);
                      }),
                ),
                body: Center(
                  child: DefaultTabController(
                      length: 2,
                      initialIndex: widget.tabName == "expense" ? 0 : 1,
                      child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              TabBar(
                                labelColor: Colors.grey,
                                tabs: [
                                  Tab(
                                      text: AppLocalizations.of(context)!
                                          .tab_Expense),
                                  Tab(
                                      text: AppLocalizations.of(context)!
                                          .tab_Income),
                                ],
                              ),
                              Expanded(
                                  child: TabBarView(
                                children: [
                                  Column(children: [
                                    Expanded(
                                        child: _buildExpenseCategoryList(
                                            expenseCategory)),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const AddCategoryWidget()),
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              width: 1,
                                              color: (Colors.grey[300])!,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(AppLocalizations.of(context)!
                                                .modifyCategory_Add_Category)
                                          ],
                                        ),
                                      ),
                                    )
                                  ]),
                                  Column(children: [
                                    Expanded(
                                        child: _buildIncomeCategoryList(
                                            incomeCategory)),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const AddCategoryWidget()),
                                        );
                                      },
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              width: 1,
                                              color: (Colors.grey[300])!,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(AppLocalizations.of(context)!
                                                .modifyCategory_Add_Category)
                                          ],
                                        ),
                                      ),
                                    )
                                  ])
                                ],
                              ))
                            ],
                          ))),
                )),
          );
        });
  }

  _buildExpenseCategoryList(List<CategoryItem> expenseCategory) {
    return ReorderableListView.builder(
      // physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          key: Key(index.toString()),
          leading: SizedBox(
            height: 25,
            child: FloatingActionButton.small(
                heroTag: "remove_expense_$index",
                elevation: 0,
                child: const Icon(
                  Icons.horizontal_rule,
                  size: 15,
                ),
                onPressed: () {
                  final categoryToRemove = expenseCategory[index];
                  setState(() {
                    expenseCategory.removeAt(index);
                    expenseChanged++;
                  });
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .modifyCategory_SnackBar_category_removed),
                          action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                expenseChanged--;
                                setState(() {
                                  expenseCategory.insert(
                                      index, categoryToRemove);
                                });
                              })))
                      .closed
                      .then((value) async {
                    if (value == SnackBarClosedReason.timeout ||
                        value == SnackBarClosedReason.remove) {
                      int ret = await (db.delete(db.categories)
                            ..where((t) => t.id.equals(categoryToRemove.id)))
                          .go();
                      if (ret == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .modifyCategory_SnackBar_failed_to_remove_category)));
                      }
                    }
                  });
                },
                backgroundColor: Colors.red),
          ),
          title: Text(expenseCategory[index].getDisplayName(context)),
          trailing: const Icon(Icons.drag_handle),
        );
      },
      itemCount: expenseCategory.length,
      onReorder: (int oldIndex, int newIndex) {
        expenseChanged++;
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final CategoryItem item = expenseCategory.removeAt(oldIndex);
          expenseCategory.insert(newIndex, item);
        });
      },
    );
  }

  _buildIncomeCategoryList(List<CategoryItem> incomeCategory) {
    return ReorderableListView.builder(
      // physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          key: Key(index.toString()),
          leading: SizedBox(
            height: 25,
            child: FloatingActionButton.small(
                heroTag: "remove_income_$index",
                elevation: 0,
                child: const Icon(
                  Icons.horizontal_rule,
                  size: 15,
                ),
                onPressed: () {
                  final categoryToRemove = incomeCategory[index];
                  setState(() {
                    incomeCategory.removeAt(index);
                    incomeChanged++;
                  });
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!
                              .modifyCategory_SnackBar_category_removed),
                          action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                incomeChanged--;
                                setState(() {
                                  incomeCategory.insert(
                                      index, categoryToRemove);
                                });
                              })))
                      .closed
                      .then((value) async {
                    if (value == SnackBarClosedReason.timeout ||
                        value == SnackBarClosedReason.remove) {
                      int ret = await (db.delete(db.categories)
                            ..where((t) => t.id.equals(categoryToRemove.id)))
                          .go();
                      if (ret == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .modifyCategory_SnackBar_failed_to_remove_category)));
                      }
                    }
                  });
                },
                backgroundColor: Colors.red),
          ),
          title: Text(incomeCategory[index].getDisplayName(context)),
          trailing: const Icon(Icons.drag_handle),
        );
      },
      itemCount: incomeCategory.length,
      onReorder: (int oldIndex, int newIndex) {
        incomeChanged++;
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final CategoryItem item = incomeCategory.removeAt(oldIndex);
          incomeCategory.insert(newIndex, item);
        });
      },
    );
  }
}
