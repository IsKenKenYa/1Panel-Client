import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:web/web.dart' as web;

import 'browser_key_store.dart';

class BrowserVault {
  BrowserVault({this.boxName = 'onepanel_browser_vault'});

  static final instance = BrowserVault();
  static const _iterations = 600000;
  static const _verification = 'onepanel-browser-vault-v1';
  final String boxName;
  late Box<dynamic> _box;
  web.CryptoKey? _key;
  Future<void>? _initialization;
  bool isPersistent = false;

  bool get isConfigured => _box.containsKey('metadata');
  bool get isUnlocked => _key != null;
  bool get usesBrowserKey =>
      isConfigured && (_box.get('metadata') as Map)['mode'] == 'browser';

  Future<void> initialize() async {
    if (_initialization != null) return _initialization!;
    _initialization = _initialize();
    try {
      await _initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    if (!web.window.isSecureContext) {
      throw StateError('浏览器存储需要 HTTPS 或 localhost');
    }
    _box = await Hive.openBox<dynamic>(boxName);
    if (!isConfigured && _box.isNotEmpty) {
      throw StateError('浏览器加密存储缺少 metadata');
    }
    final storage = web.window.navigator.storage;
    if (!storage.isUndefinedOrNull && storage.has('persisted')) {
      isPersistent = (await storage.persisted().toDart).toDart;
    }
  }

  Future<bool> requestPersistence() async {
    final storage = web.window.navigator.storage;
    if (storage.isUndefinedOrNull || !storage.has('persist')) return false;
    isPersistent = (await storage.persist().toDart).toDart;
    return isPersistent;
  }

  Future<void> unlock(String password) async {
    await initialize();
    if (password.length < 12 && !isConfigured) {
      throw ArgumentError('本地密码至少需要 12 个字符');
    }
    if (usesBrowserKey) {
      throw StateError('当前本地存储使用浏览器密钥');
    }
    final metadata = isConfigured
        ? Map<String, dynamic>.from(_box.get('metadata') as Map)
        : null;
    if (metadata != null &&
        (metadata['version'] != 1 || metadata['iterations'] != _iterations)) {
      throw StateError('无法识别浏览器加密存储格式');
    }
    final salt = metadata == null
        ? _randomBytes(16)
        : base64Decode(metadata['salt'] as String);
    if (salt.length != 16) throw StateError('浏览器存储的 salt 无效');
    final subtle = web.window.crypto.subtle;
    final material = await subtle
        .importKey('raw', _bytes(password).toJS, 'PBKDF2'.toJS, false,
            ['deriveKey'.toJS].toJS)
        .toDart;
    final key = (await subtle
        .deriveKey(
          {
            'name': 'PBKDF2',
            'salt': salt.toJS,
            'iterations': _iterations,
            'hash': 'SHA-256',
          }.jsify()!,
          material,
          {'name': 'AES-GCM', 'length': 256}.jsify()!,
          false,
          ['encrypt'.toJS, 'decrypt'.toJS].toJS,
        )
        .toDart) as web.CryptoKey;
    await _verifyOrCreate(key, metadata, {
      'version': 1,
      'mode': 'password',
      'iterations': _iterations,
      'salt': base64Encode(salt),
    });
  }

  Future<void> unlockWithBrowserKey() async {
    await initialize();
    if (isConfigured && !usesBrowserKey) {
      throw StateError('当前本地存储需要密码解锁');
    }
    final store = BrowserKeyStore('${boxName}_keys');
    var key = await store.read();
    if (key == null) {
      if (isConfigured) throw StateError('浏览器解密密钥缺失');
      key = (await web.window.crypto.subtle
          .generateKey({'name': 'AES-GCM', 'length': 256}.jsify()!, false,
              ['encrypt'.toJS, 'decrypt'.toJS].toJS)
          .toDart) as web.CryptoKey;
      await store.write(key);
    }
    final metadata = isConfigured
        ? Map<String, dynamic>.from(_box.get('metadata') as Map)
        : null;
    await _verifyOrCreate(key, metadata, {'version': 1, 'mode': 'browser'});
  }

  Future<void> _verifyOrCreate(web.CryptoKey key,
      Map<String, dynamic>? metadata, Map<String, dynamic> fields) async {
    if (metadata == null) {
      final verification = await _encrypt(key, 'metadata', _verification);
      await _box.put('metadata', {...fields, 'verification': verification});
    } else {
      if (metadata['version'] != 1 ||
          await _decrypt(key, 'metadata', metadata['verification'] as Map) !=
              _verification) {
        throw StateError('浏览器加密存储校验失败');
      }
    }
    _key = key;
  }

  web.CryptoKey get _unlockedKey =>
      _key ?? (throw StateError('浏览器加密存储尚未解锁'));

  Future<String?> read(String key) async {
    final cipherKey = _unlockedKey;
    final value = _box.get('entry:$key');
    return value == null ? null : _decrypt(cipherKey, key, value as Map);
  }

  Future<void> write(String key, String? value) async {
    if (value == null) return delete(key);
    final encrypted = await _encrypt(_unlockedKey, key, value);
    await _box.put('entry:$key', encrypted);
  }

  Future<void> delete(String key) async {
    _unlockedKey;
    await _box.delete('entry:$key');
  }

  Future<void> deleteAll() async {
    _unlockedKey;
    await _box.deleteAll(
        _box.keys.where((key) => key.toString().startsWith('entry:')).toList());
  }

  void lock() => _key = null;

  Future<Map<String, String>> _encrypt(
      web.CryptoKey key, String name, String value) async {
    final iv = _randomBytes(12);
    final encrypted = (await web.window.crypto.subtle
        .encrypt(_algorithm(iv, name), key, _bytes(value).toJS)
        .toDart) as JSArrayBuffer;
    return {
      'iv': base64Encode(iv),
      'ciphertext': base64Encode(encrypted.toDart.asUint8List()),
    };
  }

  Future<String> _decrypt(web.CryptoKey key, String name, Map value) async {
    final iv = base64Decode(value['iv'] as String);
    final ciphertext = base64Decode(value['ciphertext'] as String);
    if (iv.length != 12 || ciphertext.length < 16) {
      throw StateError('浏览器加密数据格式无效');
    }
    final decrypted = (await web.window.crypto.subtle
        .decrypt(_algorithm(iv, name), key, ciphertext.toJS)
        .toDart) as JSArrayBuffer;
    return utf8.decode(decrypted.toDart.asUint8List());
  }

  JSObject _algorithm(Uint8List iv, String name) => {
        'name': 'AES-GCM',
        'iv': iv.toJS,
        'additionalData': _bytes('onepanel:v1:$name').toJS,
        'tagLength': 128,
      }.jsify()! as JSObject;

  Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

  Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    web.window.crypto.getRandomValues(bytes.toJS);
    return bytes;
  }
}
