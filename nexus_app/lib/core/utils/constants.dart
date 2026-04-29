class AppConstants {
  // Polling
  static const Duration documentPollingInterval = Duration(seconds: 5);
  static const int documentPollingMaxAttempts = 24; // 2 min total

  // Pagination
  static const int defaultPageSize = 20;
}