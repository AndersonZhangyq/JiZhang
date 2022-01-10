import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/loading.dart';
import 'package:ji_zhang/widget/transaction/modifyTransaction.dart';
import 'package:provider/provider.dart';

class SelectExpenseWidget extends StatefulWidget {
  const SelectExpenseWidget({Key? key, required this.budgetCategoryIds})
      : super(key: key);
  final List<int> budgetCategoryIds;

  @override
  _SelectExpenseWidgetState createState() => _SelectExpenseWidgetState();
}

class _SelectExpenseWidgetState extends State<SelectExpenseWidget> {
  late MyDatabase db;
  Set<int> selectedCategoryIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<MyDatabase>(context);
    selectedCategoryIds = Set<int>.from(widget.budgetCategoryIds);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryItem>>(
        stream: db.watchAllCategories(),
        // initialData: const <CategoryItem>[],
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final categories = snapshot.data!;
            categories.removeWhere((element) => element.type != "expense");
            return WillPopScope(
                onWillPop: () {
                  Navigator.of(context, rootNavigator: true)
                      .pop(selectedCategoryIds);
                  return Future<bool>.value(false);
                },
                child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                          AppLocalizations.of(context)!.selectExpense_Title),
                      leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pop(selectedCategoryIds);
                          }),
                    ),
                    body: Column(
                      children: [
                        Expanded(
                            child: ListView.builder(
                          itemBuilder: (context, index) {
                            final curCategory = categories[index];
                            return ListTile(
                              onTap: () {
                                if (selectedCategoryIds
                                    .contains(curCategory.id)) {
                                  setState(() {
                                    selectedCategoryIds.remove(curCategory.id);
                                  });
                                } else {
                                  setState(() {
                                    selectedCategoryIds.add(curCategory.id);
                                  });
                                }
                              },
                              leading: Icon(
                                curCategory.icon,
                                color: curCategory.color,
                              ),
                              title: Text(curCategory.getDisplayName(context)),
                              trailing:
                                  selectedCategoryIds.contains(curCategory.id)
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green[300],
                                        )
                                      : null,
                            );
                          },
                          itemCount: categories.length,
                        )),
                      ],
                    )));
          }
          return const LoadingWidget();
        });
  }
}
