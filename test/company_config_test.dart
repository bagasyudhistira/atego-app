import 'package:flutter_test/flutter_test.dart';
import 'package:presence/app/config/company_config.dart';
import 'package:presence/app/controllers/attendance_policy.dart';

CompanyConfig settings({
  String name = 'Test office',
  double latitude = 0,
  double longitude = 0,
  double radius = 350,
  int startHour = 9,
  int startMinute = 30,
  int endHour = 18,
  int endMinute = 15,
  Set<int> workdays = const {6, 7},
}) => CompanyConfig(
  name: name,
  latitude: latitude,
  longitude: longitude,
  radiusMetres: radius,
  startHour: startHour,
  startMinute: startMinute,
  endHour: endHour,
  endMinute: endMinute,
  workdays: workdays,
);

void main() {
  test('loads compiled company settings from Dart defines', () {
    final config = CompanyConfig.fromEnvironment();
    expect(
      config.name,
      const String.fromEnvironment('COMPANY_NAME', defaultValue: 'ATEGO'),
    );
    expect(
      config.latitude,
      double.parse(
        const String.fromEnvironment(
          'OFFICE_LATITUDE',
          defaultValue: '-7.766026',
        ),
      ),
    );
    expect(
      config.longitude,
      double.parse(
        const String.fromEnvironment(
          'OFFICE_LONGITUDE',
          defaultValue: '110.371772',
        ),
      ),
    );
    expect(
      config.radiusMetres,
      double.parse(
        const String.fromEnvironment(
          'OFFICE_RADIUS_METRES',
          defaultValue: '200',
        ),
      ),
    );
    expect(
      config.shiftStart(DateTime(2026, 11, 21)),
      DateTime(
        2026,
        11,
        21,
        int.parse(
          const String.fromEnvironment('SHIFT_START_HOUR', defaultValue: '8'),
        ),
        int.parse(
          const String.fromEnvironment('SHIFT_START_MINUTE', defaultValue: '0'),
        ),
      ),
    );
    expect(
      config.workdays,
      const String.fromEnvironment(
        'WORKDAYS',
        defaultValue: '1,2,3,4,5',
      ).split(',').map(int.parse).toSet(),
    );
  });

  test('rejects invalid deployment settings, including overnight shifts', () {
    for (final build in <CompanyConfig Function()>[
      () => settings(name: ' '),
      () => settings(latitude: 91),
      () => settings(latitude: double.nan),
      () => settings(longitude: -181),
      () => settings(radius: 0),
      () => settings(radius: double.infinity),
      () => settings(startHour: -1),
      () => settings(endHour: 24),
      () => settings(startMinute: 60),
      () => settings(endMinute: -1),
      () => settings(startHour: 20),
      () => settings(startHour: 18, startMinute: 15),
      () => settings(workdays: {}),
      () => settings(workdays: {0, 8}),
    ]) {
      expect(build, throwsArgumentError);
    }
  });

  test('configured workdays apply to automatic and manual attendance', () {
    final config = settings();
    for (final date in [DateTime(2026, 11, 16), DateTime(2026, 11, 21)]) {
      for (final request in [null, AttendanceAction.checkIn]) {
        expect(
          AttendancePolicy.action(
            now: date,
            inArea: true,
            hasCheckIn: false,
            hasCheckOut: false,
            requestedAction: request,
            config: config,
          ),
          date.weekday == DateTime.saturday
              ? AttendanceAction.checkIn
              : AttendanceAction.none,
        );
      }
    }
    expect(
      AttendancePolicy.action(
        now: DateTime(2026, 11, 16),
        inArea: false,
        hasCheckIn: true,
        hasCheckOut: false,
        config: config,
      ),
      AttendanceAction.checkOut,
    );
  });

  test(
    'custom minute-level shift boundaries remain inclusive across dates',
    () {
      final config = settings();
      for (final day in [21, 22]) {
        expect(
          AttendancePolicy.isOnTime(
            DateTime(2026, 11, day, 9, 30),
            AttendanceAction.checkIn,
            config: config,
          ),
          isTrue,
        );
        expect(
          AttendancePolicy.isOnTime(
            DateTime(2026, 11, day, 9, 31),
            AttendanceAction.checkIn,
            config: config,
          ),
          isFalse,
        );
        expect(
          AttendancePolicy.isOnTime(
            DateTime(2026, 11, day, 18, 14),
            AttendanceAction.checkOut,
            config: config,
          ),
          isFalse,
        );
        expect(
          AttendancePolicy.isOnTime(
            DateTime(2026, 11, day, 18, 15),
            AttendanceAction.checkOut,
            config: config,
          ),
          isTrue,
        );
      }
    },
  );
}
