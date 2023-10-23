# LFGSS

## TODO

- Edit comment
- Floating app bars on bi-directional infinite lists - https://www.youtube.com/watch?v=Mz3kHQxBjGg
- Remove obsolete notifications
- Auto-refresh updates page
- "More attachments" indicator
- Refactor event_attendees.dart
- Useless notification group
- Better caching/cache invalidation
- Better selector UX
- Convert API client to ChangeNotifier?
- Cache image sizes
- Caching (json, images, thumbnails, metrics)
- Page navigation (lozenge or indexed scroller?)
- Thread view
- Attachment gallery
- Download dots
- Show upload progress
- Event maps
- Persistent connections & HTTP3 (See: https://pub.dev/packages/dio)
- DRY (future_x widgets, mixins, codegen?)
- Widget keys
- Instrumentation
- Skeleton/Shimmer placeholders - https://docs.flutter.dev/cookbook/effects/shimmer-loading
- Better swipe to reply - https://docs.flutter.dev/cookbook/animation/physics-simulation
- Abstract participant/attendee widget
- Comment/incontext -> event/huddle
- https://docs.flutter.dev/cookbook/effects/expandable-fab
- Use FlutterSecureStorage?
- Blurha.sh shader?
- Better notifications (inc. replies) - https://pub.dev/packages/awesome_notifications
- Pre-populate Profile Popup with thread-participants

## TBD

- Authentication
  - Can re-use Auth0 Client ID but need callback URLs authourised
- Firebase & push notifications
- Separate conversation download and read pointer updates
- Mobile notification preferences into API
- Convert Polls (& Lists, and Events?) from Item to Attachment?
- https://blurha.sh/ for images
- TZ calcs on event timestamps

## Maintenance

- Automate updating the TZ db: https://pub.dev/packages/timezone

## Refactor

- Settings & default settings
- Attachments
- Notification handling
- popup profile selector code
  - roll into custom controller?
  - abstract word boundary code
