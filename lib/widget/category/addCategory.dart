import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';

class AddCategoryWidget extends StatefulWidget {
  const AddCategoryWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategoryWidget> {
  final TextEditingController _categoryNameController = TextEditingController();
  String categoryType = 'expense';
  Icon? categoryIcon;
  Color? categoryColor;
  int selectedIconIndex = -1;
  late MyDatabase db;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
  }

  bool canSave() {
    return _categoryNameController.text.isNotEmpty &&
        categoryType.isNotEmpty &&
        selectedIconIndex != -1 &&
        categoryIcon != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Add Category"),
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
                  int? lastPos =
                      await db.getCategoryLastPosByType(categoryType);
                  if (lastPos != null) {
                    int categoryPos = lastPos + 1;
                    int id = await db
                        .into(db.categories)
                        .insert(CategoriesCompanion.insert(
                            name: _categoryNameController.text,
                            type: categoryType,
                            icon: jsonEncode({
                              "codePoint": categoryIcon!.icon!.codePoint,
                              "fontFamily": categoryIcon!.icon!.fontFamily,
                              "fontPackage": categoryIcon!.icon!.fontPackage
                            }),
                            color: categoryColor!.value.toString(),
                            pos: categoryPos,
                            predefined: 0));
                    if (id > 0) {
                      Navigator.of(context, rootNavigator: true).pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to save.')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Failed to get the last position of the category.')));
                  }
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _categoryNameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Category Name',
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Category Type'),
                    // 设置默认值
                    value: 'expense',
                    // 选择回调
                    onChanged: (String? value) {
                      setState(() {
                        categoryType = value!;
                      });
                    },
                    // 传入可选的数组
                    items: ["Expense", "Income"].map((String type) {
                      return DropdownMenuItem(
                          value: type.toLowerCase(), child: Text(type));
                    }).toList(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Category Icon',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<CategoryItem>>(
                      stream: db.watchAllCategories(),
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? <CategoryItem>[];
                        List<CategoryItem> categoryItems = [];
                        Set<int> iconCodePoint = {};
                        for (var item in categories) {
                          if (!iconCodePoint.contains(item.icon.codePoint)) {
                            iconCodePoint.add(item.icon.codePoint);
                            categoryItems.add(item);
                          }
                        }
                        return GridView.builder(
                            itemCount: categoryItems.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                    crossAxisCount: 5),
                            itemBuilder: (BuildContext context, int index) {
                              var value = categoryItems[index];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  DottedBorder(
                                    color: selectedIconIndex == index
                                        ? Colors.red
                                        : Colors
                                            .transparent, //color of dotted/dash line
                                    strokeWidth: 1, //thickness of das
                                    dashPattern: const [3, 6],
                                    borderType: BorderType.Circle,
                                    child: IconButton(
                                      padding: const EdgeInsets.all(0),
                                      icon: Icon(value.icon),
                                      onPressed: () {
                                        setState(() {
                                          categoryIcon = Icon(value.icon);
                                          categoryColor = value.color;
                                          selectedIconIndex = index;
                                        });
                                      },
                                      color: value.color,
                                    ),
                                  ),
                                ],
                              );
                            });
                      }),
                )
              ],
            ),
          ),
        ));
  }
}
