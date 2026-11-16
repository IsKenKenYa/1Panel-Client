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
}
