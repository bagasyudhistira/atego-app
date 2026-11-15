import 'package:presence/company_data.dart';
import 'package:presence/app/config/company_config.dart';

enum AttendanceAction { none, checkIn, checkOut }

class AttendancePolicy {
  static AttendanceAction action({
    required DateTime now,
    required bool inArea,
    required bool hasCheckIn,
    required bool hasCheckOut,
    AttendanceAction? requestedAction,
    CompanyConfig? config,
  }) {
    if (requestedAction != null) {
      final allowed = action(
        now: now,
        inArea: inArea,
        hasCheckIn: hasCheckIn,
        hasCheckOut: hasCheckOut,
        config: config,
      );
      return allowed == requestedAction ? allowed : AttendanceAction.none;
    }
    if (hasCheckOut) return AttendanceAction.none;
    if (hasCheckIn) {
      final dayEnd = DateTime(now.year, now.month, now.day, 23, 59);
      return !inArea || !now.isBefore(dayEnd)
          ? AttendanceAction.checkOut
          : AttendanceAction.none;
    }
    final workday = (config ?? CompanyData.config).isWorkday(now);
    return inArea && workday ? AttendanceAction.checkIn : AttendanceAction.none;
  }

  static bool isOnTime(
    DateTime now,
    AttendanceAction action, {
    CompanyConfig? config,
  }) {
    final settings = config ?? CompanyData.config;
    final shiftStart = settings.shiftStart(now);
    final shiftEnd = settings.shiftEnd(now);
    switch (action) {
      case AttendanceAction.checkIn:
        return !now.isAfter(shiftStart);
      case AttendanceAction.checkOut:
        return !now.isBefore(shiftEnd);
      case AttendanceAction.none:
        return false;
    }
  }
}
