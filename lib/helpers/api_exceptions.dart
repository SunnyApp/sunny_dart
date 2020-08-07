import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/json.dart';

import 'error_methods.dart';
import 'request_builder.dart';

final Logger _log = Logger("apiExceptions");

abstract class ApiException implements Exception {
  String get message;

  RequestBuilder get builder;

  const factory ApiException.socket(
    SocketException error,
    StackTrace stackTrace, [
    RequestBuilder builder,
  ]) = ApiSocketException;

  const factory ApiException.runtimeError(
    Object error,
    StackTrace stackTrace, [
    RequestBuilder builder,
  ]) = ApiWrappedException;

  factory ApiException.response(int statusCode, String message,
      {RequestBuilder builder}) {
    if (statusCode == 400) {
      return BadRequestException.parsed(message, builder: builder);
    } else {
      return ApiResponseException._(statusCode,
          message: message, builder: builder);
    }
  }

  const ApiException();

  @override
  String toString() => message;
}

class ApiSocketException extends ApiWrappedException {
  const ApiSocketException(this.exception, StackTrace trace,
      [RequestBuilder builder])
      : super(exception, trace, builder);

  final SocketException exception;

  @override
  String get message =>
      "${exception.osError.message}: ${builder?.basePath ?? 'no base url'}";
}

class ApiWrappedException extends ApiException {
  @override
  String get message => "$inner";

  final Object inner;

  final StackTrace stackTrace;

  @override
  final RequestBuilder builder;

  const ApiWrappedException(this.inner, this.stackTrace, [this.builder]);
}

class ApiResponseException extends ApiException {
  final int statusCode;

  @override
  final String message;

  @override
  final RequestBuilder builder;
  ApiErrorPayload _payload;

  ApiResponseException._(this.statusCode, {this.message, this.builder});

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => "$statusCode: $message";

  ApiErrorPayload get payload => _payload ??= ApiErrorPayload.fromJson(message);
}

class BadRequestException extends ApiResponseException {
  List<ValidationError> _validationErrors;

  BadRequestException.builder()
      : _validationErrors = const [],
        super._(400);

  BadRequestException(String message, this._validationErrors,
      {RequestBuilder builder})
      : super._(400, message: message, builder: builder);

  BadRequestException.parsed(String message, {RequestBuilder builder})
      : super._(400, message: message, builder: builder);

  BadRequestException.single(ValidationError error)
      : _validationErrors = [error],
        super._(400, message: error.message);

  BadRequestException.singleField(String path, String message, {String keyword})
      : _validationErrors = [
          ValidationError(
            path: JsonPath.parsed(path),
            message: message,
            keyword: keyword,
          )
        ],
        super._(400, message: message);

  List<ValidationError> get validationErrors {
    return _validationErrors ??= _calculateErrors();
  }

  bool get isNotEmpty => _validationErrors?.isNotEmpty == true;

  List<ValidationError> _calculateErrors() {
    final _ = [
      for (final e in payload.errors)
        if (e.body["error"] is Iterable)
          ValidationError.ofJson(e.body["error"].first)
        else if (e.body is Map)
          ValidationError.ofJson(e.body),
    ];
    return _;
  }

  BadRequestException operator +(final other) {
    if (other is ValidationError) {
      return BadRequestException(this.message, [
        ..._validationErrors,
        other,
      ]);
    } else if (other is Iterable<ValidationError>) {
      return BadRequestException(
          this.message, [..._validationErrors, ...?other]);
    } else if (other is String) {
      return BadRequestException(other, _validationErrors);
    } else if (other is BadRequestException) {
      return BadRequestException(other.message ?? this.message,
          [...this._validationErrors, ...other._validationErrors]);
    } else {
      throw wrongType("other", other, [Iterable, String, BadRequestException]);
    }
  }

  /// Parses all validation errors
  static List<ValidationError> _parseErrors(String message) {
    try {
      final decoded = json.decode(message);
      final Map<String, dynamic> errors =
          decoded["errors"] as Map<String, dynamic>;
      if (errors == null) {
        return const [];
      }
      final mapped = [
        ...errors.entries.expand(
          (entry) {
            final errorPath =
                JsonPath.parsed(entry.key, relativeTo: inputSchemaPath);

            return <ValidationError>[
              if (entry.value is! Iterable)
                ValidationError(
                  path: errorPath,
                  message: "${entry.value}",
                  keyword: "error.unknown",
                  code: "unknown",
                  arguments: [],
                ),
              if (entry.value is Iterable)
                ...entry.value.map(
                  (final error) {
                    return error is Map<String, dynamic>
                        ? ValidationError(
                            path: errorPath,
                            message: error["message"]?.toString(),
                            keyword: error["keyword"]?.toString(),
                            code: error["code"]?.toString(),
                            arguments: error["arguments"] as List,
                          )
                        : ValidationError.ofString(
                            JsonPath.of(error), "$error");
                  },
                ),
            ];
          },
        ),
      ];
      return mapped;
    } catch (e, stack) {
      _log.info("Unable to parse validation errors: $e", e, stack);
      return const [];
    }
  }
}

