import 'dart:async';

import 'package:flutter/foundation.dart';

mixin Disposable {
  List<VoidCallback> _disposers;

  registerSubscription(StreamSubscription subscription) {
    if (subscription != null) {
      registerDisposer(subscription.cancel);
    }
  }

  registerDisposer(VoidCallback callback) {
    _disposers ??= [];
    _disposers.add(callback);
  }

  disposeAll() {
    _disposers?.forEach((fn) => fn?.call());
    _disposers?.clear();
  }
}
