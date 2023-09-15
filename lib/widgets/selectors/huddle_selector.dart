import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../models/huddle.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../models/search_result.dart';
import '../../services/debouncer.dart';

class HuddleSelector extends StatefulWidget {
  final String? Function(Huddle?) validator;
  final Function(Huddle) onSelected;

  const HuddleSelector({
    super.key,
    required this.validator,
    required this.onSelected,
  });

  @override
  State<HuddleSelector> createState() => _HuddleSelectorState();
}

class _HuddleSelectorState extends State<HuddleSelector> {
  // bool _searching = false;
  Huddle? _huddle;
  final Debouncer<List<Widget>> _debouncer = Debouncer<List<Widget>>(
    milliseconds: 500,
    placeholder: const <Widget>[],
  );

  @override
  Widget build(BuildContext context) {
    return FormField<Huddle>(
      validator: (_) => widget.validator(_huddle),
      builder: (formFieldState) {
        return Column(
          children: [
            SearchAnchor(
              builder: (
                BuildContext context,
                SearchController controller,
              ) {
                return ElevatedButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text("Select a Huddle"),
                  onPressed: () => controller.openView(),
                );
              },
              suggestionsBuilder: (context, controller) => _debouncer.run(
                () => _executeSearch(
                  context,
                  controller,
                ),
              ),
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
        type: {'huddle'},
        sort: 'date',
      ),
    );

    int count = search.totalChildren > 5 ? 5 : search.totalChildren;
    log("Found $count results");
    List<Widget> results = [];

    for (int i = 0; i < count; i++) {
      SearchResult sr = await search.getChild(i) as SearchResult;
      Huddle huddle = sr.child as Huddle;
      log("Adding: ${huddle.title}");
      results.add(
        ListTile(
          title: Text(huddle.title),
          leading: const Icon(Icons.forum),
          onTap: () {
            setState(() {
              _huddle = huddle;
              widget.onSelected(huddle);
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
