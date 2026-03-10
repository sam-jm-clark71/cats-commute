class AppSettings {
  final double rainThresholdPercent; // 0–100
  final double minCyclingTempC;
  final int cyclingMinutes;

  /// "Typical" work days — used to pre-populate the Sunday planning screen
  final bool typicalMonday;
  final bool typicalTuesday;
  final bool typicalThursday;

  final int morningNotifHour;
  final int morningNotifMinute;

  /// Evening notifications: Sunday planning + pre-office-day check-ins.
  /// Default 9pm.
  final int eveningNotifHour;
  final int eveningNotifMinute;

  final bool rideTrackingEnabled;

  final String openWeatherApiKey;

  const AppSettings({
    this.rainThresholdPercent = 30.0,
    this.minCyclingTempC = 7.0,
    this.cyclingMinutes = 40,
    this.typicalMonday = false,
    this.typicalTuesday = true,
    this.typicalThursday = true,
    this.morningNotifHour = 7,
    this.morningNotifMinute = 0,
    this.eveningNotifHour = 21,
    this.eveningNotifMinute = 0,
    this.rideTrackingEnabled = true,
    this.openWeatherApiKey = '',
  });

  AppSettings copyWith({
    double? rainThresholdPercent,
    double? minCyclingTempC,
    int? cyclingMinutes,
    bool? typicalMonday,
    bool? typicalTuesday,
    bool? typicalThursday,
    int? morningNotifHour,
    int? morningNotifMinute,
    int? eveningNotifHour,
    int? eveningNotifMinute,
    bool? rideTrackingEnabled,
    String? openWeatherApiKey,
  }) {
    return AppSettings(
      rainThresholdPercent: rainThresholdPercent ?? this.rainThresholdPercent,
      minCyclingTempC: minCyclingTempC ?? this.minCyclingTempC,
      cyclingMinutes: cyclingMinutes ?? this.cyclingMinutes,
      typicalMonday: typicalMonday ?? this.typicalMonday,
      typicalTuesday: typicalTuesday ?? this.typicalTuesday,
      typicalThursday: typicalThursday ?? this.typicalThursday,
      morningNotifHour: morningNotifHour ?? this.morningNotifHour,
      morningNotifMinute: morningNotifMinute ?? this.morningNotifMinute,
      eveningNotifHour: eveningNotifHour ?? this.eveningNotifHour,
      eveningNotifMinute: eveningNotifMinute ?? this.eveningNotifMinute,
      rideTrackingEnabled: rideTrackingEnabled ?? this.rideTrackingEnabled,
      openWeatherApiKey: openWeatherApiKey ?? this.openWeatherApiKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'rainThresholdPercent': rainThresholdPercent,
        'minCyclingTempC': minCyclingTempC,
        'cyclingMinutes': cyclingMinutes,
        'typicalMonday': typicalMonday,
        'typicalTuesday': typicalTuesday,
        'typicalThursday': typicalThursday,
        'morningNotifHour': morningNotifHour,
        'morningNotifMinute': morningNotifMinute,
        'eveningNotifHour': eveningNotifHour,
        'eveningNotifMinute': eveningNotifMinute,
        'rideTrackingEnabled': rideTrackingEnabled,
        'openWeatherApiKey': openWeatherApiKey,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        rainThresholdPercent:
            (json['rainThresholdPercent'] as num?)?.toDouble() ?? 30.0,
        minCyclingTempC:
            (json['minCyclingTempC'] as num?)?.toDouble() ?? 7.0,
        cyclingMinutes: json['cyclingMinutes'] as int? ?? 40,
        typicalMonday: json['typicalMonday'] as bool? ?? false,
        typicalTuesday: json['typicalTuesday'] as bool? ?? true,
        typicalThursday: json['typicalThursday'] as bool? ?? true,
        morningNotifHour: json['morningNotifHour'] as int? ?? 7,
        morningNotifMinute: json['morningNotifMinute'] as int? ?? 0,
        eveningNotifHour: json['eveningNotifHour'] as int? ?? 21,
        eveningNotifMinute: json['eveningNotifMinute'] as int? ?? 0,
        rideTrackingEnabled: json['rideTrackingEnabled'] as bool? ?? true,
        openWeatherApiKey: json['openWeatherApiKey'] as String? ?? '',
      );

  bool get isConfigured => openWeatherApiKey.isNotEmpty;
}
