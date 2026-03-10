import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/week_plan.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class SundayPlanningScreen extends StatefulWidget {
  final AppSettings settings;
  final WeekPlan initialPlan;
  final bool isManualEdit;
  final bool isFirstLaunch;

  const SundayPlanningScreen({
    super.key,
    required this.settings,
    required this.initialPlan,
    this.isManualEdit = false,
    this.isFirstLaunch = false,
  });

  @override
  State<SundayPlanningScreen> createState() => _SundayPlanningScreenState();
}

class _SundayPlanningScreenState extends State<SundayPlanningScreen> {
  final _service = SettingsService();
  late WeekPlan _plan;
  bool _done = false;

  // Arrival time per day (defaults)
  final Map<String, String> _arrivalTimes = {
    'monday': '08:30',
    'tuesday': '08:30',
    'wednesday': '08:30',
    'thursday': '08:30',
    'friday': '08:30',
  };

  static const List<_DayEntry> _days = [
    _DayEntry('monday', 'Monday'),
    _DayEntry('tuesday', 'Tuesday'),
    _DayEntry('wednesday', 'Wednesday'),
    _DayEntry('thursday', 'Thursday'),
    _DayEntry('friday', 'Friday'),
  ];

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan;
    // Seed arrival times from existing plan
    for (final d in _days) {
      final existing = _plan.days[d.key]?.arrivalTime;
      if (existing != null) _arrivalTimes[d.key] = existing;
    }
  }

  bool _isGoing(String key) => _plan.days[key]?.goingIn == true;

  void _toggle(String key, bool value) {
    final now = DateTime.now();
    final weekStart = DateTime.parse(_plan.weekStartDate);
    final dayIndex = _days.indexWhere((d) => d.key == key);
    final dayDate = weekStart.add(Duration(days: dayIndex));

    setState(() {
      if (value) {
        _plan = _plan.withDay(
          dayDate,
          DayPlan(goingIn: true, arrivalTime: _arrivalTimes[key]),
        );
      } else {
        _plan = _plan.withDay(dayDate, DayPlan.notGoing());
      }
    });
  }

  Future<void> _pickTime(String key) async {
    final parts = _arrivalTimes[key]!.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'What time do you need to be there?',
    );
    if (picked == null) return;
    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _arrivalTimes[key] = timeStr;
      if (_isGoing(key)) {
        final weekStart = DateTime.parse(_plan.weekStartDate);
        final dayIndex = _days.indexWhere((d) => d.key == key);
        final dayDate = weekStart.add(Duration(days: dayIndex));
        _plan = _plan.withDay(
          dayDate,
          DayPlan(goingIn: true, arrivalTime: timeStr),
        );
      }
    });
  }

  Future<void> _confirm() async {
    await _service.saveWeekPlan(_plan);
    await NotificationService.scheduleAll(
      settings: widget.settings,
      weekPlan: _plan,
    );
    setState(() => _done = true);
  }

  List<String> get _officeDayNames {
    return _days
        .where((d) => _isGoing(d.key))
        .map((d) => d.label)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _DoneScreen(officeDays: _officeDayNames);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isManualEdit ? 'Edit this week' : widget.isFirstLaunch ? "Welcome! 🐱" : "Next week 🗓️"),
        automaticallyImplyLeading: widget.isManualEdit,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!widget.isManualEdit) ...[
                  Text(
                    widget.isFirstLaunch ? 'Hello, Cat! 👋' : 'Good evening, Cat 🌙',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isFirstLaunch
                        ? "Let's get you set up. Which days are you in the office this week?"
                        : "Which days are you heading into the office next week?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Text(
                    'Change your office days',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Update which days you're going in this week.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                ],
                ...(_days.map((d) => _DayRow(
                  label: d.label,
                  isGoing: _isGoing(d.key),
                  arrivalTime: _arrivalTimes[d.key]!,
                  onToggle: (v) => _toggle(d.key, v),
                  onTimeTap: _isGoing(d.key) ? () => _pickTime(d.key) : null,
                ))),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirm,
                  child: const Text('Confirm'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEntry {
  final String key;
  final String label;
  const _DayEntry(this.key, this.label);
}

class _DayRow extends StatelessWidget {
  final String label;
  final bool isGoing;
  final String arrivalTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTimeTap;

  const _DayRow({
    required this.label,
    required this.isGoing,
    required this.arrivalTime,
    required this.onToggle,
    this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isGoing ? AppTheme.sageLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGoing ? AppTheme.sage : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onToggle(!isGoing),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isGoing ? AppTheme.sage : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isGoing ? AppTheme.sage : const Color(0xFFBBBBBB),
                      width: 2,
                    ),
                  ),
                  child: isGoing
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isGoing ? FontWeight.w600 : FontWeight.w400,
                      color: isGoing ? AppTheme.sageDark : Colors.black54,
                    ),
                  ),
                ),
                if (isGoing && onTimeTap != null)
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.sage.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 13, color: AppTheme.sageDark),
                          const SizedBox(width: 4),
                          Text(
                            arrivalTime,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sageDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneScreen extends StatelessWidget {
  final List<String> officeDays;

  const _DoneScreen({required this.officeDays});

  @override
  Widget build(BuildContext context) {
    final hasOffice = officeDays.isNotEmpty;
    final dayList = officeDays.isEmpty
        ? 'No office days this week — enjoy working from home!'
        : officeDays.join(', ');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text(
                hasOffice ? 'All noted, sleep well!' : 'Enjoy the week!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                hasOffice
                    ? "I've got you down for:\n$dayList\n\nI'll check in the evening before each office day. 💚"
                    : dayList,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
