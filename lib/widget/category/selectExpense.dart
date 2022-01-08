import 'package:flutter/material.dart';

class SelectExpenseWidget extends StatefulWidget {
  const SelectExpenseWidget({Key? key, required this.budgetCategoryIds})
      : super(key: key);
  final List<int> budgetCategoryIds;

  @override
  _SelectExpenseWidgetState createState() => _SelectExpenseWidgetState();
}

class _SelectExpenseWidgetState extends State<SelectExpenseWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
