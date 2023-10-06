import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/huddle.dart';

class HuddleHeader extends StatelessWidget {
  const HuddleHeader({
    super.key,
    required this.huddle,
  });

  final Huddle huddle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                for (final participant in huddle.participants)
                  Chip(
                    key: ValueKey(participant.id),
                    avatar: CachedNetworkImage(
                      imageUrl: participant.avatar,
                      imageBuilder: (context, imageProvider) {
                        log("${participant.profileName}: ${participant.avatar}");
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image(image: imageProvider),
                        );
                      },
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person_outline,
                      ),
                    ),
                    label: Text(participant.profileName),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
