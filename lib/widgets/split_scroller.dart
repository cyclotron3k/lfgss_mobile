import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lfgss_mobile/models/item_with_children.dart';

class SplitScroller extends StatefulWidget {
  final ItemWithChildren item;
  final int offsetIndex;

  const SplitScroller({
    super.key,
    required this.item,
    this.offsetIndex = 0,
  });

  @override
  State<SplitScroller> createState() => _SplitScrollerState();
}

class _SplitScrollerState extends State<SplitScroller> {
  @override
  Widget build(BuildContext context) {
    Key forwardListKey = UniqueKey();

    Widget forwardList = SliverList.builder(
      key: forwardListKey,
      itemBuilder: (BuildContext context, int index) {
        return const Placeholder();
        // return widget.item.getChild(context, widget.offsetIndex - index);
      },
      itemCount: widget.offsetIndex,
    );

    Widget reverseList = SliverList.builder(
      itemBuilder: (BuildContext context, int index) => Container(
        color: index % 2 == 0 ? Colors.blue : Colors.orange,
        height: 100.0,
        child: Text('fordward $index'),
      ),
      itemCount: 40,
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Endless List'),
        ),
        body: Scrollable(
          viewportBuilder: (BuildContext context, ViewportOffset offset) {
            return Viewport(offset: offset, center: forwardListKey, slivers: [
              reverseList,
              forwardList,
            ]);
          },
        ),
      ),
    );
  }
}
