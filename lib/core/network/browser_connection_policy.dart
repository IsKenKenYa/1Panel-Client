enum BrowserConnectionIssue { invalidAddress }

class BrowserConnectionPolicy {
  const BrowserConnectionPolicy._();

  static BrowserConnectionIssue? issue(String address) {
    final uri = Uri.tryParse(address.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !const ['https', 'http'].contains(uri.scheme)) {
      return BrowserConnectionIssue.invalidAddress;
    }
    return null;
  }

  static Uri panelWebEntrance(String address, String? securityEntrance) {
    if (issue(address) != null) throw ArgumentError.value(address, 'address');
    final base = Uri.parse(address.trim());
    final entrance = securityEntrance?.trim() ?? '';
    final segments = entrance.isEmpty ? base.pathSegments : entrance.split('/');
    return Uri.parse(base.origin).replace(
      pathSegments: segments.where((part) => part.isNotEmpty),
    );
  }
}
