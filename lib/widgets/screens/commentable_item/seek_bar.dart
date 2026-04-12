import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum SeekBarSensitivity { always, high, low, never }

class SeekBar extends StatefulWidget {
  final ValueListenable<double> scrollOffsetListenable;
  final ValueListenable<bool> isUserScrollingListenable;
  final ValueListenable<double> fractionListenable;
  final int totalChildren;
  final double topPadding;
  final SeekBarSensitivity sensitivity;
  final void Function(int pageNo) onSeek;

  const SeekBar({
    super.key,
    required this.scrollOffsetListenable,
    required this.isUserScrollingListenable,
    required this.fractionListenable,
    required this.totalChildren,
    required this.topPadding,
    this.sensitivity = SeekBarSensitivity.low,
    required this.onSeek,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final CurvedAnimation _slideAnim;
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;
  late final AnimationController _rippleCtrl;
  late final Animation<double> _rippleAnim;

  Timer? _hideTimer;
  bool _isDragging = false;
  double? _rawDragFraction; // continuous, tracks actual finger position
  double? _dragFraction; // snapped to nearest page (or raw in smooth mode)

  double _prevOffset = 0.0;
  int _prevTimeMs = 0;

  // px/s thresholds for velocity-triggered display.
  static const double _velocityThresholdHigh = 1200.0;
  static const double _velocityThresholdLow = 5000.0;
  static const Duration _hideDelay = Duration(seconds: 2);
  static const double _thumbRadius = 10.0;
  static const double _hitboxPadding = 30.0;
  static const double _trackWidth = 1.0;
  static const double _rightMargin = 16.0;
  static const double _slideDistance = 60.0;
  static const int _snapThreshold = 20;

  int get _maxPage => ((widget.totalChildren - 1) ~/ 25) + 1;
  bool get _useSnap => _maxPage <= _snapThreshold;

  double _fractionForPage(int page) {
    if (_maxPage <= 1) return 0.0;
    return (page - 1) / (_maxPage - 1);
  }

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnim = const AlwaysStoppedAnimation(0.0);
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rippleAnim = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);
    _slideCtrl.addStatusListener(_onSlideStatus);
    widget.scrollOffsetListenable.addListener(_onScroll);
    _prevTimeMs = DateTime.now().millisecondsSinceEpoch;
    _prevOffset = widget.scrollOffsetListenable.value;

    if (widget.sensitivity == SeekBarSensitivity.always) {
      _slideCtrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollOffsetListenable != widget.scrollOffsetListenable) {
      oldWidget.scrollOffsetListenable.removeListener(_onScroll);
      widget.scrollOffsetListenable.addListener(_onScroll);
      _prevOffset = widget.scrollOffsetListenable.value;
      _prevTimeMs = DateTime.now().millisecondsSinceEpoch;
    }
    if (oldWidget.sensitivity != widget.sensitivity) {
      _hideTimer?.cancel();
      if (widget.sensitivity == SeekBarSensitivity.always) {
        _slideCtrl.forward();
      } else if (widget.sensitivity == SeekBarSensitivity.never) {
        _slideCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.scrollOffsetListenable.removeListener(_onScroll);
    _hideTimer?.cancel();
    _rippleCtrl.dispose();
    _snapCtrl.dispose();
    _slideAnim.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() => _dragFraction = null);
    }
  }

  void _onScroll() {
    if (widget.sensitivity == SeekBarSensitivity.never) return;
    if (widget.sensitivity == SeekBarSensitivity.always) return;

    final offset = widget.scrollOffsetListenable.value;

    if (!widget.isUserScrollingListenable.value) {
      _prevOffset = offset;
      _prevTimeMs = DateTime.now().millisecondsSinceEpoch;
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = now - _prevTimeMs;
    final offsetDelta = (offset - _prevOffset).abs();

    if (dt > 0 && dt < 200) {
      final velocity = offsetDelta / dt * 1000;
      final threshold = widget.sensitivity == SeekBarSensitivity.high
          ? _velocityThresholdHigh
          : _velocityThresholdLow;
      if (velocity > threshold) _showBar();
    }

    _prevOffset = offset;
    _prevTimeMs = now;
  }

  void _showBar() {
    if (widget.sensitivity == SeekBarSensitivity.never) return;
    _slideCtrl.forward();
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!_isDragging && widget.sensitivity != SeekBarSensitivity.always) {
      _hideTimer = Timer(_hideDelay, () {
        if (mounted) _slideCtrl.reverse();
      });
    }
  }

  int _pageForFraction(double f) =>
      (f * (_maxPage - 1)).round().clamp(0, _maxPage - 1) + 1;

  // The visual position of the thumb, incorporating spring animation.
  double get _thumbFraction {
    if (_dragFraction != null) {
      return _snapCtrl.isAnimating ? _snapAnim.value : _dragFraction!;
    }
    return widget.fractionListenable.value;
  }

