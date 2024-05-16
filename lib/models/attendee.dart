import 'profile.dart';

enum AttendeeStatus { invited, yes, maybe, no }

class Attendee {
  final Profile profile;
  final AttendeeStatus rsvp;
  final DateTime rsvpdOn;

  Attendee.fromJson({required Map<String, dynamic> json})
      : profile = Profile.fromJson(json: json["profile"]),
        rsvp = AttendeeStatus.values.byName(json["rsvp"]),
        rsvpdOn = DateTime.tryParse(json["rsvpdOn"])!;
}
