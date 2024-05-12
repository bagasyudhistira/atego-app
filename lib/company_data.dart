class CompanyData {
  static String defaultPassword = 'qwertyuiop';
  static String defaultRole = 'employee';
  static DateTime now = DateTime.now();
  static DateTime onTimeIn = DateTime(now.year, now.month, now.day, 8, 0);
  static DateTime onTimeOut = DateTime(now.year, now.month, now.day, 16, 0);
  static Map<String, dynamic> office = {
    'latitude': -7.766026,
    'longitude': 110.371772,
  };
}
