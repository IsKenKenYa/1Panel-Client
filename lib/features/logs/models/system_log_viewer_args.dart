class SystemLogViewerArgs {
  const SystemLogViewerArgs({
    this.initialFileName,
    this.useCoreLogs = false,
  });

  final String? initialFileName;
  final bool useCoreLogs;
}
