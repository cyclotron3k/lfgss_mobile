import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:intl/intl.dart';

import '../../models/huddle.dart';
import '../../services/avatar_cache_manager.dart';
import '../screens/future_screen.dart';
import '../time_ago.dart';

class HuddleTile extends StatelessWidget {
  final Huddle huddle;
  final bool? overrideUnreadFlag;

  const HuddleTile({
    super.key,
    required this.huddle,
    this.overrideUnreadFlag,
  });

  @override
  Widget build(BuildContext context) {
    final unescape = HtmlUnescape();
    return Card(
      key: ValueKey(huddle.id),
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureScreen(
                item: Huddle.getById(huddle.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (huddle.flags.sticky
              ? Icon(
                  Icons.push_pin_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                )
              : const Icon(
                  Icons.mail_outline,
                  size: 28,
                )),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overrideUnreadFlag ?? huddle.flags.unread)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 6.0, 6.0, 6.0),
                  child: Icon(
                    Icons.circle,
                    size: 10.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              Expanded(
                child: Text(
                  unescape.convert(huddle.title),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: [
                    for (final profile in huddle.participants)
                      Tooltip(
                        message: profile.profileName,
                        child: CachedNetworkImage(
                          width: 22.0,
                          height: 22.0,
                          imageUrl: profile.avatar,
                          cacheManager: AvatarCacheManager.instance,
                          imageBuilder: (context, imageProvider) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image(image: imageProvider),
                            );
                          },
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person_outline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TimeAgo(huddle.lastActivity ?? huddle.created),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.chat,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 15.0,
                ),
              ),
              Text(
                NumberFormat.compact().format(
                  huddle.totalChildren,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
