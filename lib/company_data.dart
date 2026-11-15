class CompanyData {
  static String defaultPassword = 'qwertyuiop';
  static String defaultRole = 'employee';
  static DateTime get now => DateTime.now();
  static DateTime shiftStart(DateTime date) =>
      DateTime(date.year, date.month, date.day, 8);
  static DateTime shiftEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 16);
  static DateTime get onTimeIn => shiftStart(now);
  static DateTime get onTimeOut => shiftEnd(now);
  static Map<String, dynamic> office = {
    'latitude': -7.766026,
    'longitude': 110.371772,
  };
}
