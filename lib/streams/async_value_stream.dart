import 'dart:async';

import 'package:async/async.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:sunny_dart/extensions.dart';
import 'package:sunny_dart/helpers/disposable.dart';

import '../typedefs.dart';
import 'value_stream.dart';

/// The AsyncValueStream is used as a clearing house when more than one consumer need to update a single value, but
/// you want to control the lifecycle around that value.
///
/// This allows for synchronous or asynchronous updates, but the latest update in line will always "win", even if
/// if finishes after another later one.
///
/// Updates may be asynchronous, so they are queued up, and then processed in order.  The current
/// value is tracked as [current]
class AsyncValueStream<T> with Disposable implements ValueStream<T> {
  final StreamController<UpdateRequest<T>> _requests = StreamController(sync: true);

  /// The current incremented count;
  int _requestId = 1;

  /// The requestId that produced the latest accepted value
  int _accepted = 0;

  /// The current computed value
  T _current;

  /// The debug name for this stream
  final String debugName;

  /// The update stream where we send all the updates
  final StreamController<T> _after;

  /// Our logger
  final Logger log;

  /// The in flight request, if there is any
  UpdateRequest<T> _inflight;

  /// Whether we've got at least one value
  bool _isResolved = false;

  final bool isUnique;

  /// How updates are locked.
  final ClearingHouseMode mode;

  Stream<T> get after => _after.stream;

  AsyncValueStream(
      {String debugName,
      T initialValue,
      this.isUnique = true,
      this.mode = ClearingHouseMode.AllowSynchronousValues,
      // Allows us to transform the request stream, add debouncing, etc.
      Stream<UpdateRequest<T>> transform(Stream<UpdateRequest<T>> input)})
      : debugName = debugName ?? "asyncValueStream.$T",
        log = Logger(debugName ?? "asyncValueStream.$T"),
        _after = StreamController.broadcast() {
    /// Listen to requests stream but process requests in chunks
    _requests.stream.asyncMapBuffer((requests) async {
      final latestRequest = this._inflight = requests.max();

      /// Cancel any requests that aren't the latest
      requests.where((req) => req != latestRequest).forEach((req) => req.cancel());

      if (latestRequest.requestId < _accepted) {
        log.warning("Skipping ${latestRequest.requestId} because it was too stale");
        return;
      }

      /// Start that request
      final cancellable = latestRequest.start();
      try {
        /// And wait for either completion or cancellation
        final result = await cancellable?.valueOrCancellation(const UpdateResult.cancelled());
        if (result?.isCompleted != true) {
          log.info("Ignoring cancelled request ${latestRequest.requestId}");
        } else {
          _inflight = null;
          log.info("Request ${latestRequest.requestId} completed with ${result?.value}");
          _internalUpdate(latestRequest.requestId, result?.value);
        }
      } catch (e, stack) {
        log.severe("Error updating result: $e", e, stack);
      }
    }).autodispose(this);

    if (initialValue != null) {
      this.current = initialValue;
    }
  }

  T get current => _current;

  /// When setting a value in this way, we can assume that this update is the latest, and should cancel out any
  /// other in-flight requests
  set current(T current) {
    final requestId = _requestId++;
    switch (mode) {
      case ClearingHouseMode.AllowSynchronousValues:
        // Cancel any in-flight update, then update (after the cancellation completes)
        if (_inflight != null) {
          _inflight.cancel().then((_) => _internalUpdate(requestId, current));
        } else {
          _internalUpdate(requestId, current);
        }

        break;
      default:
        _queue(() => current);
        break;
    }
  }

  Future<T> update(Producer<T> current) {
    assert(current != null);
    _queue(current);
    return nextUpdate;
  }

  _queue(Producer<T> producer) {
    final requestId = _requestId++;
    log.fine("Queued request: $requestId");
    _requests.add(UpdateRequest(producer, requestId, log));
  }

  /// Updates the internal values and notifies listeners
  void _internalUpdate(int requestId, T current) {
    if (_accepted >= requestId) {
      log.info('Update $requestId completed, but was older than $_accepted => value = $current');
      return;
    }
    _accepted = requestId;
    if (isUnique != true || _current != current) {
      _current = current;
      _after.add(current);
    }
    _isResolved = true;
  }

  /// Waits until the next update completes
  Future<T> get nextUpdate {
    return after.firstWhere((_) => true, orElse: () => null);
  }

  @override
  Future<T> get future => current != null ? Future.value(current) : after.first;

  @override
  T resolve([T ifAbsent]) => current ?? ifAbsent;

  @override
  FutureOr<T> get() => _isResolved ? current : nextUpdate;

  @override
  ValueStream<R> map<R>(R mapper(T input)) {
    return HStream(mapper(current), after.map(mapper));
  }

  @override
  bool get isFirstResolved => _isResolved;

  dispose() async {
    await _requests.close();
    await _after.close();
    disposeAll();
  }
}

class UpdateResult<T> {
  final T value;
  final bool isCompleted;

  const UpdateResult.value(this.value) : isCompleted = true;

  const UpdateResult.cancelled()
      : value = null,
        isCompleted = false;
}

class UpdateRequest<T> with EquatableMixin implements Comparable<UpdateRequest> {
  final Producer<T> producer;
  final int requestId;
  final Logger log;
  CancelableOperation<UpdateResult<T>> operation;
  bool _isCancelled = false;

  UpdateRequest(this.producer, this.requestId, this.log);

  CancelableOperation<UpdateResult<T>> start() {
    if (_isCancelled) return null;
    assert(operation == null);
    return operation ??= CancelableOperation<UpdateResult<T>>.fromFuture(
        producer().futureValue().then((_) {
          return UpdateResult.value(_);
        }), onCancel: () {
      _isCancelled = true;
    });
  }

  cancel() async {
    log.info("Cancelling request $requestId");
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
