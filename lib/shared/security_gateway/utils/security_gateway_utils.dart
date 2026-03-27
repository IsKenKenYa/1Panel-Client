import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';

CertificateHealthStatus resolveCertificateHealthStatus(String? expiration) {
  final days = daysUntilExpiration(expiration);
  if (days == null) {
    return CertificateHealthStatus.unknown;
  }
  if (days < 0) {
    return CertificateHealthStatus.expired;
  }
  if (days <= 30) {
    return CertificateHealthStatus.expiringSoon;
  }
  return CertificateHealthStatus.healthy;
}

int? daysUntilExpiration(String? expiration) {
  final date = tryParseDate(expiration);
  if (date == null) {
    return null;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(today).inDays;
}

DateTime? tryParseDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.trim());
}

bool domainsRoughlyMatch({
  String? expectedDomain,
  String? certificateDomain,
}) {
  final expected = _normalizeDomain(expectedDomain);
  final actual = _normalizeDomain(certificateDomain);
  if (expected == null || actual == null) {
    return true;
  }
  return actual == expected ||
      actual == '*.$expected' ||
      actual.endsWith('.$expected');
}

String stringifyValue(Object? value) {
  if (value == null) {
    return '-';
  }
  if (value is bool) {
    return value ? 'Enabled' : 'Disabled';
  }
  if (value is List) {
    if (value.isEmpty) {
      return '-';
    }
    return value.join(', ');
  }
  final text = value.toString().trim();
  return text.isEmpty ? '-' : text;
}

List<ConfigDiffItem> buildLabeledDiff({
  required Map<String, Object?> current,
  required Map<String, Object?> next,
  required Map<String, String> labels,
}) {
  final items = <ConfigDiffItem>[];
  for (final entry in labels.entries) {
    final before = stringifyValue(current[entry.key]);
    final after = stringifyValue(next[entry.key]);
    if (before == after) {
      continue;
    }
    items.add(
      ConfigDiffItem(
        field: entry.key,
        label: entry.value,
        currentValue: before,
        nextValue: after,
      ),
    );
  }
  return items;
}

List<RiskNotice> detectConfigContentRisks(String content) {
  final notices = <RiskNotice>[];
  final trimmed = content.trim();
  if (trimmed.isEmpty) {
    notices.add(
      const RiskNotice(
        level: RiskLevel.high,
        title: 'Empty config',
        message: 'Saving an empty config will break the current gateway setup.',
      ),
    );
    return notices;
  }
  final openBraces = '{'.allMatches(content).length;
  final closeBraces = '}'.allMatches(content).length;
  if (openBraces != closeBraces) {
    notices.add(
      const RiskNotice(
        level: RiskLevel.high,
        title: 'Brace mismatch',
        message:
            'The config appears to have unmatched braces. Validate before saving.',
      ),
    );
  }
  if (!content.contains('http')) {
    notices.add(
      const RiskNotice(
        level: RiskLevel.medium,
        title: 'Missing http block',
        message: 'No http block was detected in the config source.',
      ),
    );
  }
  if (content.contains('TODO') || content.contains('FIXME')) {
    notices.add(
      const RiskNotice(
        level: RiskLevel.low,
        title: 'Temporary markers found',
        message: 'The config still contains TODO or FIXME markers.',
      ),
    );
  }
  return notices;
}

String describeRiskLevel(RiskLevel level) {
  switch (level) {
    case RiskLevel.low:
      return 'Low';
    case RiskLevel.medium:
      return 'Medium';
    case RiskLevel.high:
      return 'High';
  }
}

String describeCertificateHealth(CertificateHealthStatus status) {
  switch (status) {
    case CertificateHealthStatus.healthy:
      return 'Healthy';
    case CertificateHealthStatus.expiringSoon:
      return 'Expiring soon';
    case CertificateHealthStatus.expired:
      return 'Expired';
    case CertificateHealthStatus.unknown:
      return 'Unknown';
  }
}

String? _normalizeDomain(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return null;
  }
  final withoutScheme = trimmed
      .replaceFirst('https://', '')
      .replaceFirst('http://', '')
      .split('/')
      .first;
  return withoutScheme.isEmpty ? null : withoutScheme;
}
