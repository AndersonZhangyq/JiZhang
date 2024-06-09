import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/addCategory.dart';
import 'package:ji_zhang/widget/loading.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';

class ModifyCategoryWidget extends StatefulWidget {
  const ModifyCategoryWidget({Key? key, required this.tabName})
      : super(key: key);
  final String tabName;

  @override
  State<StatefulWidget> createState() => _ModifyCategoryState();
}

class ChangeCounter {
  int changeCounter = 0;

  int get() {
    return changeCounter;
  }

  void increment() {
    changeCounter++;
  }

  void decrement() {
    changeCounter--;
  }
}

class _ModifyCategoryState extends State<ModifyCategoryWidget> {
  late MyDatabase db;
  List<CategoryItem> expenseCategory = [];
  List<CategoryItem> incomeCategory = [];
  ChangeCounter expenseChanged = ChangeCounter();
  ChangeCounter incomeChanged = ChangeCounter();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  void _saveList() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    db.transaction(() async {
      // save category change
      if (expenseChanged.get() > 0) {
        for (int i = 0; i < expenseCategory.length; i++) {
          CategoryItem element = expenseCategory[i];
          await (db.update(db.categories)
                ..where((t) => t.id.equals(element.id)))
              .write(CategoriesCompanion(
            pos: drift.Value(i),
          ));
        }
      }
      if (incomeChanged.get() > 0) {
        for (int i = 0; i < incomeCategory.length; i++) {
          CategoryItem element = incomeCategory[i];
          await (db.update(db.categories)
                ..where((t) => t.id.equals(element.id)))
              .write(CategoriesCompanion(
            pos: drift.Value(i),
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, List<CategoryItem>>>(
        stream: db.watchCategoriesGroupByType(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            expenseCategory = snapshot.data!['expense']!;
            incomeCategory = snapshot.data!['income']!;
            return WillPopScope(
              onWillPop: () {
                _saveList();
                return Future<bool>.value(true);
              },
              child: Scaffold(
                  appBar: AppBar(
                    title: Text(
                        AppLocalizations.of(context)!.modifyCategory_Title),
                    leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          _saveList();
                          Navigator.of(context, rootNavigator: true)
                              .pop(context);
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
                                          child: _buildCategoryList(
                                              expenseCategory,
                                              expenseChanged,
                                              "expense")),
                                      _buildAddCategory()
                                    ]),
                                    Column(children: [
                                      Expanded(
                                          child: _buildCategoryList(
                                              incomeCategory,
                                              incomeChanged,
                                              "income")),
                                      _buildAddCategory()
                                    ])
                                  ],
                                ))
                              ],
                            ))),
                  )),
            );
          }
          return const LoadingWidget();
        });
  }

  Widget _buildAddCategory() {
    return GestureDetector(
      onTap: () {
        _saveList();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddCategoryWidget()),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.modifyCategory_Add_Category)
          ],
        ),
      ),
    );
  }

  _buildCategoryList(List<CategoryItem> categories, ChangeCounter changeCounter,
      String categoryType) {
    return ReorderableListView.builder(
      // physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          key: Key(index.toString()),
          leading: SizedBox(
            height: 25,
            child: FloatingActionButton.small(
                heroTag: "remove_${categoryType}_$index",
                elevation: 0,
                child: const Icon(
                  Icons.horizontal_rule,
                  size: 15,
                ),
                onPressed: () async {
                  final categoryToRemove = categories[index];
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(AppLocalizations.of(context)!
                              .modifyCategory_Dialog_title_remove_category),
                          content: Text(AppLocalizations.of(context)!
                              .modifyCategory_Dialog_content_remove_category),
                          actions: [
                            TextButton(
                                child:
                                    Text(AppLocalizations.of(context)!.cancel),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                            TextButton(
                                child:
                                    Text(AppLocalizations.of(context)!.confirm),
                                onPressed: () async {
                                  await _removeCategory(
                                      categoryToRemove, changeCounter);
                                  Navigator.of(context).pop();
                                }),
                          ],
                        );
                      });
                  // changeCounter.increment();
                  // await (db.delete(db.categories)
                  //       ..where((t) => t.id.equals(categoryToRemove.id)))
                  //     .go();
                  // ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //     content: Text(AppLocalizations.of(context)!
                  //         .modifyCategory_SnackBar_category_removed),
                  //     action: SnackBarAction(
                  //         label: 'Undo',
                  //         onPressed: () {
                  //           changeCounter.decrement();
                  //           db.into(db.categories).insert(
                  //               CategoriesCompanion.insert(
                  //                   name: categoryToRemove.name,
                  //                   type: categoryToRemove.type,
                  //                   icon: categoryToRemove.originIcon,
                  //                   color: categoryToRemove.originColor,
                  //                   pos: categoryToRemove.pos,
                  //                   predefined: categoryToRemove.predefined,
                  //                   accountId: db.currentAccountId));
                  //         })));
                },
                backgroundColor: Colors.red),
          ),
          title: Text(categories[index].getDisplayName(context)),
          trailing: const Icon(Icons.drag_handle),
        );
      },
      itemCount: categories.length,
      onReorder: (int oldIndex, int newIndex) {
        changeCounter.increment();
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final CategoryItem item = categories.removeAt(oldIndex);
        categories.insert(newIndex, item);
      },
    );
  }
}
