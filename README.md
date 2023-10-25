# LFGSS

## TODO

- Edit comment
- Native login
- Tidy Following page
- Auto-refresh Following page
- Page navigation (lozenge or indexed scroller?)
- Floating app bars on bi-directional infinite lists - https://www.youtube.com/watch?v=Mz3kHQxBjGg
- Remove obsolete notifications
- "More attachments" indicator
- Cache image sizes
- Caching (json, images, thumbnails, metrics)
- Attachment gallery
- Refactor event_attendees.dart
- Persistent connections & HTTP3 (See: https://pub.dev/packages/dio)
- Better caching/cache invalidation
- Better selector UX
- Useless notification group
- Better notifications (inc. replies) - https://pub.dev/packages/awesome_notifications
- Convert API client to ChangeNotifier?
- Thread view
- Event maps
- Better swipe to reply - https://docs.flutter.dev/cookbook/animation/physics-simulation
- Download dots
- Show upload progress
- DRY (future_x widgets, mixins, codegen?)
- Abstract participant/attendee widget
- Widget keys
- Instrumentation
- Skeleton/Shimmer placeholders - https://docs.flutter.dev/cookbook/effects/shimmer-loading
- Comment/incontext -> event/huddle
- https://docs.flutter.dev/cookbook/effects/expandable-fab
- Use FlutterSecureStorage?
- Blurha.sh shader?
- Pre-populate Profile Popup with thread-participants

## TBD

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
