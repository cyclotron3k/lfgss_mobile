import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lfgss_mobile/models/search_result.dart';

import '../../models/microcosm.dart';
import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../services/debouncer.dart';
import '../microcosm_logo.dart';

class MicrocosmSelector extends StatefulWidget {
  final Function(Microcosm) onSelected;
  const MicrocosmSelector({
    super.key,
    required this.onSelected,
  });

  @override
  State<MicrocosmSelector> createState() => _MicrocosmSelectorState();
}

class _MicrocosmSelectorState extends State<MicrocosmSelector> {
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
        query: "",
        inTitle: true,
        type: {'microcosm'},
      ),
    );

    int count = search.totalChildren > 5 ? 5 : search.totalChildren;
    log("Fobund $count results");
    List<Widget> results = [];

    for (int i = 0; i < count; i++) {
      SearchResult sr = await search.getChild(i) as SearchResult;
      Microcosm microcosm = sr.child as Microcosm;
      log("Adding: ${microcosm.title}");
      results.add(
        ListTile(
          title: Text(microcosm.title),
          subtitle: Text(microcosm.description),
          leading: MicrocosmLogo(microcosm: microcosm),
          onTap: () {
            setState(() {
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
