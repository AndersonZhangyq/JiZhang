import 'package:flutter/material.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:provider/provider.dart';

import 'modifyTransaction.dart';

class CategorySelectorWidget extends StatelessWidget {
  const CategorySelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Select Transaction Category',
                  textAlign: TextAlign.start,
                  textScaleFactor: 1.5,
                ),
                const TabBar(
                  labelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Expense"),
                    Tab(text: "Income"),
                  ],
                ),
                Expanded(child: Consumer<CategoryList>(
                  builder: (context, value, child) {
                    List<CategoryItem> expenseCategory = [];
                    List<CategoryItem> incomeCategory = [];
                    for (var item in value.items) {
                      if (item.type == "expense") {
                        expenseCategory.add(item);
                      } else {
                        incomeCategory.add(item);
                      }
                    }
                    return TabBarView(
                      children: [
                        GridView.builder(
                            itemCount: expenseCategory.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                    crossAxisCount: 4),
                            itemBuilder: (BuildContext context, int index) {
                              var value = expenseCategory[index];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  IconButton(
                                    padding: const EdgeInsets.all(0),
                                    icon: Icon(value.icon),
                                    onPressed: () {
                                      Navigator.pop(context, {
                                        "category": value.name,
                                        'icon': value.icon,
                                        "color": value.color,
                                        "id": value.id
                                      });
                                    },
                                    color: value.color,
                                  ),
                                  Text(
                                    value.name,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ],
                              );
                            }),
                        GridView.builder(
                            itemCount: incomeCategory.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 2,
                                    crossAxisCount: 4),
                            itemBuilder: (BuildContext context, int index) {
                              var value = incomeCategory[index];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  IconButton(
                                    padding: const EdgeInsets.all(0),
                                    icon: Icon(value.icon),
                                    onPressed: () {
                                      Navigator.pop(context, {
                                        'category': key,
                                        'icon': value.icon,
                                        'color': value.color,
                                        "id": value.id
                                      });
                                    },
                                    color: value.color,
                                  ),
                                  Text(
                                    value.name,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ],
                              );
                            })
                      ],
                    );
                  },
                ))
              ],
            )));
  }
}
