class DateTimeService {
  static String calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    return '${years}y ${months}m';
  }

  static String formatTime(dynamic timestamp) {
    final time =
        timestamp is String ? DateTime.parse(timestamp) : timestamp as DateTime;
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
