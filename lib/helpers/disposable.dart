import 'dart:async';

typedef Disposer = FutureOr Function();

abstract class HasDisposers {
  void registerDisposer(FutureOr dispose());
  void removeDisposer(FutureOr dispose());
}

mixin Disposable implements HasDisposers {
  List<Disposer>? _disposers;

  void registerSubscription(StreamSubscription? subscription) {
    if (subscription != null) {
      registerDisposer(subscription.cancel);
    }
  }

  void registerStream(Stream? stream) {
    if (stream != null) {
      registerDisposer(stream.listen((_) {}, cancelOnError: false).cancel);
    }
  }

  @override
  void removeDisposer(FutureOr dispose()) {
    _disposers!.remove(dispose);
  }

  @override
  void registerDisposer(Disposer callback) {
    _disposers ??= <Disposer>[];
    _disposers!.add(callback);
  }

  Future disposeAll() async {
    final copy = [...?_disposers];
    _disposers?.clear();
    for (final disposer in copy) {
      await disposer.call();
    }
  }
}

extension StreamDisposableMixin<X> on Stream<X> {
  void autodispose(Disposable mixin) {
    mixin.registerStream(this);
  }
}

//
extension StateObserverStream<T> on StreamSubscription<T> {
  void auto(HasDisposers obs) {
    obs.registerDisposer(this.cancel);
  }
}

extension StreamReader<T> on Stream<T> {
  void auto(HasDisposers obs, {FutureOr onItem(T item)?}) {
    this.listen(onItem ?? _doNothing, cancelOnError: false).auto(obs);
  }
}

FutureOr _doNothing<T>(T t) {}
