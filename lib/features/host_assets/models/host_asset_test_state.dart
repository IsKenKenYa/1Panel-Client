enum HostAssetTestStatus {
  notTested,
  success,
  failure,
}

class HostAssetTestState {
  const HostAssetTestState({
    required this.status,
    this.message,
  });

  final HostAssetTestStatus status;
  final String? message;

  static const HostAssetTestState notTested = HostAssetTestState(
    status: HostAssetTestStatus.notTested,
  );
}
