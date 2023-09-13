import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/partial_profile.dart';
import '../../models/profile.dart';
import '../screens/profile_screen.dart';

class PartialProfileTile extends StatelessWidget {
  const PartialProfileTile({
    super.key,
    required this.partialProfile,
  });

  final PartialProfile partialProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => ProfileScreen(
                profile: Profile.getProfile(partialProfile.id),
              ),
            ),
          );
        },
        child: ListTile(
          leading: (partialProfile.avatar.isEmpty
              ? const Icon(
                  Icons.person_2_outlined,
                  color: Colors.grey,
                )
              : (partialProfile.avatar.endsWith('.svg')
                  ? Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    )
                  : CachedNetworkImage(
                      imageUrl: partialProfile.avatar,
                      width: 28,
                      height: 28,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                      ),
                    ))),
          title: Text(
            partialProfile.profileName,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          subtitle: const Text("New user"),
        ),
      ),
    );
  }
}
