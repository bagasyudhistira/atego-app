import 'package:presence/company_data.dart';

enum AttendanceAction { none, checkIn, checkOut }

class AttendancePolicy {
  static AttendanceAction action({
    required DateTime now,
    required bool inArea,
    required bool hasCheckIn,
    required bool hasCheckOut,
    AttendanceAction? requestedAction,
  }) {
    if (requestedAction != null) {
      final allowed = action(
        now: now,
        inArea: inArea,
        hasCheckIn: hasCheckIn,
        hasCheckOut: hasCheckOut,
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
    final weekday =
        now.weekday != DateTime.saturday && now.weekday != DateTime.sunday;
    return inArea && weekday ? AttendanceAction.checkIn : AttendanceAction.none;
  }

  static bool isOnTime(DateTime now, AttendanceAction action) {
    final shiftStart = CompanyData.shiftStart(now);
    final shiftEnd = CompanyData.shiftEnd(now);
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
