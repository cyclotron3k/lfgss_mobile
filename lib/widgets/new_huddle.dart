import 'dart:developer' show log;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lfgss_mobile/widgets/profile_selector.dart';

import '../models/partial_profile.dart';

class NewHuddle extends StatefulWidget {
  final Set<PartialProfile> initialParticipants;

  const NewHuddle({
    super.key,
    required this.initialParticipants,
  });

  @override
  State<NewHuddle> createState() => _NewHuddleState();
}

class _NewHuddleState extends State<NewHuddle> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final Set<PartialProfile> _participants = {};

  void _addParticipant(PartialProfile profile) {
    setState(() {
      _participants.add(profile);
    });
  }

  @override
  void initState() {
    super.initState();
    _participants.addAll(widget.initialParticipants);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Huddle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Participants'),
            const SizedBox(height: 8.0),
            Wrap(
              children: [
                ..._participants.map((participant) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      avatar: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: CachedNetworkImage(
                          imageUrl: participant.avatar,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person_outline,
                          ),
                        ),
                      ),
                      label: Text(participant.profileName),
                      onDeleted: () {
                        setState(() {
                          _participants.remove(participant);
                        });
                      },
                    ),
                  );
                }).toList(),
                ProfileSelector(selectedParticipant: _addParticipant),
              ],
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _bodyController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Body',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Send the email with the subject, recipients, and body
          // You can implement the email sending logic here
          // For simplicity, we'll just print the values
          log('Subject: ${_subjectController.text}');
          log('Recipients: $_participants');
          log('Body: ${_bodyController.text}');
        },
        child: const Icon(Icons.send),
      ),
    );
  }
}
