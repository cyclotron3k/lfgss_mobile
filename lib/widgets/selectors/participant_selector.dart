import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/profile.dart';
import 'profile_selector.dart';

class ParticipantSelector extends StatefulWidget {
  const ParticipantSelector({
    super.key,
    required this.validator,
    required this.onChanged,
    this.initialParticipants = const {},
  });

  final String? Function(Set<Profile>?) validator;
  final Function(Set<Profile>) onChanged;
  final Set<Profile> initialParticipants;

  @override
  State<ParticipantSelector> createState() => _ParticipantSelectorState();
}

class _ParticipantSelectorState extends State<ParticipantSelector> {
  final Set<Profile> _selectedParticipants = {};

  @override
  void initState() {
    super.initState();
    _selectedParticipants.addAll(widget.initialParticipants);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<Set<Profile>>(
      validator: (_) => widget.validator(_selectedParticipants),
      builder: (formFieldState) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text('Participants'),
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final participant in _selectedParticipants)
                  Chip(
                    key: ValueKey(participant.id),
                    avatar: CachedNetworkImage(
                      imageUrl: participant.avatar,
                      imageBuilder: (context, imageProvider) => ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image(image: imageProvider),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person_outline,
                      ),
                    ),
                    label: Text(participant.profileName),
                    onDeleted: () {
                      setState(() {
                        _selectedParticipants.remove(participant);
                        widget.onChanged(_selectedParticipants);
                      });
                    },
                  ),
                ProfileSelector(
                  onSelected: (p) => setState(() {
                    _selectedParticipants.add(p);
                    widget.onChanged(_selectedParticipants);
                  }),
                ),
              ],
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 10),
                child: Text(
                  formFieldState.errorText!,
                  style: TextStyle(
                    fontStyle: FontStyle.normal,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                    height: 0.5,
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}
