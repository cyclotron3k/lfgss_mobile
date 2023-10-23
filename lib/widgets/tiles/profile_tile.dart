import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/full_profile.dart';
import '../screens/profile_screen.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.profile,
  });

  final Profile profile;

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
                profile: FullProfile.getProfile(profile.id),
              ),
            ),
          );
        },
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
