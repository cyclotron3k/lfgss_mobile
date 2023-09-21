# LFGSS

## TODO

- Implement settings
  - Embed Youtube
  - Embed Twitter
- Search
- Better selector UX
- Auto-refresh after inactivity
- Convert API client to ChangeNotifier
- Manage caching across multiple accounts better
- Better caching/cache invalidation
- Caching (json, images, thumbnails, metrics)
- Page navigation (lozenge or indexed scroller?)
- Edit comment
- Skeleton/Shimmer placeholders - https://docs.flutter.dev/cookbook/effects/shimmer-loading
- Animated containers for loading content?
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
