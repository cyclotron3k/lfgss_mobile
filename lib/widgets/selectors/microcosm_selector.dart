import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../models/microcosm.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../models/search_result.dart';
import '../../services/debouncer.dart';
import '../microcosm_logo.dart';

class MicrocosmSelector extends StatefulWidget {
  final String? Function(Microcosm?) validator;
  final Function(Microcosm) onSelected;

  const MicrocosmSelector({
    super.key,
    required this.validator,
    required this.onSelected,
  });

  @override
  State<MicrocosmSelector> createState() => _MicrocosmSelectorState();
}

class _MicrocosmSelectorState extends State<MicrocosmSelector> {
  // bool _searching = false;
  Microcosm? _microcosm;

  final Debouncer<List<Widget>> _debouncer = Debouncer<List<Widget>>(
    milliseconds: 500,
    placeholder: const <Widget>[],
  );

  @override
  Widget build(BuildContext context) {
    return FormField<Microcosm>(
      validator: (_) => widget.validator(_microcosm),
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
                  label: const Text("Select a Microcosm"),
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
                      height: 0.5),
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
        query: "",
        inTitle: true,
        type: {'microcosm'},
      ),
    );

    int count = search.totalChildren > 5 ? 5 : search.totalChildren;
    log("Fobund $count results");
    List<Widget> results = [];

    for (int i = 0; i < count; i++) {
      SearchResult sr = await search.getChild(i);
      Microcosm microcosm = sr.child as Microcosm;
      log("Adding: ${microcosm.title}");
      results.add(
        ListTile(
          title: Text(microcosm.title),
          subtitle: Text(microcosm.description),
          leading: MicrocosmLogo(microcosm: microcosm),
          onTap: () {
            setState(() {
              _microcosm = microcosm;
              widget.onSelected(microcosm);
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
