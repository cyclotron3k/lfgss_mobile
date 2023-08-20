import 'package:flutter/material.dart';

// import 'profile_screen.dart';
import '../models/profile.dart';

class FutureProfileScreen extends StatefulWidget {
  final Future<Profile> profile;
  const FutureProfileScreen({super.key, required this.profile});

  @override
  State<FutureProfileScreen> createState() => _FutureProfileScreenState();
}

class _FutureProfileScreenState extends State<FutureProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Profile>(
      future: widget.profile,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // return ProfileScreen(profile: snapshot.data!);
          return const Placeholder();
        } else if (snapshot.hasError) {
          return Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64.0,
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
