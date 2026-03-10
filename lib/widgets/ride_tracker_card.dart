import 'package:flutter/material.dart';
import '../models/ride_log.dart';
import '../theme.dart';

class RideTrackerCard extends StatelessWidget {
  final RideLog rideLog;
  final VoidCallback onStartRide;
  final VoidCallback onArrived;

  const RideTrackerCard({
    super.key,
    required this.rideLog,
    required this.onStartRide,
    required this.onArrived,
  });

  @override
  Widget build(BuildContext context) {
    final inProgress = rideLog.inProgress;
    final avg = rideLog.averageMinutes;
    final count = rideLog.completedCount;

    if (inProgress != null) {
      return _RideInProgress(
        startTime: inProgress.startTime,
        onArrived: onArrived,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Track this ride',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (avg != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Avg ${avg.round()} min  ($count ${count == 1 ? 'ride' : 'rides'})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sageDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              avg == null
                  ? 'Tap when you set off — I\'ll time the ride and learn your pace.'
                  : 'Keep tracking to keep the forecast window accurate.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cycleGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onStartRide,
                icon: const Text('🚲', style: TextStyle(fontSize: 18)),
                label: const Text('Start ride',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideInProgress extends StatefulWidget {
  final DateTime startTime;
  final VoidCallback onArrived;

  const _RideInProgress({
    required this.startTime,
    required this.onArrived,
  });

  @override
  State<_RideInProgress> createState() => _RideInProgressState();
}

class _RideInProgressState extends State<_RideInProgress> {
  late final Stream<Duration> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 30), (_) {
      return DateTime.now().difference(widget.startTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3EC),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🚲', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text('Ride in progress',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: AppTheme.cycleGreen,
                        )),
                const Spacer(),
                StreamBuilder<Duration>(
                  stream: _ticker,
                  initialData: DateTime.now().difference(widget.startTime),
                  builder: (context, snap) {
                    final elapsed = snap.data ?? Duration.zero;
                    final mins = elapsed.inMinutes;
                    return Text(
                      '${mins} min',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.cycleGreen,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.cycleGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onArrived,
                child: const Text('🏁  I\'m here!',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
