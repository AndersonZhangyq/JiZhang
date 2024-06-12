import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

class ModifyCategoryWidget extends StatefulWidget {
  const ModifyCategoryWidget({Key? key, this.category}) : super(key: key);
  final CategoryItem? category;

  @override
  State<StatefulWidget> createState() => _ModifyCategoryState();
}

class _ModifyCategoryState extends State<ModifyCategoryWidget> {
  final TextEditingController _categoryNameController = TextEditingController();
  ValueNotifier<String> categoryTypeNotifier = ValueNotifier<String>("expense");
  ValueNotifier<int> selectedIconIndexNotifier = ValueNotifier(-1);
  int? categoryParentId;
  // String categoryType = 'expense';
  Icon? categoryIcon;
  Color? categoryColor;
  // int selectedIconIndex = -1;
  Map<int, String> categoryIdName = {};
  late MyDatabase db;
  late String title;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.category != null) {
      _categoryNameController.text = widget.category!.getTrueName(context);
      categoryTypeNotifier.value = widget.category!.type;
      categoryParentId = widget.category!.parentId;
      categoryIcon = Icon(widget.category!.icon, color: widget.category!.color);
      categoryColor = widget.category!.color;
      title = AppLocalizations.of(context)!.modifyCategory_Title_edit +
          AppLocalizations.of(context)!.modifyCategory_Title_Category;
    } else {
      title = AppLocalizations.of(context)!.modifyCategory_Title_add +
          AppLocalizations.of(context)!.modifyCategory_Title_Category;
    }
    db = Provider.of<MyDatabase>(context);
  }

  bool canSave() {
    if (_categoryNameController.text == "Other") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .modifyCategory_SnackBar_preserved_name_used)));
      return false;
    }
    return _categoryNameController.text.isNotEmpty &&
        categoryTypeNotifier.value.isNotEmpty &&
        selectedIconIndexNotifier.value != -1 &&
        categoryIcon != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(context);
              }),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                if (canSave()) {
                  int? lastPos = await db
                      .getCategoryLastPosByType(categoryTypeNotifier.value);
                  if (lastPos != null) {
                    int categoryPos = lastPos + 1;
                    String? categoryParentName;
                    if (categoryParentId != null) {
                      categoryParentName = categoryIdName[categoryParentId];
                    }
                    if (widget.category != null) {
                      bool ret = await db.update(db.categories).replace(
                          CategoriesCompanion(
                              id: drift.Value(widget.category!.id),
                              name: drift.Value(_categoryNameController.text),
                              type: drift.Value(categoryTypeNotifier.value),
                              icon: drift.Value(jsonEncode({
                                "codePoint": categoryIcon!.icon!.codePoint,
                                "fontFamily": categoryIcon!.icon!.fontFamily,
                                "fontPackage": categoryIcon!.icon!.fontPackage
                              })),
                              color:
                                  drift.Value(categoryColor!.value.toString()),
                              pos: drift.Value(widget.category!.pos),
                              predefined:
                                  drift.Value(widget.category!.predefined),
                              parentId:
                                  drift.Value.absentIfNull(categoryParentId),
                              parentName:
                                  drift.Value.absentIfNull(categoryParentName),
                              accountId:
                                  drift.Value(widget.category!.accountId)));
                      if (ret) {
                        Navigator.of(context, rootNavigator: true).pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .modifyCategory_SnackBar_failed_to_modify_category)));
                      }
                    } else {
                      int id = await db.into(db.categories).insert(
                          CategoriesCompanion.insert(
                              name: _categoryNameController.text,
                              type: categoryTypeNotifier.value,
                              icon: jsonEncode({
                                "codePoint": categoryIcon!.icon!.codePoint,
                                "fontFamily": categoryIcon!.icon!.fontFamily,
                                "fontPackage": categoryIcon!.icon!.fontPackage
                              }),
                              parentId:
                                  drift.Value.absentIfNull(categoryParentId),
                              parentName:
                                  drift.Value.absentIfNull(categoryParentName),
                              color: categoryColor!.value.toString(),
                              pos: categoryPos,
                              predefined: 0,
                              accountId: db.currentAccountId));
                      if (id > 0) {
                        Navigator.of(context, rootNavigator: true).pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .modifyCategory_SnackBar_failed_to_add_category)));
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(AppLocalizations.of(context)!
                            .modifyCategory_SnackBar_failed_to_get_last_pos)));
                  }
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
            child: StreamBuilder<List<CategoryItem>>(
                stream: db.watchAllCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData) {
                    return Container();
                  }
                  final categories = snapshot.data ?? <CategoryItem>[];
                  List<CategoryItem> categoryItems = [];
                  Set<int> iconCodePoint = {};
                  for (var item in categories) {
                    categoryIdName[item.id] = item.name;
                    if (!iconCodePoint.contains(item.icon.codePoint)) {
                      iconCodePoint.add(item.icon.codePoint);
                      categoryItems.add(item);
                      if (widget.category != null &&
                          widget.category!.icon == item.icon) {
                        selectedIconIndexNotifier.value =
                            categoryItems.length - 1;
                      }
                    }
                  }
                  return ValueListenableBuilder(
                    valueListenable: categoryTypeNotifier,
                    builder: (context, categoryType, _) {
                      categoryParentId = null;
                      return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _categoryNameController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: AppLocalizations.of(context)!
                                          .modifyCategory_Form_CategoryName,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: AppLocalizations.of(context)!
                                        .modifyCategory_Form_CategoryName),
                                // 设置默认值
                                value: 'expense',
                                // 选择回调
                                onChanged: (String? value) {
                                  categoryTypeNotifier.value = value!;
                                },
                                // 传入可选的数组
                                items: ["Expense", "Income"].map((String type) {
                                  return DropdownMenuItem(
                                      value: type.toLowerCase(),
                                      child: Text(type == "Expense"
                                          ? AppLocalizations.of(context)!
                                              .tab_Expense
                                          : AppLocalizations.of(context)!
                                              .tab_Income));
                                }).toList(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: categoryType == 'expense'
                                  ? (widget.category != null &&
                                          widget.category!.parentId != null
                                      ? DropdownButtonFormField<String>(
                                          key: UniqueKey(),
                                          isExpanded: true,
                                          value: widget.category!.parentId
                                              .toString(),
                                          decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: AppLocalizations.of(
                                                      context)!
                                                  .modifyCategory_Form_CategoryParentName),
                                          // 选择回调
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              categoryParentId =
                                                  int.parse(value);
                                            }
                                          },
                                          // 传入可选的数组
                                          items: categories
                                              .where((element) =>
                                                  element.type == 'expense' &&
                                                  element.parentId == null)
                                              .map((element) {
                                            return DropdownMenuItem(
                                                value: element.id.toString(),
                                                child: Text(element
                                                    .getDisplayName(context)));
                                          }).toList(),
                                        )
                                      : DropdownButtonFormField<String>(
                                          key: UniqueKey(),
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: AppLocalizations.of(
                                                      context)!
                                                  .modifyCategory_Form_CategoryParentName),
                                          // 选择回调
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              categoryParentId =
                                                  int.parse(value);
                                            }
                                          },
                                          // 传入可选的数组
                                          items: categories
                                              .where((element) =>
                                                  element.type == 'expense' &&
                                                  element.parentId == null)
                                              .map((element) {
                                            return DropdownMenuItem(
                                                value: element.id.toString(),
                                                child: Text(element
                                                    .getDisplayName(context)));
                                          }).toList(),
                                        ))
                                  : DropdownButtonFormField<String>(
                                      key: UniqueKey(),
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: AppLocalizations.of(
                                                  context)!
                                              .modifyCategory_Form_CategoryParentName),
                                      // 选择回调
                                      onChanged: (String? value) {
                                        if (value != null) {
                                          categoryParentId = int.parse(value);
                                        }
                                      },
                                      // 传入可选的数组
                                      items: categories
                                          .where((element) =>
                                              element.type == 'income' &&
                                              element.parentId == null)
                                          .map((element) {
                                        return DropdownMenuItem(
                                            value: element.id.toString(),
                                            child: Text(element
                                                .getDisplayName(context)));
                                      }).toList(),
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .modifyCategory_Form_CategoryIcon,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                                child: ValueListenableBuilder(
                                    valueListenable: selectedIconIndexNotifier,
                                    builder: (context, selectedIconIndex, _) {
                                      return GridView.builder(
                                          itemCount: categoryItems.length,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisSpacing: 2,
                                                  mainAxisSpacing: 2,
                                                  crossAxisCount: 5),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            var value = categoryItems[index];
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                DottedBorder(
                                                  color: selectedIconIndex ==
                                                          index
                                                      ? Colors.red
                                                      : Colors
                                                          .transparent, //color of dotted/dash line
                                                  strokeWidth:
                                                      1, //thickness of das
                                                  dashPattern: const [3, 6],
                                                  borderType: BorderType.Circle,
                                                  child: IconButton(
                                                    padding:
                                                        const EdgeInsets.all(0),
                                                    icon: Icon(value.icon),
                                                    onPressed: () {
                                                      categoryIcon =
                                                          Icon(value.icon);
                                                      categoryColor =
                                                          value.color;
                                                      selectedIconIndexNotifier
                                                          .value = index;
                                                    },
                                                    color: value.color,
                                                  ),
                                                ),
                                              ],
                                            );
                                          });
                                    }))
                          ]);
                    },
                  );
                }),
          ),
        ));
  }
}
