import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ji_zhang/models/database.dart';

class CustomDatePickerDialog extends StatefulWidget {
  final List<int> disabledMonths;
  final Function(bool, Map<String, int>)
      onConfirm; // callback to pass selection info
  final MyDatabase db;

  CustomDatePickerDialog({
    Key? key,
    required this.disabledMonths,
    required this.onConfirm,
    required this.db,
  }) : super(key: key);

  @override
  _CustomDatePickerDialogState createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog>
    with TickerProviderStateMixin {
  bool byMonth = true;
  int selectedYear = DateTime.now().year;
  int? selectedMonth;
  int? selectedYearInTable;
  int yearStart = DateTime.now().year ~/ 10 * 10;

  void _incrementYear() {
    setState(() {
      selectedYear++;
    });
  }

  void _decrementYear() {
    setState(() {
      selectedYear--;
    });
  }

  void _confirmSelection() {
    if (byMonth && selectedMonth != null) {
      widget.onConfirm(true, {'year': selectedYear, 'month': selectedMonth!});
    } else if (!byMonth && selectedYearInTable != null) {
      widget.onConfirm(false, {'year': selectedYearInTable!});
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FractionallySizedBox(
              heightFactor: 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TabBar(
                    onTap: (index) => {byMonth = index == 0},
                    labelColor: Colors.black,
                    tabs: [
                      Tab(
                          text: AppLocalizations.of(context)!
                              .monthYearPicker_byMonth),
                      Tab(
                          text: AppLocalizations.of(context)!
                              .monthYearPicker_byYear),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TabBarView(
                        children: [
                          _buildMonthSelector(),
                          _buildYearSelector(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: _confirmSelection,
                            child: Text(AppLocalizations.of(context)!.confirm))
                      ],
                    ),
                  )
                ],
              ),
            )));
  }

  Widget _buildMonthSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: _decrementYear,
            ),
            Text('$selectedYear'),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: _incrementYear,
            ),
          ],
        ),
        Expanded(child: _buildMonthTable())
      ],
    );
  }

  Widget _buildMonthTable() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        crossAxisCount: 4,
      ),
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        int month = index + 1;
        bool isDisabled = widget.disabledMonths.contains(month);
        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    selectedMonth = month;
                  });
                },
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey
                  : (selectedMonth == month
                      ? Colors.blue[100]
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              month < 10 ? '0$month' : month.toString(),
              style: TextStyle(
                color: isDisabled ? Colors.black54 : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearSelector() {
    List<Widget> yearWidgets = [];
    for (int year = yearStart; year <= yearStart + 11; year++) {
      yearWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedYearInTable = year;
            });
          },
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: selectedYearInTable == year
                  ? Colors.blue[100]
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              year.toString(),
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_left),
            onPressed: () {
              setState(() {
                yearStart -= 12;
              });
            },
          ),
          Text(AppLocalizations.of(context)!.monthYearPicker_bottomSheet_title),
          IconButton(
            icon: Icon(Icons.arrow_right),
            onPressed: () {
              setState(() {
                yearStart += 12;
              });
            },
          ),
        ],
      ),
      Expanded(
          child: GridView.count(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        crossAxisCount: 4,
        children: yearWidgets,
      ))
    ]);
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
