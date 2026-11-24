import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lfgss_mobile/widgets/profile_last_active.dart';

void main() {
  group('profileLastActiveLabel', () {
    test('always returns the local month and year', () {
      expect(
        profileLastActiveLabel(DateTime(2026, 5, 14, 1)),
        'May 2026',
      );
      expect(
        profileLastActiveLabel(DateTime(2025, 12, 31, 23)),
        'December 2025',
      );
    });

    test('converts UTC timestamps to local time before formatting', () {
      final utcDateTime = DateTime.utc(2026, 5, 1).subtract(
        DateTime.now().timeZoneOffset,
      );

      expect(
        profileLastActiveLabel(utcDateTime),
        DateFormat('MMMM y').format(utcDateTime.toLocal()),
      );
    });
  });
}