final inputSchemaPath = JsonPath.parsed("/definitions/inputSchema");

class ValidationError {
  final JsonPath path;
  final String keyword;
  final String message;
  final String debugMessage;
  final String code;
  final List arguments;

  /// Whether the server generated this error.  Generally speaking, we won't clear
  /// out non-server errors because it usually indicates that there's something wrong with
  /// the input.
//  final bool isServerError;

  final dynamic value;

  ValidationError({
    @required this.path,
    this.message,
    this.debugMessage,
    this.code,
    this.keyword,
    this.arguments = const [],
    this.value,
  }) : assert(path != null);

  ValidationError.ofString(
    this.path,
    this.message, {
    this.debugMessage,
    this.arguments = const [],
  })  : code = "unknown",
        keyword = "unknown",
        value = null;

  ValidationError.ofJson(json) : this._ofMap(json as Map<String, dynamic>);

  ValidationError._ofMap(Map<String, dynamic> map)
      : this(
          path: JsonPath.of(
              map["pointerToViolation"]?.toString()?.substring(1) ??
                  map["field"]),
          message: map['message'] as String,
          debugMessage: (map['message'] ?? map['error']) as String,
          code: map['code'] as String,
          keyword: map['keyword'] as String,
          arguments: map['arguments'] as List,
          value: map['value'],
        );

  @override
  String toString() {
    switch (this.code) {
      case requiredCode:
        return "This field is required";
      case typeMismatchCode:
        if (arguments[1] == "NULL") {
          return "This field is required";
        }
        return "Invalid format";
      case parsedCode:
        return "Invalid format";
      case formatCode:
        return "Invalid format";
      default:
        _log.info(
            "$path: ${debugMessage ?? "Falling back to default renderer"} for '$code' error; message: $message");
        return message;
    }
  }

  static const requiredCode = "validation.keyword.required";
  static const typeMismatchCode = "validation.typeMismatch";
  static const parsedCode = "validation.parsed";
  static const formatCode = "validation.keyword.format";

  ValidationError relocate(JsonPath basePath) {
    assert(basePath != null);
    assert(basePath != JsonPath.root(), "Can't relocate to the root. Duh!");
    return ValidationError(
      path: basePath + path,
      message: message,
      debugMessage: debugMessage,
      code: code,
      keyword: keyword,
      arguments: arguments,
      value: value,
    );
  }
}

class ApiErrorPayload {
  final String errorType;
  final List<ApiErrorItem> errors;

  ApiErrorPayload._({this.errorType, this.errors});

  factory ApiErrorPayload.fromJson(final dyn) {
    final map = {};
    if (dyn is String && dyn.startsWith("{")) {
      final decoded = json.decode(dyn) as Map;
      map.addAll(decoded);
    } else if (dyn is Map) {
      map.addAll(dyn);
    } else {
      map['errors'] = ['$dyn'];
    }

    final errors = map['errors'] as List ?? [];
    return ApiErrorPayload._(
      errorType: map['type'] as String ?? 'unknkown',
      errors: [
        for (final err in errors) ApiErrorItem.fromJson(err),
      ],
    );
  }
}

class ApiErrorItem {
  final Map<String, dynamic> _body;
  final String _message;

  ApiErrorItem._({String message, Map body})
      : _message = message,
        _body = {...?body?.map((k, v) => MapEntry("$k", v))};

  Map<String, dynamic> get body => _body ?? const {};

  String get message => _message ?? "$body" ?? "Unknown error";

  factory ApiErrorItem.fromJson(final dyn) {
    if (dyn is Map) {
      return ApiErrorItem._(body: dyn);
    } else if (dyn is String && dyn.startsWith("{")) {
      final map = json.decode(dyn) as Map;
      return ApiErrorItem._(body: map);
    } else {
      return ApiErrorItem._(message: "$dyn");
    }
  }

  @override
  String toString() {
    var str = "ApiError{ ";
    if (_message != null) str += "message: $_message,";
    if (_body != null) str += " error=$_body }";
    return str;
  }
}

extension ErrorList on List<ValidationError> {
  List<ValidationError> embedded(JsonPath basePath) {
    return [...?this.map((err) => err.relocate(basePath))];
  }
}
