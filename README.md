# LFGSS

## TODO

- Reply to comment
- Auto-refresh updates page
- Creating a new comment or post -> thread/post
- Fix RefreshIndicator
- Notifications limited to 5
- Refreshing on page break disabled refresh button

- Better caching/cache invalidation
- Edit comment
- Search
- Better selector UX
- Convert API client to ChangeNotifier
- Manage caching across multiple accounts better
- Caching (json, images, thumbnails, metrics)
- Page navigation (lozenge or indexed scroller?)
- Swipe to reply `Draggable(axis: ...),` & https://docs.flutter.dev/cookbook/animation/physics-simulation
- Thread view
- Attachment gallery
- Download dots
- Maps
- Persistent connections & HTTP3 (See: https://pub.dev/packages/dio)
- DRY (future_x widgets, mixins, codegen?)
- Consolidated notifications
- Social sharing
- Widget keys
- Instrumentation
- https://docs.flutter.dev/cookbook/effects/expandable-fab
- Skeleton/Shimmer placeholders - https://docs.flutter.dev/cookbook/effects/shimmer-loading
- Use FlutterSecureStorage?
- Blurha.sh shader?

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
