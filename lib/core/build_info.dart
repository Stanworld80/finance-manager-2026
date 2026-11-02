class BuildInfo {
  static const String envVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.9',
  );

  static const String envBuildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: '0',
  );

  static const String envBuildDate = String.fromEnvironment(
    'BUILD_DATE',
    defaultValue: '02/11/2026 20:45',
  );

  static const String copyrightHolder = 'Stanislas Selle Informatique';

  static String formatVersion({
    String? packageVersion,
    String? packageBuildNumber,
    String? buildDateOverride,
  }) {
    final version = (packageVersion != null && packageVersion.isNotEmpty)
        ? packageVersion
        : envVersion;

    final String buildNumber;
    if (packageBuildNumber != null &&
        packageBuildNumber.isNotEmpty &&
        packageBuildNumber != '0') {
      buildNumber = packageBuildNumber;
    } else if (envBuildNumber.isNotEmpty && envBuildNumber != '0') {
      buildNumber = envBuildNumber;
    } else if (packageBuildNumber != null && packageBuildNumber.isNotEmpty) {
      buildNumber = packageBuildNumber;
    } else {
      buildNumber = '0';
    }

    final date = (buildDateOverride != null && buildDateOverride.isNotEmpty)
        ? buildDateOverride
        : envBuildDate;

    return 'v$version#$buildNumber ($date)';
  }
}

