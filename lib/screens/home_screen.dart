import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../models/commute_recommendation.dart';
import '../models/tfl_status.dart';
import '../models/week_plan.dart';
import '../services/settings_service.dart';
import '../services/commute_service.dart';
import '../services/tfl_service.dart';
import '../models/ride_log.dart';
import '../services/notification_service.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/ride_tracker_card.dart';
import '../widgets/tfl_status_card.dart';
import 'settings_screen.dart';
import 'sunday_planning_screen.dart';
import 'evening_checkin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _settingsService = SettingsService();
  final _tflService = TflService();

  AppSettings _settings = const AppSettings();
  WeekPlan? _weekPlan;
  CommuteRecommendation _recommendation = CommuteRecommendation.loading();
  TflLineStatus? _tflStatus;
  bool _tflLoading = true;
  bool? _goingOutAfterWork;
  RideLog _rideLog = const RideLog();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService.requestPermissions();
    _settings = await _settingsService.load();
    _weekPlan = await _settingsService.getOrCreateWeekPlan(_settings);
    _goingOutAfterWork = await _settingsService.getGoingOutAfterWork();
    _rideLog = await _settingsService.loadRideLog();

    await NotificationService.scheduleAll(
      settings: _settings,
      weekPlan: _weekPlan,
    );

    setState(() {});

    // First launch: no week plan saved yet — go straight to planning screen
    final savedPlan = await _settingsService.loadWeekPlan();
    if (savedPlan == null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SundayPlanningScreen(
            settings: _settings,
            initialPlan: _weekPlan!,
            isManualEdit: false,
            isFirstLaunch: true,
          ),
        ),
      );
      _settings = await _settingsService.load();

      // If it's evening and tomorrow is now an office day, run the check-in too
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final freshPlan = await _settingsService.loadWeekPlan();
      if (freshPlan != null &&
          freshPlan.isOfficeDay(tomorrow) &&
          now.hour >= 17 &&
          mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EveningCheckInScreen(
              settings: _settings,
              weekPlan: freshPlan,
              tomorrowDate: tomorrow,
            ),
          ),
        );
      }
    }

    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _recommendation = CommuteRecommendation.loading();
      _tflLoading = true;
    });

    _weekPlan = await _settingsService.getOrCreateWeekPlan(_settings);
    _rideLog = await _settingsService.loadRideLog();

    final results = await Future.wait([
      _loadRecommendation(),
      _tflService.fetchNorthernLineStatus(),
    ]);

    if (mounted) {
      setState(() {
        _recommendation = results[0] as CommuteRecommendation;
        _tflStatus = results[1] as TflLineStatus;
        _tflLoading = false;
      });
    }
  }

  Future<CommuteRecommendation> _loadRecommendation() {
    return CommuteService(_settings, weekPlan: _weekPlan, rideLog: _rideLog)
        .getRecommendation(goingOutAfterWork: _goingOutAfterWork);
  }

  Future<void> _setGoingOutAfterWork(bool value) async {
    await _settingsService.setGoingOutAfterWork(value);
    setState(() => _goingOutAfterWork = value);
    final updated = await CommuteService(_settings, weekPlan: _weekPlan, rideLog: _rideLog)
        .getRecommendation(goingOutAfterWork: value);
    if (mounted) setState(() => _recommendation = updated);
  }

  Future<void> _startRide() async {
    final updated = _rideLog.withStarted(DateTime.now());
    await _settingsService.saveRideLog(updated);
    if (mounted) setState(() => _rideLog = updated);
  }

  Future<void> _arrivedAtWork() async {
    final updated = _rideLog.withCompleted(DateTime.now());
    await _settingsService.saveRideLog(updated);
    // Refresh recommendation — effective cycling time may have changed
    if (mounted) {
      setState(() => _rideLog = updated);
      final rec = await _loadRecommendation();
      if (mounted) setState(() => _recommendation = rec);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SettingsScreen(settings: _settings, rideLog: _rideLog)),
    );
    _settings = await _settingsService.load();
    await _loadAll();
  }

  Future<void> _openWeeklyPlan() async {
    final plan = await _settingsService.getOrCreateWeekPlan(_settings);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SundayPlanningScreen(
          settings: _settings,
          initialPlan: plan,
          isManualEdit: true,
        ),
      ),
    );
    await _loadAll();
  }

  Future<void> _openEveningCheckIn() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final plan = _weekPlan;
    if (plan == null) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EveningCheckInScreen(
          settings: _settings,
          weekPlan: plan,
          tomorrowDate: tomorrow,
        ),
      ),
    );
    await _loadAll();
  }

  bool get _isOfficeDay => _weekPlan?.isOfficeDay(DateTime.now()) == true;

  bool get _isTomorrowOfficeDay {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _weekPlan?.isOfficeDay(tomorrow) == true;
  }

  bool get _isSunday => DateTime.now().weekday == DateTime.sunday;

  bool get _showRideTracker {
    // Show if there's a ride in progress, or if this morning looks like a cycling day
    if (_rideLog.inProgress != null) return true;
    if (_recommendation.mode == CommuteMode.cycle) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now);
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cat's Commute 🐱"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: const Color(0xFF888888)),
              ),
              const SizedBox(height: 20),

              // Setup banner
              if (!_settings.isConfigured)
                _SetupBanner(onTap: _openSettings)
              else ...[
                // Today's recommendation
                RecommendationCard(
                  recommendation: _recommendation,
                  goingOutAfterWork: _goingOutAfterWork,
                  onGoingOut: () => _setGoingOutAfterWork(true),
                  onNotGoingOut: () => _setGoingOutAfterWork(false),
                ),
                const SizedBox(height: 14),

                if (_recommendation.morningWeather != null &&
                    _recommendation.eveningWeather != null)
                  WeatherCard(
                    morning: _recommendation.morningWeather!,
                    evening: _recommendation.eveningWeather!,
                  ),

                const SizedBox(height: 14),
              ],

              // Ride tracker: show on cycling days (cycle recommendation or in-progress)
              if (_isOfficeDay && _settings.rideTrackingEnabled && _showRideTracker) ...[
                RideTrackerCard(
                  rideLog: _rideLog,
                  onStartRide: _startRide,
                  onArrived: _arrivedAtWork,
                ),
                const SizedBox(height: 14),
              ],

              // TfL status (show on office days or if no API key)
              if (_isOfficeDay || !_settings.isConfigured) ...[
                TflStatusCard(status: _tflStatus, isLoading: _tflLoading),
                const SizedBox(height: 14),
              ],

              // Journey info (on office days)
              if (_isOfficeDay) ...[
                _JourneyDetails(
                  arrivalTime: _weekPlan?.arrivalTime(now) ?? '08:30',
                ),
                const SizedBox(height: 14),
              ],

              // ── Quick action cards ──────────────────────────────────────

              // Sunday planning shortcut
              if (_isSunday)
                _ActionCard(
                  icon: '🗓️',
                  title: 'Plan next week',
                  subtitle: "Which days are you in the office?",
                  onTap: _openWeeklyPlan,
                ),

              // Evening check-in shortcut (show in evenings before office days)
              if (_isTomorrowOfficeDay && now.hour >= 18)
                _ActionCard(
                  icon: '🌙',
                  title: 'Tomorrow\'s check-in',
                  subtitle: "Still heading in? Set your arrival time",
                  onTap: _openEveningCheckIn,
                ),

              // Always visible — edit this week
              _ActionCard(
                icon: '✏️',
                title: 'Edit this week',
                subtitle: 'Change your office days or arrival times',
                onTap: _openWeeklyPlan,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning, Cat ☀️';
    if (h < 17) return 'Good afternoon, Cat 🌤';
    return 'Good evening, Cat 🌙';
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Text('🔑', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add your weather API key',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to open Settings and enter your free OpenWeatherMap key',
                    style: TextStyle(
                        fontSize: 13, color: Colors.orange.shade800),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade400),
          ],
        ),
      ),
    );
  }
}

class _JourneyDetails extends StatelessWidget {
  final String arrivalTime;
  const _JourneyDetails({required this.arrivalTime});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Journey info',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Arrive $arrivalTime',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A6B55)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _JourneyRow(
              icon: '🚲',
              title: 'Cycling',
              detail: 'Rodenhurst Rd → Scrutton St',
            ),
            const Divider(height: 20),
            const _JourneyRow(
              icon: '🚇',
              title: 'Clapham Common',
              detail: 'Northern line → Old Street',
            ),
            const Divider(height: 20),
            const _JourneyRow(
              icon: '🚇',
              title: 'Clapham South',
              detail: 'One stop south, similar walk',
            ),
            const Divider(height: 20),
            const _JourneyRow(
              icon: '🚇',
              title: 'Brixton (if Northern Line bad)',
              detail: "Victoria line → King's Cross → Old Street",
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  final String icon;
  final String title;
  final String detail;
  const _JourneyRow(
      {required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              Text(detail,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF666666))),
            ],
          ),
        ),
      ],
    );
  }
}
