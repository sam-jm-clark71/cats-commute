import 'package:flutter/material.dart';
import '../models/tfl_status.dart';

class TflStatusCard extends StatelessWidget {
  final TflLineStatus? status;
  final bool isLoading;

  const TflStatusCard({
    super.key,
    this.status,
    this.isLoading = false,
  });

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
                Text('Northern Line', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (status != null) _buildStatus(context, status!),
            if (status == null && !isLoading)
              const Text('Status unavailable',
                  style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context, TflLineStatus status) {
    final (icon, color) = _statusIconAndColor(status.severity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status.statusDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
        if (status.disruption != null) ...[
          const SizedBox(height: 8),
          Text(
            status.disruption!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (status.isSevere) ...[
          const SizedBox(height: 12),
          const _TubeRouteSuggestions(),
        ],
      ],
    );
  }

  (String, Color) _statusIconAndColor(TflSeverity severity) {
    switch (severity) {
      case TflSeverity.goodService:
        return ('✅', Colors.green.shade600);
      case TflSeverity.minorDelays:
        return ('⚠️', Colors.orange.shade600);
      case TflSeverity.severeDelays:
        return ('🔴', Colors.red.shade600);
      case TflSeverity.partSuspended:
        return ('🔴', Colors.red.shade700);
      case TflSeverity.suspended:
        return ('🚫', Colors.red.shade900);
      case TflSeverity.unknown:
        return ('❓', Colors.grey);
    }
  }
}

class _TubeRouteSuggestions extends StatelessWidget {
  const _TubeRouteSuggestions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alternative routes from home:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _RouteOption(
            emoji: '🟢',
            name: 'Clapham Common',
            description: 'Usual route (nearest)',
          ),
          const SizedBox(height: 4),
          _RouteOption(
            emoji: '🟡',
            name: 'Clapham South',
            description: 'One stop south, similar walk',
          ),
          const SizedBox(height: 4),
          _RouteOption(
            emoji: '🔵',
            name: 'Brixton (Victoria Line)',
            description: 'Longer walk, avoids Northern Line',
          ),
        ],
      ),
    );
  }
}

class _RouteOption extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;

  const _RouteOption({
    required this.emoji,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$name  ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
