enum BrowserConnectionIssue { invalidAddress, httpsRequired }

class BrowserConnectionPolicy {
  const BrowserConnectionPolicy._();

  static BrowserConnectionIssue? issue(String address, {Uri? application}) {
    final uri = Uri.tryParse(address.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !const ['https', 'http'].contains(uri.scheme)) {
      return BrowserConnectionIssue.invalidAddress;
    }
    final origin = application ?? Uri.base;
    final localDevelopment = origin.scheme == 'http' &&
        const ['localhost', '127.0.0.1', '::1'].contains(origin.host);
    if (uri.scheme != 'https' && !localDevelopment) {
      return BrowserConnectionIssue.httpsRequired;
    }
    return null;
  }
}
