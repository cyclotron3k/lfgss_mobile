import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class FloatingCommentHeaderController {
  final ScrollController scrollController;
  final ValueNotifier<double> translateY;
  double headerHeight;
  double _lastScrollOffset = 0.0;

  FloatingCommentHeaderController({
    required this.scrollController,
    this.headerHeight = kToolbarHeight,
  }) : translateY = ValueNotifier<double>(0.0) {
    scrollController.addListener(_handleScroll);
  }

  void updateForContext(BuildContext context) {
    final nextHeaderHeight = MediaQuery.paddingOf(context).top + kToolbarHeight;
    if ((nextHeaderHeight - headerHeight).abs() > 0.1) {
      final wasHidden = translateY.value <= -headerHeight + 0.5;
      headerHeight = nextHeaderHeight;
      final nextTranslateY = wasHidden ? -headerHeight : translateY.value;
      translateY.value = nextTranslateY.clamp(-headerHeight, 0.0);
    }
  }

  void _handleScroll() {
    if (!scrollController.hasClients) return;

    final offset = scrollController.offset;
    final delta = offset - _lastScrollOffset;
    _lastScrollOffset = offset;

    if (delta.abs() < 1.0) return;

    final nextTranslateY = (translateY.value - delta).clamp(-headerHeight, 0.0);
    if ((nextTranslateY - translateY.value).abs() > 0.1) {
      translateY.value = nextTranslateY;
    }
  }

  void dispose() {
    scrollController.removeListener(_handleScroll);
    translateY.dispose();
  }
}

class FloatingCommentHeader extends StatelessWidget {
  final String title;
  final Widget action;
  final ValueListenable<double> translateY;
  final double headerHeight;

  const FloatingCommentHeader({
    super.key,
    required this.title,
    required this.action,
    required this.translateY,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: translateY,
        child: RepaintBoundary(
          child: SizedBox(
            height: headerHeight,
            child: AppBar(
              primary: true,
              leading: null,
              automaticallyImplyLeading: false,
              title: Text(title),
              actions: <Widget>[action],
            ),
          ),
        ),
        builder: (context, translateY, child) {
          final floatingHeaderVisible = translateY > -headerHeight + 0.5;
          return IgnorePointer(
            ignoring: !floatingHeaderVisible,
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
