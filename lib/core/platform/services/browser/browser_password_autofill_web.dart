import 'dart:js_interop';

import 'package:web/web.dart' as web;

class BrowserPasswordAutofill {
  static void commit() {
    final forms = web.document.forms;
    for (var index = 0; index < forms.length; index++) {
      final form = forms.item(index) as web.HTMLFormElement;
      final passwords = form.querySelectorAll(
          'input[autocomplete="new-password"], input[autocomplete="current-password"]');
      if (passwords.length == 0) continue;
      if (form.querySelector('input[autocomplete="username"]') == null) {
        final account = web.HTMLInputElement()
          ..type = 'text'
          ..name = 'username'
          ..autocomplete = 'username'
          ..value = 'KenPanel'
          ..readOnly = true
          ..tabIndex = -1;
        account.style
          ..position = 'absolute'
          ..width = '1px'
          ..height = '1px'
          ..clipPath = 'inset(50%)';
        form.prepend(account);
      }
      if (form.querySelector('input[type="submit"], button[type="submit"]') != null) {
        continue;
      }
      // 语义表单使用原生 submit 事件通知密码管理器。
      form
        ..method = 'post'
        ..noValidate = true;
      // 密码仅交给浏览器处理，表单不会向网络提交。
      form.addEventListener('submit', ((web.Event event) {
        event.preventDefault();
      }).toJS, web.AddEventListenerOptions(capture: true, once: true));
      form.requestSubmit();
    }
  }
}
