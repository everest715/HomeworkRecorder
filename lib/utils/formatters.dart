/// 格式化秒数为 "Xh Xm" 或 "Xm"
String formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}

/// 格式化秒数为 "MM:SS"
String formatDurationShort(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// 格式化日期为 "M月d日"
String formatDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

/// 格式化日期为 "HH:MM"
String formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
