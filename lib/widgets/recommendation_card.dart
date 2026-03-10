import 'package:flutter/material.dart';
import '../models/commute_recommendation.dart';
import '../theme.dart';

class RecommendationCard extends StatelessWidget {
  final CommuteRecommendation recommendation;
  final bool? goingOutAfterWork;
  final VoidCallback? onGoingOut;
  final VoidCallback? onNotGoingOut;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.goingOutAfterWork,
    this.onGoingOut,
    this.onNotGoingOut,
  });

  @override
  Widget build(BuildContext context) {
    if (!recommendation.weatherLoaded) {
      return _buildLoadingCard(context);
    }
    return _buildCard(context);
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Text(recommendation.headline,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final (bg, fg, accent) = _colours(recommendation.mode);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _modeIcon(recommendation.mode),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.headline,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          if (recommendation.reasoning.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...recommendation.reasoning.split('\n').map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 14,
                        color: fg.withOpacity(0.85),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
          ],

          // After-work question (show when cycling is possible)
          if (_showAfterWorkQuestion) ...[
            const SizedBox(height: 16),
            Text(
              'Are you heading straight out after work?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChoiceChip(
                  label: 'Yes, going out',
                  selected: goingOutAfterWork == true,
                  onTap: onGoingOut,
                  selectedColor: fg,
                  unselectedColor: bg,
                  borderColor: fg.withOpacity(0.4),
                  textColor: fg,
                ),
                const SizedBox(width: 8),
                _ChoiceChip(
                  label: 'No, cycling home',
                  selected: goingOutAfterWork == false,
                  onTap: onNotGoingOut,
                  selectedColor: fg,
                  unselectedColor: bg,
                  borderColor: fg.withOpacity(0.4),
                  textColor: fg,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool get _showAfterWorkQuestion {
    return recommendation.mode == CommuteMode.cycle ||
        (recommendation.mode == CommuteMode.unclear &&
            recommendation.morningWeather != null);
  }

  String _modeIcon(CommuteMode mode) {
    switch (mode) {
      case CommuteMode.cycle:
        return '🚲';
      case CommuteMode.tube:
        return '🚇';
      case CommuteMode.unclear:
        return '☁️';
    }
  }

  (Color, Color, Color) _colours(CommuteMode mode) {
    switch (mode) {
      case CommuteMode.cycle:
        return (
          const Color(0xFFE8F3EC),
          AppTheme.cycleGreen,
          AppTheme.cycleGreen,
        );
      case CommuteMode.tube:
        return (
          const Color(0xFFE8EEF7),
          AppTheme.tubeBlue,
          AppTheme.tubeBlue,
        );
      case CommuteMode.unclear:
        return (
          const Color(0xFFF7F0E6),
          AppTheme.unclearAmber,
          AppTheme.unclearAmber,
        );
    }
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color borderColor;
  final Color textColor;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : borderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}
