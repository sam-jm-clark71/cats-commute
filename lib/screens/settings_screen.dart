import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/ride_log.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final RideLog? rideLog;
  const SettingsScreen({super.key, required this.settings, this.rideLog});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  late AppSettings _settings;
  late TextEditingController _apiKeyController;
  bool _apiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _apiKeyController =
        TextEditingController(text: _settings.openWeatherApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated =
        _settings.copyWith(openWeatherApiKey: _apiKeyController.text.trim());
    await _service.save(updated);
    final weekPlan = await _service.loadWeekPlan();
    await NotificationService.scheduleAll(
      settings: updated,
      weekPlan: weekPlan,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Settings saved ✓'),
            duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API key
          _SectionHeader('Weather API'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('OpenWeatherMap API key',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    'Free at openweathermap.org',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_apiKeyVisible,
                    decoration: InputDecoration(
                      hintText: 'Paste API key here',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: Icon(_apiKeyVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _apiKeyVisible = !_apiKeyVisible),
                      ),
                    ),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SectionHeader('Cycling preferences'),
          // Ride tracking toggle — prominent at the top of this section
          Card(
            child: SwitchListTile(
              value: _settings.rideTrackingEnabled,
              onChanged: (v) => setState(
                  () => _settings = _settings.copyWith(rideTrackingEnabled: v)),
              activeColor: const Color(0xFF7B9E87),
              title: const Text('Ride tracking',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: Text(
                _settings.rideTrackingEnabled
                    ? 'Times your cycles to auto-update the commute estimate'
                    : 'Off — the manual cycling time below is used instead',
                style: const TextStyle(fontSize: 12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rain threshold',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text('Max chance of rain for cycling',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        '${_settings.rainThresholdPercent.round()}%',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B9E87)),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.rainThresholdPercent,
                    min: 10,
                    max: 70,
                    divisions: 12,
                    activeColor: const Color(0xFF7B9E87),
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(rainThresholdPercent: v)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('10% (rain shy)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      Text('70% (fearless)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Minimum cycling temperature',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text('Too cold below this',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        '${_settings.minCyclingTempC.round()}°C',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B9E87)),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.minCyclingTempC,
                    min: 0,
                    max: 15,
                    divisions: 15,
                    activeColor: const Color(0xFF7B9E87),
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(minCyclingTempC: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cycling time',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text('Door-to-door estimate',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_settings.cyclingMinutes} min',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7B9E87)),
                          ),
                          if (widget.rideLog?.averageMinutes != null)
                            Text(
                              'Avg ${widget.rideLog!.averageMinutes!.round()} min (${widget.rideLog!.completedCount} rides)',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF7B9E87)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.cyclingMinutes.toDouble(),
                    min: 20,
                    max: 70,
                    divisions: 10,
                    activeColor: const Color(0xFF7B9E87),
                    onChanged: (v) => setState(() => _settings =
                        _settings.copyWith(cyclingMinutes: v.round())),
                  ),
                  if (widget.rideLog != null && widget.rideLog!.completedCount >= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Auto-updating from your ride history — manual setting is the fallback.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Once you've tracked 2+ rides, this updates automatically.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Typical office days (for Sunday pre-selection)
          _SectionHeader('Typical office days'),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(
                      "These are pre-selected on the Sunday planning screen — you can always change them week by week.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  _DayToggle(
                    day: 'Monday',
                    value: _settings.typicalMonday,
                    onChanged: (v) => setState(
                        () => _settings = _settings.copyWith(typicalMonday: v)),
                  ),
                  const Divider(height: 1, indent: 16),
                  _DayToggle(
                    day: 'Tuesday',
                    value: _settings.typicalTuesday,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(typicalTuesday: v)),
                  ),
                  const Divider(height: 1, indent: 16),
                  _DayToggle(
                    day: 'Thursday',
                    value: _settings.typicalThursday,
                    onChanged: (v) => setState(() =>
                        _settings = _settings.copyWith(typicalThursday: v)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _SectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                _TimePicker(
                  label: 'Morning reminder',
                  subtitle: 'On office days',
                  hour: _settings.morningNotifHour,
                  minute: _settings.morningNotifMinute,
                  onChanged: (h, m) => setState(() => _settings = _settings.copyWith(
                        morningNotifHour: h,
                        morningNotifMinute: m,
                      )),
                ),
                const Divider(height: 1, indent: 16),
                _TimePicker(
                  label: 'Evening check-ins',
                  subtitle: 'Sunday planning + night before office days',
                  hour: _settings.eveningNotifHour,
                  minute: _settings.eveningNotifMinute,
                  onChanged: (h, m) => setState(() => _settings = _settings.copyWith(
                        eveningNotifHour: h,
                        eveningNotifMinute: m,
                      )),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          FilledButton(onPressed: _save, child: const Text('Save settings')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888888),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final String day;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _DayToggle(
      {required this.day, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(day, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF7B9E87),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String subtitle;
  final int hour;
  final int minute;
  final void Function(int h, int m) onChanged;

  const _TimePicker({
    required this.label,
    required this.subtitle,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  String get _timeStr =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: hour, minute: minute),
          );
          if (picked != null) onChanged(picked.hour, picked.minute);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4F1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _timeStr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6B55),
            ),
          ),
        ),
      ),
    );
  }
}
