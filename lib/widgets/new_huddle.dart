import 'dart:developer' show log;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/partial_profile.dart';
import 'profile_selector.dart';

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
              maxLength: 150,
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
            // NewComment(
            //   itemId: 0,
            //   itemType: "huddle",
            //   onPostSuccess: () {},
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Map<String, dynamic> huddlePayload = {
            "isConfidential": false,
            "title": _subjectController.text,
          };

          // PUT /api/v1/huddles/$id/participants
          // Content-type: application/json
          // Body: [{"id": 1234}, {"id": 1235}]
          List<Map<String, int>> invitePayload = _participants.map(
            (p) {
              return <String, int>{"id": p.id};
            },
          ).toList();

          // commentPayload = {};

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
