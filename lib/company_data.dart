import 'app/config/company_config.dart';

class CompanyData {
  static final config = CompanyConfig.fromEnvironment();
  static String defaultPassword = 'qwertyuiop';
  static String defaultRole = 'employee';
  static DateTime get now => DateTime.now();
  static DateTime shiftStart(DateTime date) => config.shiftStart(date);
  static DateTime shiftEnd(DateTime date) => config.shiftEnd(date);
  static DateTime get onTimeIn => shiftStart(now);
  static DateTime get onTimeOut => shiftEnd(now);
  static Map<String, dynamic> get office => {
    'latitude': config.latitude,
    'longitude': config.longitude,
  };
}
