class BuildMetadataConfig {
  BuildMetadataConfig._();

  static const String gitCommit =
      String.fromEnvironment('APP_GIT_COMMIT', defaultValue: '');
  static const String buildDate =
      String.fromEnvironment('APP_BUILD_DATE', defaultValue: '');

  static String get shortCommit {
    if (gitCommit.isEmpty) {
      return '';
    }
    return gitCommit.length <= 12 ? gitCommit : gitCommit.substring(0, 12);
  }
}
