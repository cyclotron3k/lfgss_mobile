import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../profile_sheet.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.profile,
  });

  final Profile profile;

  Future<void> _showProfileModal(BuildContext context) =>
      showModalBottomSheet<void>(
        enableDrag: true,
        showDragHandle: true,
        context: context,
        builder: (BuildContext context) => ProfileSheet(
          profile: profile,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showProfileModal(context),
        child: ListTile(
          leading: (profile.avatar.isEmpty
              ? const Icon(
                  Icons.person_2_outlined,
                  color: Colors.grey,
                )
              : (profile.avatar.endsWith('.svg')
                  ? Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    )
                  : CachedNetworkImage(
                      imageUrl: profile.avatar,
                      width: 28,
                      height: 28,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error_outline,
                      ),
                    ))),
          title: Text(
            profile.profileName,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          subtitle: const Text("New user"),
        ),
      ),
    );
  }
}
