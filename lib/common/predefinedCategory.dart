import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';

final Map<String, Icon> expenseCategoryIconInfo = {
  "Food": const Icon(MaterialCommunityIcons.silverware_fork_knife),
  "Food_Weekday": const Icon(MaterialCommunityIcons.silverware_fork_knife),
  "Shopping": const Icon(Icons.shopping_cart),
  "Shopping_Family": const Icon(Icons.shopping_cart),
  "Transport": const Icon(Icons.airport_shuttle),
  "Home": const Icon(Icons.home),
  "Bills": const Icon(Icons.payments),
  "Entertainment": const Icon(Entypo.game_controller),
  "Car": const Icon(Icons.directions_car),
  "Travel": const Icon(FontAwesome.plane),
  "Friends": const Icon(Icons.people),
  "Healthcare": const Icon(Icons.local_hospital),
  "Education": const Icon(Icons.school),
  "Gifts": const Icon(Icons.card_giftcard),
  "Sports": const Icon(Icons.directions_run),
  "Beauty": const Icon(Icons.face),
  "Work": const Icon(Icons.work),
  "Other": const Icon(Icons.more_horiz)
};

final Map<String, Color> expenseCategoryColorInfo = {
  "Food": Colors.orange,
  "Food_Weekday": Colors.orange,
  "Shopping": Colors.pink,
  "Shopping_Family": Colors.pink,
  "Transport": Colors.lime,
  "Home": Colors.brown,
  "Bills": Colors.green,
  "Entertainment": Colors.deepOrange,
  "Car": Colors.blue,
  "Travel": Colors.redAccent,
  "Friends": Colors.blueGrey,
  "Healthcare": Colors.purple,
  "Education": Colors.amber,
  "Gifts": Colors.greenAccent,
  "Sports": Colors.lightGreen,
  "Beauty": Colors.purpleAccent,
  "Work": Colors.grey,
  "Other": Colors.grey,
};

final Map<String, Icon> incomeCategoryIconInfo = {
  "Salary": const Icon(Icons.attach_money),
  "Business": const Icon(Icons.business),
  "Gifts": const Icon(Icons.card_giftcard),
  "ExtraIncome": const Icon(Icons.money_sharp),
  "Loan": const Icon(Icons.wallet_giftcard),
  "ParentalLeave": const Icon(Icons.people),
  "InsurancePayout": const Icon(Icons.local_hospital),
  "Other": const Icon(Icons.more_horiz)
};

final Map<String, Color> incomeCategoryColorInfo = {
  "Salary": Colors.green,
  "Business": Colors.orange,
  "Gifts": Colors.greenAccent,
  "ExtraIncome": Colors.lightGreen,
  "Loan": Colors.pinkAccent,
  "ParentalLeave": Colors.pink,
  "InsurancePayout": Colors.blueAccent,
  "Other": Colors.grey
};
