import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

List<String> getPredefinedRecurrences(BuildContext context) {
  return [
    AppLocalizations.of(context)!.recurrence_Yearly,
    AppLocalizations.of(context)!.recurrence_Monthly,
    AppLocalizations.of(context)!.recurrence_BiWeekly,
    AppLocalizations.of(context)!.recurrence_Weekly,
    AppLocalizations.of(context)!.recurrence_Daily
  ];
}

enum RECURRENCE_TYPE {
  yearly,
  monthly,
  biweekly,
  weekly,
  daily,
}
