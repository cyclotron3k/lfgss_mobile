import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum ItemType {
  newConversation,
  conversationComment,
  newHuddle,
  huddleComment,
}

class AdaptableForm extends StatefulWidget {
  final bool showTypeSelector;
  final ItemType defaultItemType;
  const AdaptableForm({
    super.key,
    this.showTypeSelector = true,
    this.defaultItemType = ItemType.conversationComment,
  });

  @override
  State<AdaptableForm> createState() => _AdaptableFormState();
}

class _AdaptableFormState extends State<AdaptableForm> {
  late ItemType _itemTypeSelector;

  @override
  void initState() {
    super.initState();
    _itemTypeSelector = widget.defaultItemType;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Form(
          child: Column(
            children: [
              DropdownMenu(
                initialSelection: _itemTypeSelector,
                onSelected: (value) => setState(() {
                  if (value != null) {
                    _itemTypeSelector = value;
                  }
                }),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: ItemType.newConversation,
                    label: "New Conversation",
                  ),
                  DropdownMenuEntry(
                    value: ItemType.conversationComment,
                    label: "Comment in Conversation",
                  ),
                  DropdownMenuEntry(
                    value: ItemType.newHuddle,
                    label: "New Huddle",
                  ),
                  DropdownMenuEntry(
                    value: ItemType.huddleComment,
                    label: "Comment in Huddle",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
