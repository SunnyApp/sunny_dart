import 'dart:async';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:sunny_dart/extensions.dart';
import 'package:sunny_dart/helpers.dart';
//
import '../typedefs.dart';
import 'value_stream.dart';

/// The AsyncValueStream is used as a clearing house when more than one consumer need to update a single value, but
/// you want to control the lifecycle around updates, so that older updates that take longer to calculate don't clobber
/// newer values.
///
/// This allows for synchronous or asynchronous updates, but the last update to start will always "win", even if
/// if finishes before another update that started before it.
///
/// Updates may be asynchronous, so they are queued up, and then processed in order.  The current
/// value is tracked as [current]
class AsyncValueStream<T> with Disposable implements ValueStream<T?> {
  final StreamController<UpdateRequest<T>> _requests =
      StreamController(sync: true);

  /// The current incremented count;
  int _requestId = 1;

  /// The requestId that produced the latest accepted value
  int _accepted = 0;

  /// The current computed value
  T? _current;

  /// The debug name for this stream
  @override
  final String debugName;

  /// The update stream where we send all the updates
  final StreamController<T?> _after;

  /// Our logger
  final Logger log;

  /// The in flight request, if there is any
  UpdateRequest<T>? _inflight;

  /// Whether we've got at least one value
  bool _isResolved = false;

  final bool isUnique;

  /// How updates are locked.
  final ClearingHouseMode mode;

  @override
  Stream<T?> get after => _after.stream;

  /// This returns the next calculated value.  It's reset each time
  final SafeCompleter<T> _nextFrame = SafeCompleter<T>.stopped();

  AsyncValueStream({
    String? debugName,
    T? initialValue,
    this.isUnique = true,
    this.mode = ClearingHouseMode.AllowSynchronousValues,
  })  : debugName = debugName ?? "asyncValueStream.$T",
        log = Logger(debugName ?? "asyncValueStream.$T"),
        _after = StreamController.broadcast() {
    /// Listen to requests stream but process requests in chunks
    _requests.stream.asyncMapBuffer((requests) async {
      final latestRequest = (this._inflight = requests.max());

      /// Cancel any requests that aren't the latest
      await requests
          .where((req) => req != latestRequest)
          .map((req) => req.cancel())
          .awaitAll();

      if (latestRequest.requestId < _accepted) {
        log.warning(
            "Skipping ${latestRequest.requestId} because it was too stale");

//        _nextFrame
//          ..start()
//          ..complete(_current)
//          ..reset();
        return;
      } else {
        /// Start that request
        final thisRequestId = latestRequest.requestId;
        _nextFrame.start();
        final cancellable = latestRequest.start();
        try {
          /// And wait for either completion or cancellation
          final result = await cancellable
              ?.valueOrCancellation(const UpdateResult.cancelled());
          if (result?.isCompleted != true) {
            log.info("Ignoring cancelled request ${latestRequest.requestId}");
          } else {
            log.fine(
                "Request ${latestRequest.requestId} completed with ${result?.value}");
            final mostRecentRequest = _requestId - 1;
            if (mostRecentRequest <= thisRequestId) {
              log.fine(mostRecentRequest < thisRequestId
                  ? "Older request $mostRecentRequest will be superceded by $thisRequestId"
                  : "Request $thisRequestId is the latest");
              _inflight = null;
              _internalUpdate(latestRequest.requestId, result?.value);
              _nextFrame
                ..start()
                ..complete(current)
                ..reset();
            } else {
              log.fine(
                  "Expecting a newer value $mostRecentRequest than $thisRequestId, so we're not going to complete.  Logging result as _current");
              _current = result!.value;
              _isResolved = true;
            }
          }
        } catch (e, stack) {
          log.severe("Error updating result: $e", e, stack);
          _nextFrame
            ..start()
            ..complete(current)
            ..reset();
        }
      }
    }).autodispose(this);

    if (initialValue != null) {
      this.syncUpdate(initialValue);
    }
  }

  T? get current => _current;

  /// When setting a value in this way, we can assume that this update is the latest, and should cancel out any
  /// other in-flight requests
  FutureOr<T> syncUpdate(T current) {
    switch (mode) {
      case ClearingHouseMode.AllowSynchronousValues:
        final requestId = _requestId++;
        // Cancel any in-flight update, then update (after the cancellation completes)

        if (_inflight != null) {
          log.info("Cancelling inflight update");
          _inflight!.cancel().ignore();
          _inflight = null;
        }
        _internalUpdate(requestId, current);
        _nextFrame
          ..start()
          ..complete(current)
          ..reset();

        return future;
      default:
        if (_queue(() => current, debugLabel: "sync: $current")) {
          return future;
        } else {
          return Future.value(_current);
        }
    }
  }

