import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../models/conversation.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../models/search_result.dart';
import '../../services/debouncer.dart';

class ConversationSelector extends StatefulWidget {
  final Function(Conversation) onSelected;
  const ConversationSelector({
    super.key,
    required this.onSelected,
  });

  @override
  State<ConversationSelector> createState() => _ConversationSelectorState();
}

class _ConversationSelectorState extends State<ConversationSelector> {
  // bool _searching = false;
  final Debouncer<List<Widget>> _debouncer = Debouncer<List<Widget>>(
    milliseconds: 500,
    placeholder: const <Widget>[],
  );

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (
        BuildContext context,
        SearchController controller,
      ) {
        return IconButton.filled(
          icon: const Icon(Icons.search),
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
      suggestionsBuilder: (context, controller) => _debouncer.run(
        () => _executeSearch(
          context,
          controller,
        ),
      ),
    );
  }

  Future<List<Widget>> _executeSearch(
    BuildContext context,
    SearchController controller,
  ) async {
    String query = controller.value.text.trim();
    if (query == "") return List.empty();

    // setState(() {
    //   _searching = true;
    // });

    final Search search = await Search.search(
      searchParameters: SearchParameters(
        query: query,
        inTitle: true,
        type: {'conversation'},
        sort: 'date',
      ),
    );

    int count = search.totalChildren > 5 ? 5 : search.totalChildren;
    log("Found $count results");
    List<Widget> results = [];

    for (int i = 0; i < count; i++) {
      SearchResult sr = await search.getChild(i) as SearchResult;
      Conversation conversation = sr.child as Conversation;
      log("Adding: ${conversation.title}");
      results.add(
        ListTile(
          title: Text(conversation.title),
          leading: const Icon(Icons.forum),
          onTap: () {
            setState(() {
              widget.onSelected(conversation);
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
  }
}
