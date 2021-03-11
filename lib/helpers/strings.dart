import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:uuid/uuid.dart';
import 'lists.dart';

bool isPhone(String input) {
  return input.contains(RegExp("^[0-9\-\s\+\(\)]+\$")) &&
      input.replaceAll(RegExp("[^0-9]+"), "").length > 6;
}

String buildString(void builder(StringBuffer buffer)) {
  final buffer = StringBuffer();
  builder(buffer);
  return buffer.toString();
}

class StringJoiner {
  final String join;
  var str = "";

  StringJoiner(String? join) : join = join ?? ", ";

  StringJoiner operator +(final value) {
    if (value is Iterable) {
      value.forEach((v) => this + v);
      return this;
    }
    if (value == null || value == '') return this;
    String s = '';
    if (value is String) {
      s = value;
    } else {
      s = value.toString();
    }

    if (s.isEmpty) return this;
    if (str.isNotEmpty) str += join;
    str += s;

    return this;
  }

  @override
  String toString() {
    return str;
  }
}

String joinString(void builder(StringJoiner buffer), [String? separator]) {
  final buffer = StringJoiner(separator);
  builder(buffer);
  return buffer.toString();
}

String? nonBlank(String? input) {
  if (input?.trim().isNotEmpty != true) return null;
  return input;
}

String repeat(String source, int times) {
  String value = "";
  for (var i = 0; i < times; i++) {
    value += source;
  }
  return value;
}

String? trim(String? target, List<String>? chars,
    {bool trimWhitespace = true}) {
  if (target == null) {
    return null;
  }
  var manipulated = target;
  if (trimWhitespace) {
    manipulated = manipulated.trim();
  }
  chars?.forEach((c) {
    if (manipulated.endsWith(c)) {
      manipulated = manipulated.substring(0, manipulated.length - c.length);
    }
    if (manipulated.startsWith(c)) {
      manipulated = manipulated.substring(1);
    }
  });
  return manipulated;
}

String? joinOrNull(Iterable<String?>? items, {String separator = " "}) {
  if (items?.isNotEmpty == true) {
    return items!.join(separator);
  } else {
    return null;
  }
}

bool startsWith(String? first, String? second, {bool ignoreCase = true}) {
  if (second?.isNotEmpty != true) return false;
  if (ignoreCase) {
    first = first?.toLowerCase();
    second = second?.toLowerCase();
  }
  return first?.startsWith(second!) == true;
}

bool anyMatch(String? subject, List<String> potentials,
    {bool caseSensitive = true}) {
  if (subject == null) return false;
  if (caseSensitive != true) {
    subject = subject.toLowerCase();
  }
  for (var p in potentials) {
    if (caseSensitive != true) {
      p = p.toLowerCase();
    }

    if (p == subject) return true;
  }
  return false;
}

String? capitalize(String? source) {
  if (source == null || source.isEmpty) {
    return source;
  } else {
    return source[0].toUpperCase() + source.substring(1);
  }
}

String? uncapitalizeNull(String? source) {
  if (source == null || source.isEmpty) {
    return source;
  } else {
    return source[0].toLowerCase() + source.substring(1);
  }
}

String uncapitalize(String source) {
  if (source.isEmpty) {
    return source;
  } else {
    return source[0].toLowerCase() + source.substring(1);
  }
}

String? splitSnakeCase(String? source) => source?.replaceAll("_", " ");

String? properCase(String? source) =>
    source?.split(" ").map(capitalize).join(" ");

String? defaultIfEmpty(String? primary, String ifBlank) =>
    (primary?.trim().isNotEmpty == true) ? primary : ifBlank;

bool isNullOrBlank(String? input) {
  return input == null || input.trim().isEmpty == true;
}

String? firstNonEmpty(Iterable<String?>? strings) {
  if (strings == null) {
    return null;
  } else {
    for (final string in strings) {
      if (string != null && string.isNotEmpty) {
        return string;
      }
    }
    return null;
  }
}

R? withString<R>(Iterable<String?> strings, R Function(String string) handler) {
  for (final string in strings) {
    if (string != null && string.isNotEmpty) {
      return handler(string);
    }
  }
  return null;
}

String uuid() {
  return _uuid.v4();
}

List<int?> uuidb() {
  var buf = List<int?>.filled(16, null); // -> []
  _uuid.v4buffer(buf as List<int>);
  return buf;
}

const chars = "abcdefghijklmnopqrstuvwxyz";
const numbers = "0123456789";

String randomString(int length, {bool? numbersOnly, Random? rnd}) {
  rnd ??= Random(DateTime.now().millisecondsSinceEpoch);
  String result = "";
  final source = numbersOnly == true ? numbers : chars;
  for (var i = 0; i < length; i++) {
    result += source[rnd.nextInt(source.length)];
  }
  return result;
}

final _uuid = Uuid();

final Pattern notLetterOrNumber = RegExp("[^A-Za-z0-9]+");

String? initials(from, {int max = 2}) {
  Iterable<String> _sanitize(source) {
    if (source == null) return [];
    if (source is Iterable) {
      return Lists.compact(source.expand((item) => _sanitize(item)));
    }

    return source
        .toString()
        .split(" ")
        .map((word) => word.replaceAll(notLetterOrNumber, ""));
  }

  final initials = _sanitize(from)
      .where((word) => word.isNotEmpty)
      .take(max)
      .map((word) => word[0].toUpperCase())
      .join("");
  if (initials.isEmpty) {
    return null;
  } else {
    return initials;
  }
}

String? findInitials(List<dynamic>? sources) => sources
    ?.map(initials)
    .firstWhere((initials) => initials?.isNotEmpty == true);

class WordBuilder {
  final int lineLength;

  String _currentLine = "";
  final List<String> _results = [];

  WordBuilder({required this.lineLength}) : assert(lineLength > 0);

  void addAll(
      [String? line1,
      String? line2,
      String? line3,
      String? line4,
      String? line5,
      String? line6]) {
    if (line1?.isNotEmpty == true) {}
  }

  WordBuilder operator +(String item) {
    addLine(item);
    return this;
  }

  void addLine(String? single, {String? separator}) {
    if (single == null || single == "") return;
    if (_currentLine.length + single.length + (separator?.length ?? 0) >
        lineLength) {
      if (_currentLine.isNotEmpty) _results.add(_currentLine);
      _currentLine = single;
    } else {
      _currentLine += (separator ?? "") + single;
    }
  }

  List<String> complete() {
    if (_currentLine.isNotEmpty) {
      _results.add(_currentLine);
    }
    return List.unmodifiable(_results);
  }
}

final Pattern phoneNumberSplitCharacters = RegExp("[\\s\-\(\)\+]");

Iterable<String> tokenizePhoneNumber(String? phoneNumber) {
  final split =
      Lists.compactEmpty(phoneNumber?.split(phoneNumberSplitCharacters));
  split.remove("1");
  final joined = split.join("");
  return [if (joined.isNotEmpty) joined, ...split];
}

String md5(Uint8List bytes) {
  return crypto.md5.convert(bytes).toString();
}
