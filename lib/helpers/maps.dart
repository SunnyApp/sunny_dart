import 'package:dartxx/json_path.dart';

import '../json.dart';
import 'functions.dart';

class Maps {
  Maps._();

  static dynamic getByPath(map, JsonPath path) {
    dynamic value = map;
    for (var segment in path.segments) {
      if (value is MapModel) {
        value = value[segment];
      } else if (value is Map) {
        value = value[segment];
      } else {
        throw Exception("Illegal path: $path at segment $segment.  Expected Map or MModel but found ${value.runtimeType}");
      }
      if (value == null) {
        return null;
      }
    }
    return value;
  }

  static void setByPath(map, JsonPath path, value) {
    final lastSegment = path.last;
    final parents = path.chop;
    var container = map;
    for (var segment in parents.segments) {
      var child = container[segment];
      if (child == null && container is! Map) {
        throw Exception("Missing container in heirarchy.  Full path: $path.  Error found at segment $segment");
      } else if (child == null) {
        child = <String, dynamic>{};
        container[segment] = child;
      }
      container = child;
    }
    if (value == null && container is Map) {
      container.remove(lastSegment);
    } else {
      container[lastSegment] = value;
    }
  }
}

/// This assumes that the data coming in is a map, list, or primitive (json).
dynamic deepClone(final _in) {
  if (_in is Map) {
    return deepCloneMap(_in);
  } else if (_in is Iterable) {
    return deepCloneList(_in);
  } else if (_in is MapModel) {
    return deepClone(_in.wrapped);
  } else if (_in is bool) {
    return _in;
  } else if (_in is String) {
    return _in;
  } else if (_in is num) {
    return _in;
  } else if (_in == null) {
    // okay... return it
    return _in;
  } else {
    illegalState("Bad argument type $_in -> ${_in.runtimeType}");
  }
}

/// This assumes that the data coming in is a map, list, or primitive (json).
Map<String, dynamic> deepCloneMap(final Map _in) {
  return <String, dynamic>{..._in.map((key, value) => MapEntry("$key", deepClone(value)))};
}

/// This assumes that the data coming in is a map, list, or primitive (json).
List<dynamic> deepCloneList(final Iterable<dynamic> _in) {
  return [..._in.map((item) => deepClone(item))];
}
