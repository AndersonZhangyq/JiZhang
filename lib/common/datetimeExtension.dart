import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String format([String pattern = 'dd/MM/yyyy', String? locale]) {
    if (locale != null && locale.isNotEmpty) {
      initializeDateFormatting(locale);
    }
    return DateFormat(pattern, locale).format(this);
  }

  DateTime getDateOnly() {
    return DateTime(year, month, day);
  }

  DateTime getDateTillMonth() {
    return DateTime(year, month);
  }

  DateTime getDateTillYear() {
    return DateTime(year);
  }
}
