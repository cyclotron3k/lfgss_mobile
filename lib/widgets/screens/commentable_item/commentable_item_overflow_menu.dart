import 'package:flutter/material.dart';

class CommentableItemOverflowMenu extends StatelessWidget {
  final String itemTypeLabel;
  final bool watched;
  final Future<void> Function() onSearch;
  final Future<void> Function() onShare;
  final Future<void> Function() onToggleSubscription;
  final Future<void> Function() onJumpToPage;
  final Future<void> Function() onOpenInBrowser;

  const CommentableItemOverflowMenu({
    super.key,
    required this.itemTypeLabel,
    required this.watched,
    required this.onSearch,
    required this.onShare,
    required this.onToggleSubscription,
    required this.onJumpToPage,
    required this.onOpenInBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (
        BuildContext context,
        MenuController controller,
        Widget? child,
      ) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.more_vert),
          tooltip: 'Show menu',
        );
      },
      menuChildren: <MenuItemButton>[
        MenuItemButton(
          onPressed: () => onSearch(),
          leadingIcon: const Icon(Icons.search),
          child: Text('Find in $itemTypeLabel'),
        ),
        MenuItemButton(
          onPressed: () => onShare(),
          leadingIcon: Icon(Icons.adaptive.share),
          child: const Text('Share'),
        ),
        MenuItemButton(
          onPressed: () => onToggleSubscription(),
          leadingIcon: Icon(
            watched ? Icons.notifications_on : Icons.notification_add_outlined,
          ),
          child: Text(watched ? 'Unfollow $itemTypeLabel' : 'Follow $itemTypeLabel'),
        ),
        MenuItemButton(
          onPressed: () => onJumpToPage(),
          leadingIcon: const Icon(Icons.numbers),
          child: const Text('Jump to page'),
        ),
        MenuItemButton(
          onPressed: () => onOpenInBrowser(),
          leadingIcon: const Icon(Icons.open_in_browser),
          child: const Text('Open in browser'),
        ),
      ],
    );
  }
}
