import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/common/predefinedRecurrence.dart';
import 'package:ji_zhang/models/database.dart';
import 'package:ji_zhang/widget/category/selectExpense.dart';
import 'package:ji_zhang/widget/moneyNumberTablet.dart';
import 'package:provider/provider.dart';

class ModifyBudgetPage extends StatefulWidget {
  const ModifyBudgetPage({Key? key, this.budget}) : super(key: key);
  final Budget? budget;

  @override
  _ModifyBudgetPageState createState() => _ModifyBudgetPageState();
}

class _ModifyBudgetPageState extends State<ModifyBudgetPage> {
  late MyDatabase db;
  late bool isAdd;
  late Color primaryColor;
  List<int> budgetCategoryIds = <int>[];
  late RECURRENCE_TYPE budgetRecurrence;
  late List<String> predefinedRecurrences;

  final TextEditingController budgetNameController = TextEditingController();

  final TextEditingController budgetAmountController =
      TextEditingController(text: "0");
  late List<int> categoryIds;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    predefinedRecurrences = getPredefinedRecurrences(context);
    if (null == widget.budget) {
      isAdd = true;
      budgetRecurrence = RECURRENCE_TYPE.monthly;
    } else {
      isAdd = false;
      budgetNameController.text = widget.budget!.name.toString();
      budgetAmountController.text = widget.budget!.amount.toStringAsFixed(2);
      budgetCategoryIds = widget.budget!.categoryIds;
      budgetRecurrence = widget.budget!.recurrence;
    }
    db = Provider.of<MyDatabase>(context);
    primaryColor = Theme.of(context).primaryColor;
    if (isAdd) budgetCategoryIds = categoryIds;
  }

  bool canSave() {
    return budgetAmountController.text.isNotEmpty &&
        0 != double.tryParse(budgetAmountController.text) &&
        budgetNameController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<List<int>?>(
        initialData: null,
        create: (_) async {
          return await (db.select(db.categories)
                ..where((tbl) => tbl.type.equals("expense")))
              .map((category) => category.id)
              .get();
        },
        child: Consumer<List<int>?>(builder: (_, value, __) {
          if (value == null) return Container();
          categoryIds = value;
          return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  centerTitle: true,
                  title: Text((isAdd
                          ? AppLocalizations.of(context)!.modifyBudget_Title_add
                          : AppLocalizations.of(context)!
                              .modifyBudget_Title_edit) +
                      AppLocalizations.of(context)!.modifyBudget_Title_budget),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(context);
                    },
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: canSave()
                          ? () async {
                              final amount =
                                  double.parse(budgetAmountController.text);
                              if (isAdd) {
                                int id = await db.into(db.budgets).insert(
                                    BudgetsCompanion.insert(
                                        name: budgetNameController.text,
                                        amount: amount,
                                        categoryIds: budgetCategoryIds,
                                        recurrence: budgetRecurrence));
                                if (0 == id) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(
                                              context)!
                                          .modifyBudget_SnackBar_failed_to_add_budget),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop(context);
                                }
                              } else {
                                bool ret = await db.update(db.budgets).replace(
                                    BudgetsCompanion(
                                        id: drift.Value(widget.budget!.id),
                                        name: drift.Value(
                                            budgetNameController.text),
                                        amount: drift.Value(amount),
                                        categoryIds:
                                            drift.Value(budgetCategoryIds),
                                        recurrence:
                                            drift.Value(budgetRecurrence)));
                                if (false == ret) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(
                                              context)!
                                          .modifyBudget_SnackBar_failed_to_update_budget),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop(context);
                                }
                              }
                            }
                          : null,
                    ),
                  ]),
              body: Column(
                children: [
                  Container(
                    color: primaryColor,
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextFormField(
                          controller: budgetAmountController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                          textAlign: TextAlign.end,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            // border: OutlineInputBorder(),
                            border: InputBorder.none,
                          ),
                          readOnly: true,
                        )),
                  ),
                  ListTile(
                    leading: Icon(Icons.description, color: primaryColor),
                    title: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: AppLocalizations.of(context)!
                            .modifyBudget_Budget_name_hint,
                      ),
                      controller: budgetNameController,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.label, color: primaryColor),
                    title: Text(
                        AppLocalizations.of(context)!.modifyBudget_Categories),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            budgetCategoryIds.length == categoryIds.length
                                ? AppLocalizations.of(context)!
                                    .modifyBudget_AllCategories
                                : budgetCategoryIds.length.toString(),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () async {
                      var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SelectExpenseWidget(
                                budgetCategoryIds: budgetCategoryIds)),
                      );
                      setState(() {
                        budgetCategoryIds = List.from(result);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.lock_clock, color: primaryColor),
                    title: Text(
                        AppLocalizations.of(context)!.modifyBudget_Recurrence),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(predefinedRecurrences[budgetRecurrence.index],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: SizedBox(
                                height: 240,
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .modifyBudget_Recurrence,
                                      textAlign: TextAlign.start,
                                      textScaleFactor: 1.5,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                          itemCount:
                                              predefinedRecurrences.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            bool selected =
                                                index == budgetRecurrence.index;
                                            return ListTile(
                                              onTap: () {
                                                Navigator.pop(context, {
                                                  'recurrence': RECURRENCE_TYPE
                                                      .values[index],
                                                });
                                              },
                                              selected: selected,
                                              title: Text(
                                                  predefinedRecurrences[index]),
                                              trailing: selected
                                                  ? const Icon(Icons
                                                      .check_circle_rounded)
                                                  : null,
                                            );
                                          }),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }).then((value) => null != value
                          ? setState(() {
                              budgetRecurrence = value['recurrence'];
                            })
                          : null);
                    },
                  ),
                  const Spacer(),
                  MoneyNumberTablet(
                    moneyController: budgetAmountController,
                    callback: (text) {
                      setState(() {
                        budgetAmountController.text = text;
                      });
                    },
                  )
                ],
              ));
        }));
  }
}
