import 'package:flutter/material.dart';
import 'package:ji_zhang/models/categoryList.dart';
import 'package:provider/provider.dart';

import 'addTransaction.dart';

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
                  'Transaction Category',
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
                        GridView.count(
                            crossAxisCount: 4,
                            children: () {
                              List<Widget> list = [];
                              for (var value in expenseCategory) {
                                list.add(Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    )));
                              }
                              return list;
                            }()),
                        GridView.count(
                            crossAxisCount: 4,
                            children: () {
                              List<Widget> list = [];
                              for (var value in incomeCategory) {
                                list.add(Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        IconButton(
                                          padding: const EdgeInsets.all(0),
                                          icon: Icon(value.icon),
                                          onPressed: () {
                                            Navigator.pop(context, {
                                              'category': key,
                                              'icon': value.icon,
                                              'color': value.color,
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
                                    )));
                              }
                              return list;
                            }())
                      ],
                    );
                  },
                ))
              ],
            )));
  }
}
