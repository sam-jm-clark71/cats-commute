import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/week_plan.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';

enum _Step { stillGoing, arrivalTime, cycling, done }

class EveningCheckInScreen extends StatefulWidget {
  final AppSettings settings;
  final WeekPlan weekPlan;
  final DateTime tomorrowDate;

  const EveningCheckInScreen({
    super.key,
    required this.settings,
    required this.weekPlan,
    required this.tomorrowDate,
  });

  @override
  State<EveningCheckInScreen> createState() => _EveningCheckInScreenState();
}

class _EveningCheckInScreenState extends State<EveningCheckInScreen> {
  final _service = SettingsService();
  _Step _step = _Step.stillGoing;

  bool _stillGoing = true;
  String _arrivalTime = '08:30';
  bool? _openToCycling;

  @override
  void initState() {
    super.initState();
    // Seed arrival time from existing plan if set
    final existing = widget.weekPlan.arrivalTime(widget.tomorrowDate);
    if (existing != null) _arrivalTime = existing;
  }

  Future<void> _saveAndFinish() async {
    final updated = widget.weekPlan.withDay(
      widget.tomorrowDate,
      DayPlan(
        goingIn: _stillGoing,
        arrivalTime: _stillGoing ? _arrivalTime : null,
        openToCycling: _stillGoing ? _openToCycling : null,
      ),
    );
    await _service.saveWeekPlan(updated);
    await NotificationService.scheduleAll(
      settings: widget.settings,
      weekPlan: updated,
    );
    if (mounted) setState(() => _step = _Step.done);
  }

  Future<void> _pickTime() async {
    final parts = _arrivalTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'What time would you like to arrive?',
    );
    if (picked == null) return;
    setState(() {
      _arrivalTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evening check-in 🌙')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.stillGoing:
        return _StillGoingStep(
          key: const ValueKey('stillGoing'),
          tomorrowDate: widget.tomorrowDate,
          onYes: () => setState(() {
            _stillGoing = true;
            _step = _Step.arrivalTime;
          }),
          onNo: () {
            _stillGoing = false;
            _saveAndFinish();
          },
        );
      case _Step.arrivalTime:
        return _ArrivalTimeStep(
          key: const ValueKey('arrivalTime'),
          arrivalTime: _arrivalTime,
          onPickTime: _pickTime,
          onNext: () => setState(() => _step = _Step.cycling),
        );
      case _Step.cycling:
        return _CyclingStep(
          key: const ValueKey('cycling'),
          onYes: () {
            _openToCycling = true;
            _saveAndFinish();
          },
          onNo: () {
            _openToCycling = false;
            _saveAndFinish();
          },
        );
      case _Step.done:
        return _DoneStep(
          key: const ValueKey('done'),
          stillGoing: _stillGoing,
          arrivalTime: _arrivalTime,
          openToCycling: _openToCycling,
          onClose: () => Navigator.of(context).pop(),
        );
    }
  }
}

// ── Steps ─────────────────────────────────────────────────────────────────

class _StillGoingStep extends StatelessWidget {
  final DateTime tomorrowDate;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _StillGoingStep({
    super.key,
    required this.tomorrowDate,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = const [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ][tomorrowDate.weekday - 1];

    return _StepShell(
      emoji: '🏢',
      question: 'Are you still heading into the office tomorrow ($weekday)?',
      children: [
        const SizedBox(height: 28),
        _BigButton(
          label: 'Yes, still going in',
          color: AppTheme.sage,
          onTap: onYes,
        ),
        const SizedBox(height: 12),
        _BigButton(
          label: 'No, not going in',
          color: const Color(0xFFAAAAAA),
          onTap: onNo,
        ),
      ],
    );
  }
}

class _ArrivalTimeStep extends StatelessWidget {
  final String arrivalTime;
  final VoidCallback onPickTime;
  final VoidCallback onNext;

  const _ArrivalTimeStep({
    super.key,
    required this.arrivalTime,
    required this.onPickTime,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      emoji: '⏰',
      question: 'What time would you like to arrive?',
      children: [
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onPickTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.sageLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.sage, width: 2),
            ),
            child: Text(
              arrivalTime,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppTheme.sageDark,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to change',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 28),
        _BigButton(label: 'That\'s the time →', color: AppTheme.sage, onTap: onNext),
      ],
    );
  }
}

class _CyclingStep extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _CyclingStep({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      emoji: '🚲',
      question: 'Are you open to cycling tomorrow?',
      subtitle: "I'll check the forecast in the morning and let you know",
      children: [
        const SizedBox(height: 28),
        _BigButton(label: 'Yes, if the weather\'s good', color: AppTheme.cycleGreen, onTap: onYes),
        const SizedBox(height: 12),
        _BigButton(label: 'No, tube it is', color: AppTheme.tubeBlue, onTap: onNo),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  final bool stillGoing;
  final String arrivalTime;
  final bool? openToCycling;
  final VoidCallback onClose;

  const _DoneStep({
    super.key,
    required this.stillGoing,
    required this.arrivalTime,
    required this.openToCycling,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    if (!stillGoing) {
      message = "No worries — enjoy the day off! I've updated your week.";
    } else if (openToCycling == true) {
      message = "Great! I'll check the forecast in the morning and let you know "
          "if it's a cycling day. Target arrival: $arrivalTime. Sleep well! 💚";
    } else {
      message = "Tube it is! I'll have the Northern Line status ready for you "
          "in the morning. Target arrival: $arrivalTime. Sleep well! 🚇";
    }

    return _StepShell(
      emoji: '🌙',
      question: stillGoing ? 'Goodnight, Cat!' : 'All noted!',
      children: [
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────

class _StepShell extends StatelessWidget {
  final String emoji;
  final String question;
  final String? subtitle;
  final List<Widget> children;

  const _StepShell({
    super.key,
    required this.emoji,
    required this.question,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 20),
          Text(
            question,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 22,
                ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
