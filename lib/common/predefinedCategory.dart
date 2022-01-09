import 'package:flutter/material.dart';

final Map<String, Icon> expenseCategoryIconInfo = {
  "Food": const Icon(Icons.fastfood),
  "Shopping": const Icon(Icons.shopping_cart),
  "Transport": const Icon(Icons.airport_shuttle),
  "Home": const Icon(Icons.home),
  "Bills": const Icon(Icons.attach_money),
  "Entertainment": const Icon(Icons.videogame_asset),
  "Car": const Icon(Icons.directions_car),
  "Travel": const Icon(Icons.airplanemode_active),
  "Family": const Icon(Icons.people),
  "Healthcare": const Icon(Icons.local_hospital),
  "Education": const Icon(Icons.school),
  "Groceries": const Icon(Icons.local_grocery_store),
  "Gifts": const Icon(Icons.card_giftcard),
  "Sports": const Icon(Icons.directions_run),
  "Beauty": const Icon(Icons.face),
  "Work": const Icon(Icons.work),
  "Other": const Icon(Icons.more_horiz)
};

final Map<String, Color> expenseCategoryColorInfo = {
  "Food": Colors.orange,
  "Shopping": Colors.pink,
  "Transport": Colors.lime,
  "Home": Colors.brown,
  "Bills": Colors.green,
  "Entertainment": Colors.deepOrange,
  "Car": Colors.blue,
  "Travel": Colors.redAccent,
  "Family": Colors.blueGrey,
  "Healthcare": Colors.purple,
  "Education": Colors.amber,
  "Groceries": Colors.blueAccent,
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
