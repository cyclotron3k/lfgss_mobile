import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const double _kMinFlingVelocity = 700.0;
const double _kMinFlingVelocityDelta = 400.0;
const double _kFlingVelocityScale = 1.0 / 300.0;
const double _kSwipeThreshold = 0.4;

/// Signature used by [Swipeable] to indicate that it has been dismissed in
/// the given `direction`.
///
/// Used by [Swipeable.onRelease].
typedef SwipeDirectionCallback = void Function(SwipeUpdateDetails details);

/// Signature used by [Swipeable] to give the application an opportunity to
/// confirm or veto a dismiss gesture.
///
/// Used by [Swipeable.confirmDismiss].
typedef ConfirmSwipeCallback = Future<bool?> Function(SwipeDirection direction);

/// Signature used by [Swipeable] to indicate that the dismissible has been dragged.
///
/// Used by [Swipeable.onUpdate].
typedef SwipeUpdateCallback = void Function(SwipeUpdateDetails details);

/// The direction in which a [Swipeable] can be dismissed.
enum SwipeDirection {
  /// The [Swipeable] can be dismissed by dragging either up or down.
  vertical,

  /// The [Swipeable] can be dismissed by dragging either left or right.
  horizontal,

  /// The [Swipeable] can be dismissed by dragging in the reverse of the
  /// reading direction (e.g., from right to left in left-to-right languages).
  endToStart,

  /// The [Swipeable] can be dismissed by dragging in the reading direction
  /// (e.g., from left to right in left-to-right languages).
  startToEnd,

  /// The [Swipeable] can be dismissed by dragging up only.
  up,

  /// The [Swipeable] can be dismissed by dragging down only.
  down,

  /// The [Swipeable] cannot be dismissed by dragging.
  none
}

/// A widget that can be dismissed by dragging in the indicated [direction].
///
/// Dragging or flinging this widget in the [SwipeDirection] causes the child
/// to slide out of view. Following the slide animation, if [resizeDuration] is
/// non-null, the Dismissible widget animates its height (or width, whichever is
/// perpendicular to the dismiss direction) to zero over the [resizeDuration].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=iEMgjrfuc58}
///
/// {@tool dartpad}
/// This sample shows how you can use the [Swipeable] widget to
/// remove list items using swipe gestures. Swipe any of the list
/// tiles to the left or right to dismiss them from the [ListView].
///
/// ** See code in examples/api/lib/widgets/dismissible/dismissible.0.dart **
/// {@end-tool}
///
/// Backgrounds can be used to implement the "leave-behind" idiom. If a background
/// is specified it is stacked behind the Dismissible's child and is exposed when
/// the child moves.
///
/// The widget calls the [onRelease] callback either after its size has
/// collapsed to zero (if [resizeDuration] is non-null) or immediately after
/// the slide animation (if [resizeDuration] is null). If the Dismissible is a
/// list item, it must have a key that distinguishes it from the other items and
/// its [onRelease] callback must remove the item from the list.
class Swipeable extends StatefulWidget {
  /// Creates a widget that can be dismissed.
  ///
  /// The [key] argument must not be null because [Swipeable]s are commonly
  /// used in lists and removed from the list when dismissed. Without keys, the
  /// default behavior is to sync widgets based on their index in the list,
  /// which means the item after the dismissed item would be synced with the
  /// state of the dismissed item. Using keys causes the widgets to sync
  /// according to their keys and avoids this pitfall.
  const Swipeable({
    required Key key,
    required this.child,
    this.background,
    this.secondaryBackground,
    this.onUpdate,
    this.onRelease,
    this.direction = SwipeDirection.horizontal,
    this.resizeDuration = const Duration(milliseconds: 300),
    this.swipeThresholds = const <SwipeDirection, double>{},
    this.movementDuration = const Duration(milliseconds: 200),
    this.crossAxisEndOffset = 0.0,
    this.dragStartBehavior = DragStartBehavior.start,
    this.behavior = HitTestBehavior.opaque,
  })  : assert(secondaryBackground == null || background != null),
        super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// A widget that is stacked behind the child. If secondaryBackground is also
  /// specified then this widget only appears when the child has been dragged
  /// down or to the right.
  final Widget? background;

