import 'package:flutter_test/flutter_test.dart';
import 'package:sunny_dart/time/date_components.dart';

void main() {
  group("Date Components Test", () {
    test("Standard iso date", () {
      final parsed = DateComponents.parse("2012-10-03");
      expect(parsed.year, 2012);
      expect(parsed.month, 10);
      expect(parsed.day, 3);
    });

    test("Month and year (4 digits)", () {
      final parsed = DateComponents.parse("12-2000");
      expect(parsed.year, 2000);
      expect(parsed.month, 12);
      expect(parsed.day, isNull);
    });

    test("Month and day", () {
      final parsed = DateComponents.parse("12-28");
      expect(parsed.year, null);
      expect(parsed.month, 12);
      expect(parsed.day, 28);
    });

    test("Month and year (short month digits)", () {
      final parsed = DateComponents.parse("Jan 12");
      expect(parsed.year, null);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("January 12", () {
      final parsed = DateComponents.parse("January 12");
      expect(parsed.year, null);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("1/12", () {
      final parsed = DateComponents.parse("1/12");
      expect(parsed.year, null);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("January 12, 1977", () {
      final parsed = DateComponents.parse("January 12, 1977");
      expect(parsed.year, 1977);
      expect(parsed.month, 1);
      expect(parsed.day, 12);
    });

    test("breakfast sausage", () {
      expect(() => DateComponents.parse("breakfast sausage"), throwsException);
    });

    test("31-5521-43", () {
      expect(() => DateComponents.parse("31-5521-43"), throwsException);
    });
  });
}
