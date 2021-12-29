import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CategoryNameLocalizationHelper {
  static String getDisplayName(
      String categoryName, String categoryType, BuildContext context) {
    var table = AppLocalizations.of(context)!;
    String displayName;
    if (categoryType == "income")
      switch (categoryName) {
        case "Salary":
          displayName = table.category_Income_Salary;
          break;
        case "Business":
          displayName = table.category_Income_Business;
          break;
        case "Gifts":
          displayName = table.category_Income_Gifts;
          break;
        case "ExtraIncome":
          displayName = table.category_Income_ExtraIncome;
          break;
        case "Loan":
          displayName = table.category_Income_Loan;
          break;
        case "ParentalLeave":
          displayName = table.category_Income_ParentalLeave;
          break;
        case "InsurancePayout":
          displayName = table.category_Income_InsurancePayout;
          break;
        case "Other":
          displayName = table.category_Income_Other;
          break;
        default:
          throw UnimplementedError();
      }
    else {
      switch (categoryName) {
        case "Food":
          displayName = table.category_Expense_Food;
          break;
        case "Shopping":
          displayName = table.category_Expense_Shopping;
          break;
        case "Transport":
          displayName = table.category_Expense_Transport;
          break;
        case "Home":
          displayName = table.category_Expense_Home;
          break;
        case "Bills":
          displayName = table.category_Expense_Bills;
          break;
        case "Entertainment":
          displayName = table.category_Expense_Entertainment;
          break;
        case "Car":
          displayName = table.category_Expense_Car;
          break;
        case "Travel":
          displayName = table.category_Expense_Travel;
          break;
        case "Family":
          displayName = table.category_Expense_Family;
          break;
        case "Healthcare":
          displayName = table.category_Expense_Healthcare;
          break;
        case "Education":
          displayName = table.category_Expense_Education;
          break;
        case "Groceries":
          displayName = table.category_Expense_Groceries;
          break;
        case "Gifts":
          displayName = table.category_Expense_Gifts;
          break;
        case "Sports":
          displayName = table.category_Expense_Sports;
          break;
        case "Beauty":
          displayName = table.category_Expense_Beauty;
          break;
        case "Work":
          displayName = table.category_Expense_Work;
          break;
        case "Other":
          displayName = table.category_Expense_Other;
          break;
        default:
          throw UnimplementedError();
      }
    }
    return displayName;
  }
}
