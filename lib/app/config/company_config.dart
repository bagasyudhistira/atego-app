class CompanyConfig {
  CompanyConfig({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required Set<int> workdays,
  }) : workdays = Set.unmodifiable(workdays) {
    if (name.trim().isEmpty ||
        !latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180 ||
        !radiusMetres.isFinite ||
        radiusMetres <= 0 ||
        startHour < 0 ||
        startHour > 23 ||
        endHour < 0 ||
        endHour > 23 ||
        startMinute < 0 ||
        startMinute > 59 ||
        endMinute < 0 ||
        endMinute > 59 ||
        startHour * 60 + startMinute >= endHour * 60 + endMinute ||
        workdays.isEmpty ||
        workdays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError(
        'Invalid company configuration. Check coordinates, radius, workdays, and same-day shift times.',
      );
    }
  }

  factory CompanyConfig.fromEnvironment() => CompanyConfig(
    name: const String.fromEnvironment('COMPANY_NAME', defaultValue: 'ATEGO'),
    latitude: double.parse(
      const String.fromEnvironment(
        'OFFICE_LATITUDE',
        defaultValue: '-7.766026',
      ),
    ),
    longitude: double.parse(
      const String.fromEnvironment(
        'OFFICE_LONGITUDE',
        defaultValue: '110.371772',
      ),
    ),
    radiusMetres: double.parse(
      const String.fromEnvironment('OFFICE_RADIUS_METRES', defaultValue: '200'),
    ),
    startHour: int.parse(
      const String.fromEnvironment('SHIFT_START_HOUR', defaultValue: '8'),
    ),
    startMinute: int.parse(
      const String.fromEnvironment('SHIFT_START_MINUTE', defaultValue: '0'),
    ),
    endHour: int.parse(
      const String.fromEnvironment('SHIFT_END_HOUR', defaultValue: '16'),
    ),
    endMinute: int.parse(
      const String.fromEnvironment('SHIFT_END_MINUTE', defaultValue: '0'),
    ),
    workdays: const String.fromEnvironment(
      'WORKDAYS',
      defaultValue: '1,2,3,4,5',
    ).split(',').map((day) => int.parse(day.trim())).toSet(),
  );

  final String name;
  final double latitude;
  final double longitude;
  final double radiusMetres;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final Set<int> workdays;

  bool isWorkday(DateTime date) => workdays.contains(date.weekday);
  DateTime shiftStart(DateTime date) =>
      DateTime(date.year, date.month, date.day, startHour, startMinute);
  DateTime shiftEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, endHour, endMinute);
}
