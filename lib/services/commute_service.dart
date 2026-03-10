import '../models/app_settings.dart';
import '../models/commute_recommendation.dart';
import '../models/ride_log.dart';
import '../models/ride_log.dart';
import '../models/week_plan.dart';
import 'weather_service.dart';

class CommuteService {
  final AppSettings settings;
  final WeekPlan? weekPlan;
  final RideLog? rideLog;

  CommuteService(this.settings, {this.weekPlan, this.rideLog});

  /// Cycling time used in calculations: ride log average (if 2+ rides) else manual setting.
  int get effectiveCyclingMinutes {
    final avg = rideLog?.averageMinutes;
    if (avg != null && (rideLog?.completedCount ?? 0) >= 2) return avg.round();
    return settings.cyclingMinutes;
  }

  Future<CommuteRecommendation> getRecommendation({
    bool? goingOutAfterWork,
  }) async {
    if (!settings.isConfigured) {
      return CommuteRecommendation.noApiKey();
    }

    final today = DateTime.now();
    final plan = weekPlan?.dayPlan(today);

    if (plan == null || !plan.goingIn) {
      return CommuteRecommendation.notOfficeDay();
    }

    // If evening check-in said she's not open to cycling, go straight to tube
    if (plan.openToCycling == false) {
      return CommuteRecommendation(
        mode: CommuteMode.tube,
        headline: 'Tube day 🚇',
        reasoning: "You said last night you're not cycling today.",
        weatherLoaded: true,
      );
    }

    try {
      final arrivalTime = plan.arrivalTime ?? '08:30';
      final weatherService = WeatherService(
        settings.openWeatherApiKey,
        cyclingMinutes: effectiveCyclingMinutes,
        targetArrivalTime: arrivalTime,
      );
      final windows = await weatherService.fetchCommuteWindows();
      final morning = windows['morning']!;
      final evening = windows['evening']!;

      return _decide(
        morning: morning,
        evening: evening,
        goingOutAfterWork: goingOutAfterWork,
        openToCycling: plan.openToCycling,
      );
    } catch (_) {
      return CommuteRecommendation.error();
    }
  }

  CommuteRecommendation _decide({
    required CommuteWindow morning,
    required CommuteWindow evening,
    bool? goingOutAfterWork,
    bool? openToCycling,
  }) {
    final threshold = settings.rainThresholdPercent;
    final borderline = threshold * 0.85;
    final morningRain = morning.maxRainPercent;
    final eveningRain = evening.maxRainPercent;
    final morningTemp = morning.avgTempC;
    final tooCold = morningTemp < settings.minCyclingTempC;

    if (morningRain >= threshold) {
      return CommuteRecommendation(
        mode: CommuteMode.tube,
        headline: 'Tube day 🚇',
        reasoning: _join([
          'Rain forecast at ${morningRain.round()}% this morning '
              '(your limit is ${threshold.round()}%)',
          if (tooCold) 'Also quite cold (${morningTemp.round()}°C)',
        ]),
        morningWeather: morning,
        eveningWeather: evening,
      );
    }

    if (tooCold) {
      return CommuteRecommendation(
        mode: CommuteMode.tube,
        headline: 'Tube day 🚇',
        reasoning: _join([
          'Chilly this morning at ${morningTemp.round()}°C '
              '(your cycling minimum is ${settings.minCyclingTempC.round()}°C)',
          if (morningRain > 10) 'Plus ${morningRain.round()}% chance of rain',
        ]),
        morningWeather: morning,
        eveningWeather: evening,
      );
    }

    if (morningRain >= borderline) {
      return CommuteRecommendation(
        mode: CommuteMode.unclear,
        headline: 'Could go either way ☁️',
        reasoning: _join([
          'Morning rain at ${morningRain.round()}% — close to your '
              '${threshold.round()}% limit',
          if (eveningRain >= threshold) 'Evening also looks wet (${eveningRain.round()}%)',
          if (goingOutAfterWork == true)
            "You're heading out after work, so tube might make more sense",
        ]),
        morningWeather: morning,
        eveningWeather: evening,
        goingOutAfterWork: goingOutAfterWork,
      );
    }

    // Morning looks fine for cycling
    if (goingOutAfterWork == true) {
      return CommuteRecommendation(
        mode: CommuteMode.tube,
        headline: 'Tube today 🚇',
        reasoning: _join([
          "Weather's fine for cycling but you're heading out after work",
          'Take the tube so you can come home without the bike',
        ]),
        morningWeather: morning,
        eveningWeather: evening,
        goingOutAfterWork: goingOutAfterWork,
      );
    }

    if (goingOutAfterWork == null) {
      if (eveningRain >= threshold) {
        return CommuteRecommendation(
          mode: CommuteMode.unclear,
          headline: 'Morning looks good… 🚲❓',
          reasoning: _join([
            'Morning rain only ${morningRain.round()}% — fine for cycling',
            'But evening looks wet (${eveningRain.round()}%)',
            'Are you heading out straight from work?',
          ]),
          morningWeather: morning,
          eveningWeather: evening,
          goingOutAfterWork: goingOutAfterWork,
        );
      }
      return CommuteRecommendation(
        mode: CommuteMode.cycle,
        headline: 'Cycle day! 🚲',
        reasoning: _join([
          'Low rain forecast (${morningRain.round()}% morning, ${eveningRain.round()}% evening)',
          'Looks great for the bike — are you heading out after work?',
        ]),
        morningWeather: morning,
        eveningWeather: evening,
        goingOutAfterWork: goingOutAfterWork,
      );
    }

    if (eveningRain >= threshold) {
      return CommuteRecommendation(
        mode: CommuteMode.unclear,
        headline: 'Cycle in, tube back? ☁️',
        reasoning: _join([
          'Morning looks fine (${morningRain.round()}% rain)',
          'Evening forecast is ${eveningRain.round()}% — possibly wet ride home',
        ]),
        morningWeather: morning,
        eveningWeather: evening,
        goingOutAfterWork: goingOutAfterWork,
      );
    }

    return CommuteRecommendation(
      mode: CommuteMode.cycle,
      headline: 'Cycle day! 🚲',
      reasoning: _join([
        'Low rain all day (${morningRain.round()}% morning, ${eveningRain.round()}% evening)',
        'Great weather for the bike!',
      ]),
      morningWeather: morning,
      eveningWeather: evening,
      goingOutAfterWork: goingOutAfterWork,
    );
  }

  String _join(List<String> parts) => parts.join('\n');
}
