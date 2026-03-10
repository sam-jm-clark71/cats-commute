import 'package:flutter/material.dart';
import '../models/commute_recommendation.dart';

class WeatherCard extends StatelessWidget {
  final CommuteWindow morning;
  final CommuteWindow evening;

  const WeatherCard({
    super.key,
    required this.morning,
    required this.evening,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forecast', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            _WeatherRow(
              icon: '🌅',
              label: 'Morning',
              time: morning.timeLabel,
              rainPercent: morning.maxRainPercent,
              tempC: morning.avgTempC,
            ),
            const Divider(height: 20),
            _WeatherRow(
              icon: '🌆',
              label: 'Evening',
              time: evening.timeLabel,
              rainPercent: evening.maxRainPercent,
              tempC: evening.avgTempC,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final String icon;
  final String label;
  final String time;
  final double rainPercent;
  final double tempC;

  const _WeatherRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.rainPercent,
    required this.tempC,
  });

  @override
  Widget build(BuildContext context) {
    final rainColor = rainPercent >= 50
        ? Colors.blue.shade700
        : rainPercent >= 30
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label  ·  $time',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tempC.round()}°C',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: rainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                '💧',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                '${rainPercent.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rainColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
