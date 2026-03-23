import 'dart:developer' show log;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quiver/collection.dart' show LruMap;

import '../models/profile.dart';
import '../models/profiles.dart';
import '../services/avatar_cache_manager.dart';

class ProfilePickerPopup extends StatefulWidget {
  const ProfilePickerPopup({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  final TextEditingController controller;
  final Function(Profile) onSelected;

  @override
  State<ProfilePickerPopup> createState() => _ProfilePickerPopupState();
}

class _ProfilePickerPopupState extends State<ProfilePickerPopup> {
  final _cache = LruMap<String, Future<Profiles>>();
  String? _currentQuery;
  Profiles? _displayProfiles;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_handleTypingEvent);
    _handleTypingEvent();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTypingEvent);
    super.dispose();
  }

  Future<void> _update(String word) async {
    _currentQuery = word;
    await _searchFor(word);
  }

  Future<void> _searchFor(String word) async {
    if (!_cache.containsKey(word)) {
      _cache[word] = Profiles.search(query: word);
    }

    _scrolltoTop();
    Profiles profiles = await _cache[word]!;

    // current search may have changed by the time we get a response...
    if (_currentQuery == word) {
      log("Search for $word completed");
      if (mounted) setState(() => _displayProfiles = profiles);
    } else {
      log("Search for $word completed, but the current search term is now $_currentQuery, so I'm ignoring it");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_displayProfiles == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return ListView.builder(
        shrinkWrap: true,
        controller: _controller,
        padding: const EdgeInsets.all(8.0),
        itemCount: _displayProfiles!.totalChildren,
        itemBuilder: (BuildContext context, int index) {
          return FutureBuilder(
            future: _displayProfiles!.getChild(index),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final profile = snapshot.data!;
                return ListTile(
                  title: Text(profile.profileName),
                  dense: true,
                  leading: CachedNetworkImage(
                    imageUrl: profile.avatar,
                    cacheManager: AvatarCacheManager.instance,
                    width: 28.0,
                    height: 28.0,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person_outline,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      widget.onSelected(profile);
                      //controller.closeView("");
                    });
                  },
                );
              } else if (snapshot.hasError) {
                return const ListTile(
                  title: Text("Error"),
                  leading: Icon(
                    Icons.error_outline,
                    size: 28.0,
                  ),
                ); // TODO
              } else {
                return ListTile(
                  title: const Text("Loading..."),
                  dense: true,
                  leading: Container(
                    color: Colors.grey,
                    width: 28.0,
                    height: 28.0,
                  ),
                );
              }
            },
          );
        },
      );
    }
  }

  void _scrolltoTop() {
    if (_controller.hasClients) {
      _controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleTypingEvent() {
    TextSelection ts = widget.controller.selection;

    // Check for multi-character selection
    if (ts.baseOffset != ts.extentOffset) return;

    int startIndex = ts.baseOffset;
    int endIndex = ts.baseOffset;
    final String text = widget.controller.text;
    final nonSpace = RegExp(r'[^\s]');

    if (text.isEmpty) return;

    while (startIndex > 0 && nonSpace.hasMatch(text[startIndex - 1])) {
      startIndex--;
    }

    if (startIndex >= text.length || text[startIndex] != "@") return;

    while (endIndex < text.length && nonSpace.hasMatch(text[endIndex])) {
      endIndex++;
    }

    if (startIndex == endIndex) return;

    String word = text.substring(startIndex, endIndex);

    _update(word);
  }
}
