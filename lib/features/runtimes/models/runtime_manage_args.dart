class RuntimeManageArgs {
  const RuntimeManageArgs({
    required this.runtimeId,
    this.runtimeName,
    this.runtimeKind,
    this.codeDir,
    this.packageManager,
  });

  final int runtimeId;
  final String? runtimeName;
  final String? runtimeKind;
  final String? codeDir;
  final String? packageManager;
}
