import 'dart:async';

typedef ListFactory<T> = List<T> Function();
typedef Factory<T> = T Function();
typedef Getter<T> = T Function();
typedef Loader<K, T> = FutureOr<T> Function(K key);
typedef Consumer<T> = dynamic Function(T input);
typedef Consume<T> = void Function(T input);
typedef Producer<T> = FutureOr<T> Function();
typedef Mapping<F, T> = T Function(F from);
typedef Formatter<T> = String Function(T from);

typedef Converter<T> = T Function(String input);
typedef Transformer<F, T> = T Function(F from);
typedef DynTransformer<T> = T Function(dynamic from);
