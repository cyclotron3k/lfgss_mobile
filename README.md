# LFGSS

## TODO

- Refactor event_attendees.dart
- Evict expired pages from cache
- Auto-refresh updates page - https://pub.dev/packages/visibility_detector
- Useless notification group
- Better caching/cache invalidation
- Remember last page
- Creating a new comment or post -> thread/post
- Edit comment
- Search
- Better selector UX
- Convert API client to ChangeNotifier?
- Manage caching across multiple accounts better
- Caching (json, images, thumbnails, metrics)
- Page navigation (lozenge or indexed scroller?)
- Thread view
- Attachment gallery
- Download dots
- Maps
- Persistent connections & HTTP3 (See: https://pub.dev/packages/dio)
- DRY (future_x widgets, mixins, codegen?)
- Social sharing
- Widget keys
- Instrumentation
- https://docs.flutter.dev/cookbook/effects/expandable-fab
- Skeleton/Shimmer placeholders - https://docs.flutter.dev/cookbook/effects/shimmer-loading
- Better swipe to reply - https://docs.flutter.dev/cookbook/animation/physics-simulation
- Better RefreshIndicator UX
- Use FlutterSecureStorage?
- Blurha.sh shader?
- Abstract participant/attendee widget

## TBD

- Authentication
  - Can re-use Auth0 Client ID but need callback URLs authourised
- Firebase & push notifications
- Separate conversation download and read pointer updates
- Mobile notification preferences into API
- Convert Polls from Item to Attachment
- https://blurha.sh/ for images
- TZ calcs on event timestamps

## Maintenance

- Automate updating the TZ db: https://pub.dev/packages/timezone

## Refactor

- Settings & default settings
- Attachments
- Notification handling
- comment/incontext -> event/huddle
