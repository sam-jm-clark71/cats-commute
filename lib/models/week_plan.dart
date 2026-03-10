/// A plan for a single office day
class DayPlan {
  final bool goingIn;
  final String? arrivalTime; // e.g. "08:30" — null if not going in
  final bool? openToCycling; // set during evening check-in

  const DayPlan({
    required this.goingIn,
    this.arrivalTime,
    this.openToCycling,
  });

  DayPlan copyWith({
    bool? goingIn,
    String? arrivalTime,
    bool? openToCycling,
  }) {
    return DayPlan(
      goingIn: goingIn ?? this.goingIn,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      openToCycling: openToCycling ?? this.openToCycling,
    );
  }

  Map<String, dynamic> toJson() => {
        'goingIn': goingIn,
        'arrivalTime': arrivalTime,
        'openToCycling': openToCycling,
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        goingIn: json['goingIn'] as bool? ?? false,
        arrivalTime: json['arrivalTime'] as String?,
        openToCycling: json['openToCycling'] as bool?,
      );

  static DayPlan notGoing() => const DayPlan(goingIn: false);
}

/// The full week's office plan, keyed by lowercase weekday name
class WeekPlan {
  /// ISO date string of the Monday that starts this week (e.g. "2025-03-10")
  final String weekStartDate;
  final Map<String, DayPlan> days;

  const WeekPlan({
    required this.weekStartDate,
    required this.days,
  });

  static const List<String> weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  DayPlan? dayPlan(DateTime date) {
    final key = _keyFor(date);
    return days[key];
  }

  bool isOfficeDay(DateTime date) => dayPlan(date)?.goingIn == true;

  String? arrivalTime(DateTime date) => dayPlan(date)?.arrivalTime;

  bool? openToCycling(DateTime date) => dayPlan(date)?.openToCycling;

  WeekPlan withDay(DateTime date, DayPlan plan) {
    final updated = Map<String, DayPlan>.from(days);
    updated[_keyFor(date)] = plan;
    return WeekPlan(weekStartDate: weekStartDate, days: updated);
  }

  static String _keyFor(DateTime date) {
    const keys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return keys[date.weekday - 1];
  }

  /// Returns the Monday date of the week containing [date]
  static DateTime mondayOf(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static String mondayKey(DateTime date) {
    final monday = mondayOf(date);
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  static WeekPlan empty(DateTime forDate) => WeekPlan(
        weekStartDate: mondayKey(forDate),
        days: {},
      );

  /// Pre-populate from typical work days (for Sunday planning screen)
  static WeekPlan fromTypical({
    required DateTime forDate,
    required bool monday,
    required bool tuesday,
    required bool thursday,
  }) {
    final days = <String, DayPlan>{};
    if (monday) days['monday'] = const DayPlan(goingIn: true, arrivalTime: '08:30');
    if (tuesday) days['tuesday'] = const DayPlan(goingIn: true, arrivalTime: '08:30');
    if (thursday) days['thursday'] = const DayPlan(goingIn: true, arrivalTime: '08:30');
    return WeekPlan(weekStartDate: mondayKey(forDate), days: days);
  }

  Map<String, dynamic> toJson() => {
        'weekStartDate': weekStartDate,
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as Map<String, dynamic>? ?? {};
    return WeekPlan(
      weekStartDate: json['weekStartDate'] as String? ?? '',
      days: daysJson.map(
        (k, v) => MapEntry(k, DayPlan.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}