  /// A widget that is stacked behind the child and is exposed when the child
  /// has been dragged up or to the left. It may only be specified when background
  /// has also been specified.
  final Widget? secondaryBackground;

  /// Called when the widget has been dismissed, after finishing resizing.
  final SwipeDirectionCallback? onRelease;

  /// The direction in which the widget can be dismissed.
  final SwipeDirection direction;

  /// The amount of time the widget will spend contracting before [onRelease] is called.
  ///
  /// If null, the widget will not contract and [onRelease] will be called
  /// immediately after the widget is dismissed.
  final Duration? resizeDuration;

  /// The offset threshold the item has to be dragged in order to be considered
  /// dismissed.
  ///
  /// Represented as a fraction, e.g. if it is 0.4 (the default), then the item
  /// has to be dragged at least 40% towards one direction to be considered
  /// dismissed. Clients can define different thresholds for each dismiss
  /// direction.
  ///
  /// Flinging is treated as being equivalent to dragging almost to 1.0, so
  /// flinging can dismiss an item past any threshold less than 1.0.
  ///
  /// Setting a threshold of 1.0 (or greater) prevents a drag in the given
  /// [SwipeDirection] even if it would be allowed by the [direction]
  /// property.
  ///
  /// See also:
  ///
  ///  * [direction], which controls the directions in which the items can
  ///    be dismissed.
  final Map<SwipeDirection, double> swipeThresholds;

  /// Defines the duration for card to dismiss or to come back to original position if not dismissed.
  final Duration movementDuration;

  /// Defines the end offset across the main axis after the card is dismissed.
  ///
  /// If non-zero value is given then widget moves in cross direction depending on whether
  /// it is positive or negative.
  final double crossAxisEndOffset;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], the drag gesture used to dismiss a
  /// dismissible will begin at the position where the drag gesture won the arena.
  /// If set to [DragStartBehavior.down] it will begin at the position where
  /// a down event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// How to behave during hit tests.
  ///
  /// This defaults to [HitTestBehavior.opaque].
  final HitTestBehavior behavior;

  /// Called when the dismissible widget has been dragged.
  ///
  /// If [onUpdate] is not null, then it will be invoked for every pointer event
  /// to dispatch the latest state of the drag. For example, this callback
  /// can be used to for example change the color of the background widget
  /// depending on whether the dismiss threshold is currently reached.
  final SwipeUpdateCallback? onUpdate;

  @override
  State<Swipeable> createState() => _SwipeableState();
}

/// Details for [SwipeUpdateCallback].
///
/// See also:
///
///   * [Swipeable.onUpdate], which receives this information.
class SwipeUpdateDetails {
  /// Create a new instance of [SwipeUpdateDetails].
  SwipeUpdateDetails({
    this.direction = SwipeDirection.horizontal,
    this.reached = false,
    this.previousReached = false,
    this.progress = 0.0,
  });

  /// The direction that the dismissible is being dragged.
  final SwipeDirection direction;

  /// Whether the dismiss threshold is currently reached.
  final bool reached;

  /// Whether the dismiss threshold was reached the last time this callback was invoked.
  ///
  /// This can be used in conjunction with [SwipeUpdateDetails.reached] to catch the moment
  /// that the [Swipeable] is dragged across the threshold.
  final bool previousReached;

  /// The offset ratio of the dismissible in its parent container.
  ///
  /// A value of 0.0 represents the normal position and 1.0 means the child is
  /// completely outside its parent.
  ///
  /// This can be used to synchronize other elements to what the dismissible is doing on screen,
  /// e.g. using this value to set the opacity thereby fading dismissible as it's dragged offscreen.
  final double progress;
}

