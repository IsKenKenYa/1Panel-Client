class ServerConnectionResult {
  const ServerConnectionResult({
    required this.success,
    this.errorMessage,
    this.operatingSystem,
    this.responseTime,
    this.isNetworkError = false,
  });

  final bool success;
  final String? errorMessage;
  final String? operatingSystem;
  final Duration? responseTime;
  final bool isNetworkError;
}
