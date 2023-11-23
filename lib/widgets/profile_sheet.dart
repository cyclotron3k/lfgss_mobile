import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/full_profile.dart';
import '../models/profile.dart';
import '../models/search.dart';
import '../models/search_parameters.dart';
import '../services/microcosm_client.dart';
import 'adaptable_form.dart';
import 'screens/future_search_results_screen.dart';
import 'time_ago.dart';

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({
    super.key,
    required this.profile,
  });

  final Profile profile;

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late Future<FullProfile> fullProfile;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    fullProfile = widget.profile.getFullProfile(ignoreCache: true);
  }

  Future<void> _searchFor(
    BuildContext context,
    String title,
    Set<SearchType> types,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (context) => FutureSearchResultsScreen(
          search: Search.search(
            searchParameters: SearchParameters(
              query: "authorId:${widget.profile.id}",
              type: types,
            ),
          ),
          title: title,
          showSummary: false,
        ),
      ),
    );
    return;
  }

  Future<void> _searchForPosts(BuildContext context) => _searchFor(
        context,
        "Posts by ${widget.profile.profileName}",
        {
          SearchType.conversation,
          SearchType.event,
        },
      );

  Future<void> _searchForComments(BuildContext context) => _searchFor(
        context,
        "Comments by ${widget.profile.profileName}",
        {
          SearchType.comment,
        },
      );

  Future<void> _sendMessage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        maintainState: true,
        builder: (context) => AdaptableForm(
          lock: true,
          defaultOperationType: OperationType.newHuddle,
          initialParticipants: {widget.profile},
          onPostSuccess: () {},
        ),
      ),
    );
    return;
  }

  Future<void> _unignore(BuildContext context, FullProfile fullProfile) async {
    setState(() => _active = true);
    await widget.profile.unignore();
    if (!context.mounted) return;
    setState(() {
      _active = false;
      fullProfile.flags.ignored = false;
      MicrocosmClient().clearCache();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Successfully unignored ${widget.profile.profileName}"),
        duration: TOAST_DURATION,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Hide bottom sheet
    // Navigator.pop(context);

    return;
  }

  Future<void> _ignore(BuildContext context, FullProfile fullProfile) async {
    bool? ignore = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ignore user'),
        content: Text(
          'Are you sure you want to ignore ${widget.profile.profileName}?',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('YES'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    if (ignore != true) return;

    setState(() => _active = true);
    await widget.profile.ignore();
    if (!context.mounted) return;
    setState(() {
      _active = false;
      fullProfile.flags.ignored = true;
      MicrocosmClient().clearCache();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Successfully ignored ${widget.profile.profileName}"),
        duration: TOAST_DURATION,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Hide bottom sheet:
    // Navigator.pop(context);

    return;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12.0),
              CachedNetworkImage(
                imageUrl: widget.profile.avatar,
                width: 98.0,
                height: 98.0,
                errorWidget: (context, url, error) => const Icon(
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge,
                      widget.profile.profileName,
                    ),
                    FutureBuilder(
                      future: fullProfile,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Placeholder();
                        } else if (snapshot.hasData) {
                          return _profileBodyBuilder(context, snapshot.data!);
                        }
                        return const Text("Loading...");
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileBodyBuilder(
    BuildContext context,
    FullProfile fp,
  ) {
    final nf = NumberFormat();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Member since ${DateFormat('d MMMM, y').format(fp.created)}",
          style: const TextStyle(color: Colors.grey),
        ),
        Row(
          children: [
            const Text(
              "Last active ",
              style: TextStyle(color: Colors.grey),
            ),
            TimeAgo(
              fp.lastActive,
              color: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 20.0),
        Wrap(
          spacing: 8.0,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.search),
              onPressed: () => _searchForComments(
                context,
              ),
              label: Text(
                "${nf.format(fp.commentCount)} comments",
              ),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.search),
              onPressed: () => _searchForPosts(
                context,
              ),
              label: Text(
                "${nf.format(fp.itemCount)} posts",
              ),
            ),
          ],
        ),
        // fp.flags.ignored
        //     ? OutlinedButton.icon(
        //         style: const ButtonStyle(
        //           foregroundColor: MaterialStatePropertyAll(
        //             Colors.red,
        //           ),
        //         ),
        //         onPressed: _active ? null : () => _unignore(context, fp),
        //         icon: _active
        //             ? const SizedBox.square(
        //                 dimension: 24.0,
        //                 child: CircularProgressIndicator(),
        //               )
        //             : const Icon(Icons.block),
        //         label: const Text("Unignore"),
        //       )
        //     : FilledButton.icon(
        //         style: const ButtonStyle(
        //           backgroundColor: MaterialStatePropertyAll(
        //             Colors.red,
        //           ),
        //         ),
        //         onPressed: _active ? null : () => _ignore(context, fp),
        //         icon: _active
        //             ? const SizedBox.square(
        //                 dimension: 24.0,
        //                 child: CircularProgressIndicator(),
        //               )
        //             : const Icon(Icons.block),
        //         label: const Text("Ignore"),
        //       ),
        FilledButton.icon(
          onPressed: () => _sendMessage(context),
          icon: const Icon(Icons.mail_outline),
          label: const Text("Message"),
        ),
      ],
    );
  }
}
