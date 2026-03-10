enum CommuteMode { cycle, tube, unclear }

enum TubeRoute { claphamCommon, claphamSouth, brixton }

class CommuteWindow {
  final double maxRainPercent;
  final double avgTempC;
  final String timeLabel; // e.g. "8am–9am"

  const CommuteWindow({
    required this.maxRainPercent,
    required this.avgTempC,
    required this.timeLabel,
  });
}

class CommuteRecommendation {
  final CommuteMode mode;
  final String headline;
  final String reasoning;
  final CommuteWindow? morningWeather;
  final CommuteWindow? eveningWeather;
  final bool? goingOutAfterWork;
  final bool weatherLoaded;

  const CommuteRecommendation({
    required this.mode,
    required this.headline,
    required this.reasoning,
    this.morningWeather,
    this.eveningWeather,
    this.goingOutAfterWork,
    this.weatherLoaded = true,
  });

  CommuteRecommendation withAfterWork(bool goingOut) {
    return CommuteRecommendation(
      mode: mode,
      headline: headline,
      reasoning: reasoning,
      morningWeather: morningWeather,
      eveningWeather: eveningWeather,
      goingOutAfterWork: goingOut,
      weatherLoaded: weatherLoaded,
    );
  }

  static CommuteRecommendation loading() => const CommuteRecommendation(
        mode: CommuteMode.unclear,
        headline: 'Checking the forecast…',
        reasoning: '',
        weatherLoaded: false,
      );

  static CommuteRecommendation noApiKey() => const CommuteRecommendation(
        mode: CommuteMode.unclear,
        headline: 'Setup needed',
        reasoning: 'Please add your OpenWeatherMap API key in Settings to get forecasts.',
        weatherLoaded: true,
      );

  static CommuteRecommendation error() => const CommuteRecommendation(
        mode: CommuteMode.unclear,
        headline: 'Could not load forecast',
        reasoning: 'Check your internet connection and try again.',
        weatherLoaded: true,
      );

  static CommuteRecommendation notOfficeDay() => const CommuteRecommendation(
        mode: CommuteMode.unclear,
        headline: 'Enjoy your day off!',
        reasoning: 'Today is not a scheduled office day.',
        weatherLoaded: true,
      );
}
