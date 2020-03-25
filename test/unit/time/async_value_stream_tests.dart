import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';
import 'package:sunny_dart/sunny_dart.dart';

void main() {
  group("Async Value Stream", () {
    configureLogging(LogConfig.root(Level.FINER));
    test("Test initial value", () async {
      final number = AsyncValueStream(
          debugName: "tester", initialValue: 23, isUnique: true);
      expect(await number.nextUpdate.timeout(1.second), 23);
      final updates = await number.captureUpdates(() {});

      expect(updates.length, 1);
      expect(updates.first, 23);
      expect(await number.get(), 23);
    });

    test("Test no initial value", () async {
      final number = AsyncValueStream(debugName: "tester", isUnique: false);
      final updates = await number.captureUpdates(() {});

      expect(updates.length, 2);
      expect(updates.first, isNull);
    });

    test("Test update wait", () async {
      final number = AsyncValueStream(
          debugName: "tester", initialValue: 23, isUnique: true);

      final updates = await number.captureUpdates(() async {
        await number.update(() async {
          await 1.second.pause();
          return 42;
        });
      });

      expect(updates.length, 2);
      expect(updates.first, 23);
      expect(updates.last, 42);
    });

    test("Test update overlapping", () async {
      final number = AsyncValueStream(
          debugName: "update overlapping", initialValue: 23, isUnique: true);

      final updates = await number.captureUpdates(() async {
        number.update(() async {
          await 1.second.pause();
          return 42;
        }).ignore();
        await 300.ms.pause();
        number.update(() async {
          await 1.second.pause();
          return 43;
        }).ignore();

        await 300.ms.pause();
        number.update(() async {
          await 1.second.pause();
          return 44;
        }).ignore();

        await 300.ms.pause();
        await number.update(() async {
          await 1.second.pause();
          return 45;
        });
      });

      // 2 and 3 should get cancelled because a newer value comes in
      expect(updates.length, 2);
      expect(updates.first, 23);
      expect(updates.last, 45);
    });

    test("Test stale request", () async {
      final number = AsyncValueStream(
          debugName: "stale", initialValue: 23, isUnique: true);

      final updates = await number.captureUpdates(() async {
        number.update(() async {
          await 2.second.pause();
          return 42;
        }).ignore();

        number.update(() async {
          await 1.second.pause();
          return 43;
        }).ignore();
      });

      // 2 and 3 should get cancelled because a newer value comes in
      expect(updates.length, 2);
      expect(updates.first, 23);
      expect(updates.last, 43);
    });

    test("Test sync update", () async {
      final number = AsyncValueStream(
          debugName: "sync update", initialValue: 23, isUnique: false);
      expect(await number.nextUpdate, 23);
      final updates = await number.captureUpdates(() async {
        number.update(() async {
          await 2.second.pause();
          return 42;
        }).ignore();

        final afterSync = number.syncUpdate(43);
        await number.nextUpdate;

        number.syncUpdate(44);
        number.syncUpdate(45);
        number.syncUpdate(46);
        await number.syncUpdate(47);
        await number.update(() async {
          await 2.second.pause();
          return 50;
        });
      });

      // 2 and 3 should get cancelled because a newer value comes in
      expect(updates.length, 6);
      expect(updates.first, 23);
      expect(updates.last, 50);
    });

    test("Test sync update - locks", () async {
      final number = AsyncValueStream(
          debugName: "sync update - locks",
          initialValue: 23,
          isUnique: true,
          mode: ClearingHouseMode.LockUpdateCompletion);
      final firstValue = await number.nextUpdate;
      expect(firstValue, 23);
      final updates = await number.captureUpdates(() async {
        number.update(() async {
          await 2.second.pause();
          return 42;
        }).ignore();

        final afterSync = await number.syncUpdate(43);
      });

      // 2 and 3 should get cancelled because a newer value comes in
      expect(updates.length, 2);
      expect(updates.first, 23);
      expect(updates.last, 43);
    });
  });
}

extension AsyncValueStreamTestExt<T> on AsyncValueStream<T> {
  Future<List<T>> captureUpdates([FutureOr block()]) async {
    final updates = <T>[];
    this.flatten().listen(updates.add, onError: (err, stack) {
      print(stack);
      fail("$err");
    });

    await Future.microtask(() => block?.call());
    await this.nextUpdate;
    await 100.ms.pause();
    await this.dispose();
    return updates;
  }
}
