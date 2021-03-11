import 'package:sunny_dart/helpers.dart';
import 'package:uri/uri.dart';

extension StringUriExtensions on String? {
  UriTemplate? toUriTemplate() {
    return this == null ? null : UriTemplate(this!);
  }
}

extension UriTemplateExtensions on UriTemplate? {
  String? merge(final data, [final Object? data2]) {
    if (this == null) {
      return null;
    }

    if (data2 != null && data is String?) {
      return this!.expand({if (data != null) data.toString(): data2});
    } else if (data is Map<String, Object>) {
      return this!.expand(data);
    } else {
      return illegalArg("Must provide a key/value pair or a map");
    }
  }

  String? id(final id) {
    if (this == null) {
      return null;
    }
    assert(id != null);
    return this!.expand({"id": id});
  }
}
