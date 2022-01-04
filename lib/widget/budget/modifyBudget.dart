import 'package:flutter/material.dart';
import 'package:ji_zhang/models/database.dart';

class ModifyBudgetPage extends StatefulWidget {
  const ModifyBudgetPage({Key? key, this.budget}) : super(key: key);
  final Budget? budget;

  @override
  _ModifyBudgetPageState createState() => _ModifyBudgetPageState();
}

class _ModifyBudgetPageState extends State<ModifyBudgetPage> {
  late MyDatabase db;
  late bool isAdd;

  @override
  void initState() {
    super.initState();
    if (null == widget.budget) {
      isAdd = true;
    } else {
      setState(() {
        isAdd = false;
        // moneyController.text = widget.budget!.money.toStringAsFixed(2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
