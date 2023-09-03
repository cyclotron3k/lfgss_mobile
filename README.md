# LFGSS

## TODO

- Thread view
- Composable forms: Conversation + comment, Huddle + comment
  - Create post
  - Create huddle
- Swipe to reply `Draggable(axis: ...),` & https://docs.flutter.dev/cookbook/animation/physics-simulation
- Edit comment
- Implement settings
- Page navigation (lozenge or indexed scroller?)
- Skeleton/Shimmer placeholders - https://docs.flutter.dev/cookbook/effects/shimmer-loading
- Animated containers for loading content?
- Better caching/cache invalidation
- Download dots
- Caching (json, images, thumbnails, metrics)
- Attachment gallery
- User selector
- Maps
- Social sharing
- Persistent connections & HTTP3 (See: https://pub.dev/packages/dio)
- DRY (future_x widgets, mixins, codegen?)
- Widget keys
- Instrumentation
- https://docs.flutter.dev/cookbook/effects/expandable-fab
- Use FlutterSecureStorage?
- Manage caching across multiple accounts better
- Consolidated notifications
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

## Bugs

- Horizontal scroll new comment attachments

## Maintenance

- Automate updating the TZ db: https://pub.dev/packages/timezone
