import 'dart:async';

typedef Disposer = FutureOr Function();

mixin Disposable {
  List<Disposer> _disposers;

  void registerSubscription(StreamSubscription subscription) {
    if (subscription != null) {
      registerDisposer(subscription.cancel);
    }
  }

  void registerStream(Stream stream) {
    if (stream != null) {
      registerDisposer(stream.listen((_) {}, cancelOnError: false).cancel);
    }
  }

  void registerDisposer(Disposer callback) {
    _disposers ??= <Disposer>[];
    _disposers.add(callback);
  }

  Future disposeAll() async {
    for (final disposer in _disposers) {
      await disposer?.call();
    }
    _disposers?.clear();
  }
}

extension StreamDisposableMixin<X> on Stream<X> {
  void autodispose(Disposable mixin) {
    mixin.registerStream(this);
  }
}
