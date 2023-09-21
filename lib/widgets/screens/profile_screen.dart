import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/profile.dart';

class ProfileScreen extends StatefulWidget {
  final Future<Profile> profile;
  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Profile>(
          future: widget.profile,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Profile profile = snapshot.data!;
              DateFormat.yMMMd().format(profile.lastActive);

              return ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(profile.profileName),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: profile.avatar,
                      width: 256,
                      height: 256,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                      ),
                    ),
                  ),
                  Text(
                    "Conversations: ${profile.itemCount}",
                  ),
                  Text(
                    "Comments: ${profile.commentCount}",
                  ),
                  Text(
                    "Signed up: ${DateFormat.yMMMd().format(profile.created)}",
                  ),
                  Text(
                    "Last activity: ${DateFormat.yMMMd().format(profile.lastActive)}",
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 64.0,
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}