class _SwipeableClipper extends CustomClipper<Rect> {
  _SwipeableClipper({
    required this.axis,
    required this.moveAnimation,
  }) : super(reclip: moveAnimation);

  final Axis axis;
  final Animation<Offset> moveAnimation;

  @override
  Rect getClip(Size size) {
    switch (axis) {
      case Axis.horizontal:
        final double offset = moveAnimation.value.dx * size.width;
        if (offset < 0) {
          return Rect.fromLTRB(
              size.width + offset, 0.0, size.width, size.height);
        }
        return Rect.fromLTRB(0.0, 0.0, offset, size.height);
      case Axis.vertical:
        final double offset = moveAnimation.value.dy * size.height;
        if (offset < 0) {
          return Rect.fromLTRB(
              0.0, size.height + offset, size.width, size.height);
        }
        return Rect.fromLTRB(0.0, 0.0, size.width, offset);
    }
  }

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_SwipeableClipper oldClipper) {
    return oldClipper.axis != axis ||
        oldClipper.moveAnimation.value != moveAnimation.value;
  }
}

enum _FlingGestureKind { none, forward, reverse }

class _SwipeableState extends State<Swipeable> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _moveController =
        AnimationController(duration: widget.movementDuration, vsync: this)
          ..addStatusListener(_handleSwipeStatusChanged)
          ..addListener(_handleSwipeUpdateValueChanged);
    _updateMoveAnimation();
  }

  AnimationController? _moveController;
  late Animation<Offset> _moveAnimation;

  AnimationController? _resizeController;
  // Animation<double>? _resizeAnimation;

  double _dragExtent = 0.0;
  bool _dragUnderway = false;
  bool _swipeThresholdReached = false;

  final GlobalKey _contentKey = GlobalKey();

  @override
  void dispose() {
    _moveController!.dispose();
    _resizeController?.dispose();
    super.dispose();
  }

  bool get _directionIsXAxis {
    return widget.direction == SwipeDirection.horizontal ||
        widget.direction == SwipeDirection.endToStart ||
        widget.direction == SwipeDirection.startToEnd;
  }

  SwipeDirection _extentToDirection(double extent) {
    if (extent == 0.0) {
      return SwipeDirection.none;
    }
    if (_directionIsXAxis) {
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          return extent < 0
              ? SwipeDirection.startToEnd
              : SwipeDirection.endToStart;
        case TextDirection.ltr:
          return extent > 0
              ? SwipeDirection.startToEnd
              : SwipeDirection.endToStart;
      }
    }
    return extent > 0 ? SwipeDirection.down : SwipeDirection.up;
  }

  SwipeDirection get _swipeDirection => _extentToDirection(_dragExtent);

  bool get _isActive {
    return _dragUnderway || _moveController!.isAnimating;
  }

  double get _overallDragAxisExtent {
    final Size size = context.size!;
    return _directionIsXAxis ? size.width : size.height;
  }

  void _handleDragStart(DragStartDetails details) {
    _dragUnderway = true;
    if (_moveController!.isAnimating) {
      _dragExtent =
          _moveController!.value * _overallDragAxisExtent * _dragExtent.sign;
      _moveController!.stop();
    } else {
      _dragExtent = 0.0;
      _moveController!.value = 0.0;
    }
    setState(() {
      _updateMoveAnimation();
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isActive || _moveController!.isAnimating) {
      return;
    }

    final double delta = details.primaryDelta!;
    final double oldDragExtent = _dragExtent;
    switch (widget.direction) {
      case SwipeDirection.horizontal:
      case SwipeDirection.vertical:
        _dragExtent += delta;

      case SwipeDirection.up:
        if (_dragExtent + delta < 0) {
          _dragExtent += delta;
        }

      case SwipeDirection.down:
        if (_dragExtent + delta > 0) {
          _dragExtent += delta;
        }

      case SwipeDirection.endToStart:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta > 0) {
              _dragExtent += delta;
            }
          case TextDirection.ltr:
            if (_dragExtent + delta < 0) {
              _dragExtent += delta;
            }
        }

      case SwipeDirection.startToEnd:
        switch (Directionality.of(context)) {
          case TextDirection.rtl:
            if (_dragExtent + delta < 0) {
              _dragExtent += delta;
            }
          case TextDirection.ltr:
            if (_dragExtent + delta > 0) {
              _dragExtent += delta;
            }
        }

      case SwipeDirection.none:
        _dragExtent = 0;
    }
    if (oldDragExtent.sign != _dragExtent.sign) {
      setState(() {
        _updateMoveAnimation();
      });
    }
    if (!_moveController!.isAnimating) {
      _moveController!.value = _dragExtent.abs() / _overallDragAxisExtent;
    }
  }

  void _handleSwipeUpdateValueChanged() {
    if (widget.onUpdate != null) {
      final bool oldSwipeThresholdReached = _swipeThresholdReached;
      _swipeThresholdReached = _moveController!.value >
          (widget.swipeThresholds[_swipeDirection] ?? _kSwipeThreshold);
      final SwipeUpdateDetails details = SwipeUpdateDetails(
        direction: _swipeDirection,
        reached: _swipeThresholdReached,
        previousReached: oldSwipeThresholdReached,
        progress: _moveController!.value,
      );
      widget.onUpdate!(details);
    }
  }

  void _updateMoveAnimation() {
    final double end = _dragExtent.sign;
    _moveAnimation = _moveController!.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: _directionIsXAxis
            ? Offset(end, widget.crossAxisEndOffset)
            : Offset(widget.crossAxisEndOffset, end),
      ),
    );
  }

  _FlingGestureKind _describeFlingGesture(Velocity velocity) {
    if (_dragExtent == 0.0) {
      // If it was a fling, then it was a fling that was let loose at the exact
      // middle of the range (i.e. when there's no displacement). In that case,
      // we assume that the user meant to fling it back to the center, as
      // opposed to having wanted to drag it out one way, then fling it past the
      // center and into and out the other side.
      return _FlingGestureKind.none;
    }
    final double vx = velocity.pixelsPerSecond.dx;
    final double vy = velocity.pixelsPerSecond.dy;
    SwipeDirection flingDirection;
    // Verify that the fling is in the generally right direction and fast enough.
    if (_directionIsXAxis) {
      if (vx.abs() - vy.abs() < _kMinFlingVelocityDelta ||
          vx.abs() < _kMinFlingVelocity) {
        return _FlingGestureKind.none;
      }
      assert(vx != 0.0);
      flingDirection = _extentToDirection(vx);
    } else {
      if (vy.abs() - vx.abs() < _kMinFlingVelocityDelta ||
          vy.abs() < _kMinFlingVelocity) {
        return _FlingGestureKind.none;
      }
      assert(vy != 0.0);
      flingDirection = _extentToDirection(vy);
    }
    if (flingDirection == _swipeDirection) {
      return _FlingGestureKind.forward;
    }
    return _FlingGestureKind.reverse;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isActive || _moveController!.isAnimating) {
      return;
    }
    _dragUnderway = false;
    if (widget.onRelease != null) {
      final SwipeUpdateDetails details = SwipeUpdateDetails(
        direction: _swipeDirection,
        reached: _swipeThresholdReached,
        progress: _moveController!.value,
      );
      widget.onRelease!(details);
    }
    if (_moveController!.isCompleted) {
      _handleMoveCompleted();
      return;
    }
    final double flingVelocity = _directionIsXAxis
        ? details.velocity.pixelsPerSecond.dx
        : details.velocity.pixelsPerSecond.dy;
    switch (_describeFlingGesture(details.velocity)) {
      case _FlingGestureKind.forward:
        assert(_dragExtent != 0.0);
        assert(!_moveController!.isDismissed);
        if ((widget.swipeThresholds[_swipeDirection] ?? _kSwipeThreshold) >=
            1.0) {
          _moveController!.reverse();
          break;
        }
        _dragExtent = flingVelocity.sign;
        _moveController!
            .fling(velocity: flingVelocity.abs() * _kFlingVelocityScale);
      case _FlingGestureKind.reverse:
        assert(_dragExtent != 0.0);
        assert(!_moveController!.isDismissed);
        _dragExtent = flingVelocity.sign;
        _moveController!
            .fling(velocity: -flingVelocity.abs() * _kFlingVelocityScale);
      case _FlingGestureKind.none:
        if (!_moveController!.isDismissed) {
          _moveController!.reverse();
        }
    }
  }

  Future<void> _handleSwipeStatusChanged(AnimationStatus status) async {
    if (status == AnimationStatus.completed && !_dragUnderway) {
      await _handleMoveCompleted();
    }
  }

  Future<void> _handleMoveCompleted() async {
    _moveController!.reverse();
  }

  @override
  Widget build(BuildContext context) {
    assert(!_directionIsXAxis || debugCheckHasDirectionality(context));

    Widget? background = widget.background;
    if (widget.secondaryBackground != null) {
      final SwipeDirection direction = _swipeDirection;
      if (direction == SwipeDirection.endToStart ||
          direction == SwipeDirection.up) {
        background = widget.secondaryBackground;
      }
    }

    // if (_resizeAnimation != null) {
    //   // we've been dragged aside, and are now resizing.
    //   assert(() {
    //     if (_resizeAnimation!.status != AnimationStatus.forward) {
    //       assert(_resizeAnimation!.status == AnimationStatus.completed);
    //       throw FlutterError.fromParts(<DiagnosticsNode>[
    //         ErrorSummary(
    //             'A dismissed Dismissible widget is still part of the tree.'),
    //         ErrorHint(
    //           'Make sure to implement the onDismissed handler and to immediately remove the Dismissible '
    //           'widget from the application once that handler has fired.',
    //         ),
    //       ]);
    //     }
    //     return true;
    //   }());

    //   return SizeTransition(
    //     sizeFactor: _resizeAnimation!,
    //     axis: _directionIsXAxis ? Axis.vertical : Axis.horizontal,
    //     child: SizedBox(
    //       width: _sizePriorToCollapse!.width,
    //       height: _sizePriorToCollapse!.height,
    //       child: background,
    //     ),
    //   );
    // }

    Widget content = SlideTransition(
      position: _moveAnimation,
      child: KeyedSubtree(key: _contentKey, child: widget.child),
    );

    if (background != null) {
      content = Stack(children: <Widget>[
        if (!_moveAnimation.isDismissed)
          Positioned.fill(
            child: ClipRect(
              clipper: _SwipeableClipper(
                axis: _directionIsXAxis ? Axis.horizontal : Axis.vertical,
                moveAnimation: _moveAnimation,
              ),
              child: background,
            ),
          ),
        content,
      ]);
    }

    // If the DismissDirection is none, we do not add drag gestures because the content
    // cannot be dragged.
    if (widget.direction == SwipeDirection.none) {
      return content;
    }

    // We are not resizing but we may be being dragging in widget.direction.
    return GestureDetector(
      onHorizontalDragStart: _directionIsXAxis ? _handleDragStart : null,
      onHorizontalDragUpdate: _directionIsXAxis ? _handleDragUpdate : null,
      onHorizontalDragEnd: _directionIsXAxis ? _handleDragEnd : null,
      onVerticalDragStart: _directionIsXAxis ? null : _handleDragStart,
      onVerticalDragUpdate: _directionIsXAxis ? null : _handleDragUpdate,
      onVerticalDragEnd: _directionIsXAxis ? null : _handleDragEnd,
      behavior: widget.behavior,
      dragStartBehavior: widget.dragStartBehavior,
      child: content,
    );
  }
}
