import 'package:sunny_dart/json/m_literal.dart';

import '../helpers.dart';

/// Represents a json-pointer - can be used to do json-pointer operations on [MModel] instances.
///
/// [T] represents the type of data expected at this pointer
class JsonPath<T> extends MLiteral<String> {
  final List<String> segments;
  final String path;

  const JsonPath._(this.segments, this.path) : super(path);

  const JsonPath.internal(this.segments, this.path) : super(path);
  static const Root = JsonPath._([], "/");

  const JsonPath.root()
      : segments = const [],
        path = "/",
        super("/");

  JsonPath.segments(List<String> segments)
      : this._(List.unmodifiable(segments), _toPathName(segments));

  factory JsonPath.fromJson(json) => JsonPath<T>.parsed("$json");

  factory JsonPath.parsed(String value, {JsonPath? relativeTo}) {
    final _segments = _parsePath(value);
    final path =
        JsonPath<T>._(List.unmodifiable(_segments), _toPathName(_segments));
    if (relativeTo != null) {
      return path.relativize<T>(relativeTo);
    } else {
      return path;
    }
  }

  factory JsonPath.of(dynamic from, {JsonPath? relativeTo}) {
    if (from is JsonPath && relativeTo != null) {
      return from.relativize(relativeTo).cast<T>();
    } else if (from is JsonPath<T> && relativeTo == null) {
      return from.cast<T>();
    } else if (from == null) {
      return JsonPath.root();
    } else {
      return JsonPath.parsed("$from", relativeTo: relativeTo);
    }
  }

  JsonPath<TT> cast<TT>() {
    return JsonPath<TT>._(segments, path);
  }

  /// The last segment in the path
  String get last => segments.last;

  /// The first segment in the path
  String get first => segments.first;

  int get length => segments.length;

  /// Whether this path starts with another [JsonPath] instance.
  bool startsWith(JsonPath otherPath) {
    return path.startsWith(otherPath.path);
  }

  /// Returns an immutable copy of this path, with the last path segment removed
  JsonPath get chop => JsonPath.segments(chopList(segments));

  JsonPath<TT> relativize<TT>(JsonPath<dynamic> other) {
    final segments = <String>[];
    final i = this.segments.iterator;
    final i2 = other.segments.iterator;
    bool matches = true;
    while (i.moveNext()) {
      if (matches && i2.moveNext()) {
        if (i.current == i2.current) {
          continue;
        } else {
          matches = false;
        }
      }

      segments.add(i.current);
    }

    return JsonPath<TT>.segments(segments);
  }

  dynamic operator [](int index) {
    return segments[index];
  }

  @override
  String toString() => path;

  dynamic toJson() => path;

  String toKey() {
    return uncapitalize(segments.map(capitalize).join(""));
  }
}

List<String> _parsePath(String? path) {
  if (path == null) return [];
  if (path.startsWith("/")) path = path.substring(1);
  return [...path.split("/")];
}

String _toPathName(Iterable<String> segments) => "/" + segments.join("/");

extension JsonPathOperatorNullExtensions<T> on JsonPath<T>? {
  JsonPath<T> get self => this ?? const JsonPath.root();
  bool get isNullOrRoot => this == null || this!.segments.isEmpty;
}

extension JsonPathOperatorExtensions<T> on JsonPath<T> {
  JsonPath operator +(path) {
    if (path is JsonPath) {
      return self.plus(path.self);
    } else {
      return self.plus(JsonPath.of(path));
    }
  }

  /// Whether this path is empty, eg "/"
  bool get isEmpty => segments.isNotEmpty != true;

  JsonPath<T> get verifyNotRoot =>
      isNotRoot ? this : illegalState("Expected ${this} to not be root");
  bool get isNotRoot => self.segments.isNotEmpty;

  JsonPath<TT> plus<TT>(JsonPath<TT> path) {
    final self = this.self;
    if (self.isEmpty) {
      return path;
    }
    if (path.self.isEmpty) {
      return this.cast();
    }
    return JsonPath<TT>._(this.self.segments + path.self.segments,
        this.self.path + path.self.path);
  }
}
