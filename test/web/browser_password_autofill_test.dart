@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/platform/services/browser_password_autofill.dart';
import 'package:web/web.dart' as web;

void main() {
  test('密码表单提交被阻止，标准自动填充字段保留至提交时', () {
    final form = web.HTMLFormElement();
    final password = web.HTMLInputElement()
      ..type = 'password'
      ..autocomplete = 'new-password'
      ..name = 'new-password'
      ..value = 'a';
    form.append(password);
    web.document.body!.append(form);
    var submitted = false;
    form.addEventListener('submit', ((web.Event event) {
      submitted = true;
      expect(event.defaultPrevented, isTrue);
      expect(form.method, 'post');
      expect(password.value, 'a');
      final account = form.querySelector('input[autocomplete="username"]')
          as web.HTMLInputElement;
      expect(account.value, 'KenPanel');
    }).toJS);
    try {
      BrowserPasswordAutofill.commit();
      expect(submitted, isTrue);
    } finally {
      form.remove();
    }
  });
}
