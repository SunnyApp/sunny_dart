import 'dart:async';

import 'package:collection/collection.dart';

class _StreamSortSample<T extends Comparable<T>>
    extends StreamTransformerBase<T, List<T>> {
  final int size;

  _StreamSortSample(this.size);

  @override
  Stream<List<T>> bind(Stream<T> stream) {
    StreamSubscription<T>? inbound;
    late StreamController<List<T>> output;

    List<T> sortedBuffer = [];

    void onItem(T item) {
      final isFilled = sortedBuffer.length >= size;
      if (isFilled) {
        if (sortedBuffer.last.compareTo(item) < 1) {
          /// The new item is smaller than the last item;
          return;
        }
      }
      sortedBuffer.add(item);
      insertionSort(sortedBuffer);

      if (isFilled) sortedBuffer.removeLast();
      output.add([...sortedBuffer]);
    }

    void onDone() {
      output.close();
    }

    void onListen() {
      inbound = stream.listen(
        onItem,
        onError: (Object error, StackTrace stack) =>
            output.addError(error, stack),
        onDone: onDone,
        cancelOnError: false,
      );
    }

    output = stream.isBroadcast
        ? StreamController<List<T>>.broadcast(
            sync: true,
            onListen: onListen,
            onCancel: () => inbound?.cancel(),
          )
        : StreamController<List<T>>(
            sync: true,
            onListen: onListen,
            onCancel: () => inbound?.cancel(),
          );

    return output.stream;
  }
}

extension StreamSortSampleExtension<T extends Comparable<T>> on Stream<T> {
  Stream<List<T>> sortSample([int size = 10]) {
    return this.transform(_StreamSortSample(size));
  }
}
