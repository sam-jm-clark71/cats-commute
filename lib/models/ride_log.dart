class RideLog {
  final List<RideEntry> entries;

  const RideLog({this.entries = const []});

  /// Rolling average of the last [maxEntries] completed rides, in minutes.
  /// Returns null if there are no completed rides yet.
  double? get averageMinutes {
    final completed = entries.where((e) => e.durationMinutes != null).toList();
    if (completed.isEmpty) return null;
    final recent = completed.length > maxEntries
        ? completed.sublist(completed.length - maxEntries)
        : completed;
    final total = recent.fold<double>(
        0, (sum, e) => sum + e.durationMinutes!);
    return total / recent.length;
  }

  /// Number of completed rides used for the average
  int get completedCount =>
      entries.where((e) => e.durationMinutes != null).length;

  static const int maxEntries = 5;

  /// Add a new entry. If there's already an in-progress entry, complete it.
  RideLog withStarted(DateTime startTime) {
    // Discard any stale in-progress entry before starting a new one
    final clean = entries.where((e) => e.durationMinutes != null).toList();
    return RideLog(
      entries: [...clean, RideEntry(startTime: startTime)],
    );
  }

  RideLog withCompleted(DateTime endTime) {
    if (entries.isEmpty) return this;
    final last = entries.last;
    if (last.durationMinutes != null) return this; // already completed
    final duration = endTime.difference(last.startTime).inSeconds / 60.0;
    // Sanity check: ignore rides under 5 min or over 3 hours
    if (duration < 5 || duration > 180) {
      // Drop the bad entry
      return RideLog(entries: entries.sublist(0, entries.length - 1));
    }
    final updated = RideEntry(
      startTime: last.startTime,
      endTime: endTime,
      durationMinutes: duration,
    );
    return RideLog(
      entries: [...entries.sublist(0, entries.length - 1), updated],
    );
  }

  /// Returns the in-progress ride, if any.
  RideEntry? get inProgress {
    if (entries.isEmpty) return null;
    final last = entries.last;
    return last.durationMinutes == null ? last : null;
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory RideLog.fromJson(Map<String, dynamic> json) {
    final list = json['entries'] as List<dynamic>? ?? [];
    return RideLog(
      entries: list
          .map((e) => RideEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RideEntry {
  final DateTime startTime;
  final DateTime? endTime;
  final double? durationMinutes;

  const RideEntry({
    required this.startTime,
    this.endTime,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory RideEntry.fromJson(Map<String, dynamic> json) => RideEntry(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        durationMinutes: (json['durationMinutes'] as num?)?.toDouble(),
      );
}
