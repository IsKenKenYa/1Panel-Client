import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// IndexedDB 通过 structured clone 保存不可导出的 CryptoKey。
class BrowserKeyStore {
  const BrowserKeyStore(this.databaseName);

  final String databaseName;

  Future<web.IDBDatabase> _open() async {
    final request = web.window.indexedDB.open(databaseName, 1);
    request.onupgradeneeded = ((web.Event event) {
      (request.result as web.IDBDatabase).createObjectStore('keys');
    }).toJS;
    return (await _result(request)) as web.IDBDatabase;
  }

  Future<web.CryptoKey?> read() async {
    final database = await _open();
    try {
      final transaction = database.transaction('keys'.toJS);
      return (await _result(transaction.objectStore('keys').get('key'.toJS)))
          as web.CryptoKey?;
    } finally {
      database.close();
    }
  }

  Future<void> write(web.CryptoKey key) async {
    final database = await _open();
    try {
      final transaction = database.transaction('keys'.toJS, 'readwrite');
      final completed = Completer<void>();
      transaction.oncomplete = ((web.Event event) => completed.complete()).toJS;
      transaction.onabort = ((web.Event event) {
        completed.completeError(StateError('浏览器密钥存储事务已经终止'));
      }).toJS;
      transaction.objectStore('keys').put(key, 'key'.toJS);
      await completed.future;
    } finally {
      database.close();
    }
  }

  Future<JSAny?> _result(web.IDBRequest request) {
    final completed = Completer<JSAny?>();
    request.onsuccess =
        ((web.Event event) => completed.complete(request.result)).toJS;
    request.onerror = ((web.Event event) {
      completed.completeError(StateError('IndexedDB 请求失败'));
    }).toJS;
    return completed.future;
  }
}