  void _triggerSnap(double from, double to) {
    _snapAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOutBack),
    );
    _snapCtrl.forward(from: 0.0);
  }

  void _onDragStart(double currentFraction) {
    _hideTimer?.cancel();
    _rippleCtrl.forward(from: 0.0);
    final snapped = _useSnap
        ? _fractionForPage(_pageForFraction(currentFraction))
        : currentFraction;
    setState(() {
      _isDragging = true;
      _rawDragFraction = currentFraction;
      _dragFraction = snapped;
    });
  }

  void _onDragUpdate(double deltaY, double trackHeight) {
    final newRaw =
        ((_rawDragFraction ?? 0.0) + deltaY / trackHeight).clamp(0.0, 1.0);

    if (_useSnap) {
      final newFraction = _fractionForPage(_pageForFraction(newRaw));
      if ((newFraction - (_dragFraction ?? newFraction)).abs() > 0.0001) {
        final from = _snapCtrl.isAnimating
            ? _snapAnim.value
            : (_dragFraction ?? newFraction);
        _triggerSnap(from, newFraction);
      }
      setState(() {
        _rawDragFraction = newRaw;
        _dragFraction = newFraction;
      });
    } else {
      setState(() {
        _rawDragFraction = newRaw;
        _dragFraction = newRaw;
      });
    }
  }

  void _onDragEnd() {
    final targetPage =
        _pageForFraction(_dragFraction ?? widget.fractionListenable.value);
    _snapCtrl.stop();
    _rippleCtrl.reverse();
    // Keep _dragFraction alive so the thumb doesn't snap back to the scroll
    // position before navigation completes. It is cleared by _onSlideStatus
    // once the bar has fully hidden.
    setState(() {
      _isDragging = false;
      _rawDragFraction = null;
    });
    widget.onSeek(targetPage);
    _scheduleHide();
  }

  void _onDragCancel() {
    _snapCtrl.stop();
    _rippleCtrl.reverse();
    setState(() {
      _isDragging = false;
      _rawDragFraction = null;
      _dragFraction = null;
    });
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) {
        return IgnorePointer(
          ignoring: _slideCtrl.isDismissed && !_isDragging,
          child: Transform.translate(
            offset: Offset((1.0 - _slideAnim.value) * _slideDistance, 0),
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availHeight = constraints.maxHeight - widget.topPadding;
          final trackHeight = availHeight * 0.8;
          final trackTopAbs =
              widget.topPadding + (availHeight - trackHeight) / 2;

          return AnimatedBuilder(
            animation: Listenable.merge([
              widget.fractionListenable,
              widget.scrollOffsetListenable,
              _snapCtrl,
              _rippleCtrl,
            ]),
            builder: (context, _) {
              final fraction = _thumbFraction.clamp(0.0, 1.0);
              final thumbCenterY = trackTopAbs + fraction * trackHeight;
              final page = _pageForFraction(
                _dragFraction ?? widget.fractionListenable.value,
              );

              return Stack(
                children: [
                  // Track line
                  Positioned(
                    right: _rightMargin + _thumbRadius - _trackWidth / 2,
                    top: trackTopAbs,
                    child: IgnorePointer(
                      child: Container(
                        width: _trackWidth,
                        height: trackHeight,
                        color: colors.outline.withAlpha(120),
                      ),
                    ),
                  ),

                  // Tick marks for snap mode
                  if (_useSnap)
                    for (var i = 0; i < _maxPage; i++)
                      Positioned(
                        right: _rightMargin + _thumbRadius - 4,
                        top: trackTopAbs +
                            _fractionForPage(i + 1) * trackHeight -
                            1,
                        child: IgnorePointer(
                          child: Container(
                            width: 8,
                            height: _trackWidth,
                            color: colors.outline.withAlpha(140),
                          ),
                        ),
                      ),

                  // Ripple behind thumb — always in tree, opacity-controlled
                  // to avoid disrupting gesture reconciliation.
                  Positioned(
                    right: _rightMargin +
                        _thumbRadius -
                        (_thumbRadius * (1 + 1.8 * _rippleAnim.value)),
                    top: thumbCenterY -
                        _thumbRadius * (1 + 1.8 * _rippleAnim.value),
                    child: IgnorePointer(
                      child: Container(
                        width: _thumbRadius * 2 * (1 + 1.8 * _rippleAnim.value),
                        height:
                            _thumbRadius * 2 * (1 + 1.8 * _rippleAnim.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.primary.withAlpha(120),
                        ),
                      ),
                    ),
                  ),

                  // Label — always in tree, opacity-controlled to keep the
                  // Positioned slot stable so gesture reconciliation for the
                  // thumb is never disrupted by an insertion/removal here.
                  Positioned(
                    right: _rightMargin + _thumbRadius * 2 + 12,
                    top: thumbCenterY - 14,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: _isDragging ? 1.0 : 0.0,
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(6),
                          color: colors.surfaceContainerHigh.withAlpha(80),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            child: Text(
                              'Page $page / $_maxPage',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Thumb with enlarged hitbox
                  Positioned(
                    right: _rightMargin - _hitboxPadding,
                    top: thumbCenterY - _thumbRadius - _hitboxPadding,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) => _onDragStart(fraction),
                      onVerticalDragUpdate: (d) =>
                          _onDragUpdate(d.delta.dy, trackHeight),
                      onVerticalDragEnd: (_) => _onDragEnd(),
                      onVerticalDragCancel: _onDragCancel,
                      child: Padding(
                        padding: const EdgeInsets.all(_hitboxPadding),
                        child: Container(
                          width: _thumbRadius * 2,
                          height: _thumbRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
