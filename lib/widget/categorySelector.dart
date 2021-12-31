import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/dbProxy/index.dart';
import 'package:ji_zhang/widget/modifyCategory.dart';
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
                Text(
                  AppLocalizations.of(context)!.categorySelector_Title,
                  textAlign: TextAlign.start,
                  textScaleFactor: 1.5,
                ),
                TabBar(
                  labelColor: Colors.grey,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.tab_Expense),
                    Tab(text: AppLocalizations.of(context)!.tab_Income),
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
                        _buildExpenseCategory(expenseCategory),
                        _buildIncomeCategory(incomeCategory)
                      ],
                    );
                  },
                ))
              ],
            )));
  }

  GridView _buildIncomeCategory(List<CategoryItem> incomeCategory) {
    return GridView.builder(
        itemCount: incomeCategory.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: 2, mainAxisSpacing: 2, crossAxisCount: 4),
        itemBuilder: (BuildContext context, int index) {
          if (index == incomeCategory.length) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  padding: const EdgeInsets.all(0),
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // open category settings
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ModifyCategoryWidget(tabName: "income")),
                    );
                  },
                  color: Colors.black,
                ),
                Text(
                  AppLocalizations.of(context)!.categorySelector_LastListItem,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            );
          }
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
                value.getDisplayName(context),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          );
        });
  }

  GridView _buildExpenseCategory(List<CategoryItem> expenseCategory) {
    return GridView.builder(
        itemCount: expenseCategory.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: 2, mainAxisSpacing: 2, crossAxisCount: 4),
        itemBuilder: (BuildContext context, int index) {
          if (index == expenseCategory.length) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  padding: const EdgeInsets.all(0),
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // open category settings
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ModifyCategoryWidget(tabName: "expense")),
                    );
                  },
                  color: Colors.black,
                ),
                Text(
                  AppLocalizations.of(context)!.categorySelector_LastListItem,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ],
            );
          }
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
                value.getDisplayName(context),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          );
        });
  }
}