  Future<T?> update(Producer<T> current,
      {String? debugLabel, Duration? timeout, bool? fallbackToCurrent}) {
    bool isQueued = _queue(current, debugLabel: debugLabel);

    final value = isQueued ? nextUpdate : Future.value(this._current);
    return timeout == null
        ? value
        : value.timeout(
            timeout,
            onTimeout:
                fallbackToCurrent == true ? (() => this._current!) : null,
          );
  }

  bool _queue(Producer<T> producer, {String? debugLabel}) {
    final requestId = _requestId++;
    log.fine("Queued request: $requestId");
    if (!_requests.isClosed) {
      _requests
          .add(UpdateRequest(producer, requestId, log, debugLabel: debugLabel));
      _nextFrame.start();
      return true;
    } else {
      return false;
    }
  }

  /// Updates the internal values and notifies listeners
  void _internalUpdate(int requestId, T? current) {
    if (_accepted >= requestId) {
      log.info(
          'Update $requestId completed, but was older than $_accepted => value = $current');
      return;
    } else {
      _accepted = requestId;
      _current = current;
    }
    log.finer("Emitting $current");
    _after.add(current);
    _isResolved = true;
  }

  /// Waits until the next update completes
  Future<T> get nextUpdate {
    return _nextFrame.isActive
        ? _nextFrame.future.timeout(5.second, onTimeout: () {
            log.warning("Timeout on update - sending current value: $_current");
            _nextFrame
              ..start()
              ..complete(_current)
              ..reset();
            return _current!;
          })
        : Future.value(_current);
  }

  @override
  Future<T> get future =>
      _nextFrame.isActive ? _nextFrame.future : Future.value(_current);

  @override
  T? resolve([T? ifAbsent]) => current ?? ifAbsent;

  @override
  FutureOr<T?> get() => _isResolved ? current : nextUpdate as FutureOr<T?>;

  @override
  ValueStream<R> map<R>(R mapper(T? input)) {
    return HStream(mapper(current), after.map(mapper));
  }

  @override
  bool get isFirstResolved => _isResolved;

  Future dispose() async {
    await future;
    await _requests.close();
    await _after.close();
    await disposeAll();
  }
}

class UpdateResult<T> {
  final T? value;
  final bool isCompleted;

  const UpdateResult.value(this.value) : isCompleted = true;

  const UpdateResult.cancelled()
      : value = null,
        isCompleted = false;
}

class UpdateRequest<T>
    with EquatableMixin
    implements Comparable<UpdateRequest> {
  final Producer<T> producer;
  final int requestId;
  final Logger log;
  CancelableOperation<UpdateResult<T>>? operation;
  bool _isCancelled = false;
  String? debugLabel;

  UpdateRequest(this.producer, this.requestId, this.log, {this.debugLabel});

  CancelableOperation<UpdateResult<T>>? start() {
    if (_isCancelled) return null;
    assert(operation == null);
    return operation ??= CancelableOperation<UpdateResult<T>>.fromFuture(
        producer().futureValue().then((_) {
          return UpdateResult.value(_);
        }).catchError((err, StackTrace stack) {
          log.severe("Error $err", err, stack);
        }), onCancel: () {
      _isCancelled = true;
    });
  }

  Future cancel() async {
    log.info("Cancelling request $requestId: (${debugLabel ?? 'no details'})");
    await operation?.cancel();
    _isCancelled = true;
  }

  @override
  int compareTo(UpdateRequest other) {
    return this.requestId.compareTo(other.requestId);
  }

  @override
  List<Object> get props => [requestId];
}

enum ClearingHouseMode {
  /// If this mode is used, the system will not start new requests until the previous has completed, even if they are
  /// synchronous
  AllowSynchronousValues,

  /// If this mode is used, the system will not start new requests until the previous has completed, even if they are
  /// synchronous
  LockUpdateStart,

  /// If this mode is used, the system will start requests, but will keep track of their order, and any newer request
  /// will override an older request, even if the older request finishes first.

  /// Note: this mode does not attempt to cancel any prior actions
  LockUpdateCompletion
}
