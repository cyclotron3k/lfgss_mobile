import 'package:flutter_test/flutter_test.dart';
import 'package:lfgss_mobile/widgets/profile_last_active.dart';

void main() {
  group('profileLastActiveLabel', () {
    test('returns today for the local current day', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2026, 5, 14, 1), now: now),
        'today',
      );
    });

    test('returns yesterday for the previous local day', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2026, 5, 13, 23), now: now),
        'yesterday',
      );
    });

    test('returns this week after yesterday within the local week', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2026, 5, 12, 23), now: now),
        'this week',
      );
    });

    test('returns this month before the local week', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2026, 5, 3, 23), now: now),
        'this month',
      );
    });

    test('returns this year before the local month', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2026, 4, 30, 23), now: now),
        'this year',
      );
    });

    test('returns last year for the previous local year', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2025, 12, 31, 23), now: now),
        'last year',
      );
    });

    test('returns more than a year ago before the previous local year', () {
      final now = DateTime(2026, 5, 14, 12);

      expect(
        profileLastActiveLabel(DateTime(2024, 12, 31, 23), now: now),
        'more than a year ago',
      );
    });

    test('compares UTC timestamps after converting to local time', () {
      final now = DateTime(2026, 5, 14, 12);
      final utcToday = DateTime.utc(2026, 5, 14).subtract(
        now.timeZoneOffset,
      );

      expect(
        profileLastActiveLabel(utcToday, now: now),
        'today',
      );
    });
  });
}
