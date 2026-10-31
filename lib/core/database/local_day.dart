DateTime localDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime nextLocalDay(DateTime date) {
  final day = localDay(date);
  // Calendar arithmetic, not a 24-hour duration (DST-safe).
  return DateTime(day.year, day.month, day.day + 1);
}
