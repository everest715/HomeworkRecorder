import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int elapsedSeconds;
  final int? targetSeconds;
  final bool isCountdown;

  const TimerDisplay({
    super.key,
    required this.elapsedSeconds,
    this.targetSeconds,
    this.isCountdown = false,
  });

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displaySeconds = isCountdown && targetSeconds != null
        ? (targetSeconds! - elapsedSeconds).clamp(0, targetSeconds!)
        : elapsedSeconds;
    final progress = isCountdown && targetSeconds != null && targetSeconds! > 0
        ? elapsedSeconds / targetSeconds!
        : 0.0;

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCountdown && targetSeconds != null)
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            )
          else
            SizedBox(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                value: 0,
                strokeWidth: 8,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          Text(
            _formatDuration(displaySeconds),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
