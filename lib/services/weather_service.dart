import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/commute_recommendation.dart';

class WeatherService {
  static const double _homeLat = 51.4534;
  static const double _homeLon = -0.1344;

  final String apiKey;
  final int cyclingMinutes;
  final String targetArrivalTime; // e.g. "08:30"

  WeatherService(
    this.apiKey, {
    this.cyclingMinutes = 40,
    this.targetArrivalTime = '08:30',
  });

  Future<Map<String, CommuteWindow>> fetchCommuteWindows() async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast'
      '?lat=$_homeLat&lon=$_homeLon&appid=$apiKey&units=metric',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['list'] as List<dynamic>;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate morning window from target arrival time
    final parts = targetArrivalTime.split(':');
    final arrivalHour = int.tryParse(parts[0]) ?? 8;
    final arrivalMinute = int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30;

    final arrivalMins = arrivalHour * 60 + arrivalMinute;
    final departMins = arrivalMins - cyclingMinutes;
    final windowStartMins = departMins - 15;
    final windowEndMins = arrivalMins + 15;

    final morningStart = today.add(Duration(minutes: windowStartMins));
    final morningEnd = today.add(Duration(minutes: windowEndMins));

    // Evening: 4:30pm–7pm
    final eveningStart = today.add(const Duration(hours: 16, minutes: 30));
    final eveningEnd = today.add(const Duration(hours: 19));

    final morningSlots = <Map<String, dynamic>>[];
    final eveningSlots = <Map<String, dynamic>>[];

    for (final item in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (item['dt'] as int) * 1000,
      );
      if (dt.isAfter(morningStart.subtract(const Duration(hours: 1))) &&
          dt.isBefore(morningEnd.add(const Duration(hours: 1)))) {
        morningSlots.add(item as Map<String, dynamic>);
      } else if (dt.isAfter(eveningStart.subtract(const Duration(hours: 1))) &&
          dt.isBefore(eveningEnd.add(const Duration(hours: 1)))) {
        eveningSlots.add(item as Map<String, dynamic>);
      }
    }

    return {
      'morning': _summarise(morningSlots, targetArrivalTime),
      'evening': _summarise(eveningSlots, '5pm–6pm'),
    };
  }

  CommuteWindow _summarise(List<Map<String, dynamic>> slots, String label) {
    if (slots.isEmpty) {
      return CommuteWindow(maxRainPercent: 0, avgTempC: 15, timeLabel: label);
    }
    double maxRain = 0;
    double totalTemp = 0;
    for (final s in slots) {
      final pop = (s['pop'] as num?)?.toDouble() ?? 0;
      final temp = (s['main']?['temp'] as num?)?.toDouble() ?? 15.0;
      if (pop * 100 > maxRain) maxRain = pop * 100;
      totalTemp += temp;
    }
    return CommuteWindow(
      maxRainPercent: maxRain,
      avgTempC: totalTemp / slots.length,
      timeLabel: label,
    );
  }
}
