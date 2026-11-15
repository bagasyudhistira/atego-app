import 'package:flutter_test/flutter_test.dart';
import 'package:presence/app/controllers/attendance_policy.dart';

void main() {
  test('only checks in on weekdays inside the office', () {
    for (final day in [DateTime(2026, 11, 16), DateTime(2026, 11, 21)]) {
      for (final inArea in [true, false]) {
        expect(
          AttendancePolicy.action(
            now: day,
            inArea: inArea,
            hasCheckIn: false,
            hasCheckOut: false,
          ),
          day.weekday == DateTime.monday && inArea
              ? AttendanceAction.checkIn
              : AttendanceAction.none,
        );
      }
    }
  });

  test('checks out only after entry and when leaving or reaching day end', () {
    expect(
      AttendancePolicy.action(
        now: DateTime(2026, 11, 16, 16),
        inArea: true,
        hasCheckIn: true,
        hasCheckOut: false,
      ),
      AttendanceAction.none,
    );
    for (final inArea in [true, false]) {
      expect(
        AttendancePolicy.action(
          now: DateTime(2026, 11, 16, 23, 59),
          inArea: inArea,
          hasCheckIn: true,
          hasCheckOut: false,
        ),
        AttendanceAction.checkOut,
      );
    }
    expect(
      AttendancePolicy.action(
        now: DateTime(2026, 11, 16, 12),
        inArea: false,
        hasCheckIn: true,
        hasCheckOut: false,
      ),
      AttendanceAction.checkOut,
    );
  });

  test('completed attendance does not produce another event', () {
    for (final inArea in [true, false]) {
      expect(
        AttendancePolicy.action(
          now: DateTime(2026, 11, 16, 23, 59),
          inArea: inArea,
          hasCheckIn: true,
          hasCheckOut: true,
        ),
        AttendanceAction.none,
      );
    }
  });

  test('shift boundaries are inclusive and recalculated after midnight', () {
    for (final day in [16, 17]) {
      expect(
          AttendancePolicy.isOnTime(
              DateTime(2026, 11, day, 8), AttendanceAction.checkIn),
          isTrue);
      expect(
          AttendancePolicy.isOnTime(
              DateTime(2026, 11, day, 8, 1), AttendanceAction.checkIn),
          isFalse);
      expect(
          AttendancePolicy.isOnTime(
              DateTime(2026, 11, day, 15, 59), AttendanceAction.checkOut),
          isFalse);
      expect(
          AttendancePolicy.isOnTime(
              DateTime(2026, 11, day, 16), AttendanceAction.checkOut),
          isTrue);
      expect(
          AttendancePolicy.isOnTime(
              DateTime(2026, 11, day, 17), AttendanceAction.checkOut),
          isTrue);
    }
  });
}
