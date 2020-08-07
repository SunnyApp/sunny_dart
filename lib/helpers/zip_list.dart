import 'dart:math' as math;

class ZipList<T> {
  final Map<int, List<T>> _items = {};
  int _maxSize = 0;

  List<T> _getIndex(int index) {
    _maxSize = math.max(_maxSize, index + 1);
    return _items.putIfAbsent(index, () {
      return <T>[];
    });
  }

  void addAll(Iterable<T> items) {
    var i = 0;
    items.forEach((item) => _getIndex(i++).add(item));
  }

  List<T> get zipped {
    return _items.values.expand((_) => _).toList();
  }
}
