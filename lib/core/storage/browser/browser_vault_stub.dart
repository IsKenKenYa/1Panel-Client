class BrowserVault {
  BrowserVault({String boxName = 'onepanel_browser_vault'});

  static final instance = BrowserVault();

  bool get isConfigured => throw UnsupportedError('Browser storage required');
  bool get isUnlocked => throw UnsupportedError('Browser storage required');
  bool get usesBrowserKey => throw UnsupportedError('Browser storage required');
  bool get isPersistent => throw UnsupportedError('Browser storage required');

  Future<void> initialize() async =>
      throw UnsupportedError('Browser storage required');
  Future<void> unlock(String password) async =>
      throw UnsupportedError('Browser storage required');
  Future<void> unlockWithBrowserKey() async =>
      throw UnsupportedError('Browser storage required');
  Future<bool> requestPersistence() async =>
      throw UnsupportedError('Browser storage required');
  Future<String?> read(String key) async =>
      throw UnsupportedError('Browser storage required');
  Future<void> write(String key, String? value) async =>
      throw UnsupportedError('Browser storage required');
  Future<void> delete(String key) async =>
      throw UnsupportedError('Browser storage required');
  Future<void> deleteAll() async =>
      throw UnsupportedError('Browser storage required');
  void lock() => throw UnsupportedError('Browser storage required');
}
