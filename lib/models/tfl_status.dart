enum TflSeverity { goodService, minorDelays, severeDelays, partSuspended, suspended, unknown }

class TflLineStatus {
  final TflSeverity severity;
  final String statusDescription;
  final String? disruption;

  const TflLineStatus({
    required this.severity,
    required this.statusDescription,
    this.disruption,
  });

  bool get isGood => severity == TflSeverity.goodService;
  bool get isSevere =>
      severity == TflSeverity.severeDelays ||
      severity == TflSeverity.partSuspended ||
      severity == TflSeverity.suspended;

  factory TflLineStatus.fromJson(Map<String, dynamic> json) {
    final lineStatuses = json['lineStatuses'] as List<dynamic>? ?? [];
    if (lineStatuses.isEmpty) {
      return const TflLineStatus(
        severity: TflSeverity.unknown,
        statusDescription: 'Status unknown',
      );
    }

    final first = lineStatuses.first as Map<String, dynamic>;
    final severityCode = first['statusSeverity'] as int? ?? 0;
    final statusDesc = first['statusSeverityDescription'] as String? ?? 'Unknown';
    final disruptionData = first['disruption'] as Map<String, dynamic>?;
    final disruptionDesc = disruptionData?['description'] as String?;

    TflSeverity sev;
    switch (severityCode) {
      case 10:
        sev = TflSeverity.goodService;
        break;
      case 9:
      case 8:
        sev = TflSeverity.minorDelays;
        break;
      case 5:
      case 6:
        sev = TflSeverity.severeDelays;
        break;
      case 4:
        sev = TflSeverity.partSuspended;
        break;
      case 0:
        sev = TflSeverity.suspended;
        break;
      default:
        sev = severityCode > 8 ? TflSeverity.goodService : TflSeverity.minorDelays;
    }

    return TflLineStatus(
      severity: sev,
      statusDescription: statusDesc,
      disruption: disruptionDesc,
    );
  }

  static TflLineStatus unknown() => const TflLineStatus(
        severity: TflSeverity.unknown,
        statusDescription: 'Status unavailable',
      );
}
