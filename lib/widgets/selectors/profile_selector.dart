import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/partial_profile.dart';

import '../../models/profiles.dart';

class ProfileSelector extends StatefulWidget {
  final Function(PartialProfile) onSelected;
  const ProfileSelector({
    super.key,
    required this.onSelected,
  });

  @override
  State<ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<ProfileSelector> {
  // bool _searching = false;

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (
        BuildContext context,
        SearchController controller,
      ) {
        return IconButton.filled(
          icon: const Icon(Icons.person_add_alt),
          onPressed: () {
            controller.openView();
          },
        );

        // return SearchBar(
        //   controller: controller,
        //   hintText: "Add participants",
        //   padding: const MaterialStatePropertyAll<EdgeInsets>(
        //     EdgeInsets.symmetric(
        //       horizontal: 16.0,
        //     ),
        //   ),
        //   onTap: () {
        //     controller.openView();
        //   },
        //   onChanged: (_) {
        //     controller.openView();
        //   },
        //   leading: const Icon(Icons.person_add_alt),
        //   trailing: const [Icon(Icons.search)],
        //   // trailing: [if (_searching) const CircularProgressIndicator()],
        // );
      },
      suggestionsBuilder: (
        BuildContext context,
        SearchController controller,
      ) async {
        String query = controller.value.text.trim();
        if (query == "") return List.empty();

        // setState(() {
        //   _searching = true;
        // });

        final Profiles profiles = await Profiles.search(query: query);

        int count = profiles.totalChildren > 5 ? 5 : profiles.totalChildren;

        List<Widget> results = [];

        for (int i = 0; i < count; i++) {
          PartialProfile profile = await profiles.getChild(i) as PartialProfile;
          results.add(
            ListTile(
              title: Text(profile.profileName),
              leading: CachedNetworkImage(
                imageUrl: profile.avatar,
                width: 28,
                height: 28,
                errorWidget: (context, url, error) => const Icon(
                  Icons.person_outline,
                ),
              ),
              onTap: () {
                setState(() {
                  widget.onSelected(profile);
                  controller.closeView("");
                });
              },
            ),
          );
        }

        // setState(() {
        //   _searching = false;
        // });

        return results;
      },
    );
  }
}
