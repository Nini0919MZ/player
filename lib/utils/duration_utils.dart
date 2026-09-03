class DurationUtils {
  static String formatDuration(Duration duration, {String zero = '0:00'}) {
    if (duration.inMilliseconds <= 0) return zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '${duration.inMinutes}:$seconds';
  }

  static String formatMilliseconds(int? milliseconds, {String zero = '0:00'}) {
    if (milliseconds == null || milliseconds <= 0) return zero;
    return formatDuration(
      Duration(milliseconds: milliseconds),
      zero: zero,
    );
  }
}
