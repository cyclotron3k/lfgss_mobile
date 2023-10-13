import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/search.dart';
import '../../models/search_parameters.dart';
import 'future_search_results_screen.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final SearchParameters? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum Ordering { recency, relevancy }

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  Ordering? _sortBy = Ordering.recency;
  final Set<SearchType> _filters = {};
  bool _following = false;
  bool _hasAttachment = false;
  bool _inTitle = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery == null) return;
    final SearchParameters iq = widget.initialQuery!;
    _query.text = iq.query;
    if (iq.following != null) _following = iq.following!;
    if (iq.hasAttachment != null) _hasAttachment = iq.hasAttachment!;
    if (iq.inTitle != null) _inTitle = iq.inTitle!;
    if (iq.type != null) _filters.addAll(iq.type!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            maintainState: true,
            builder: (context) => FutureSearchResultsScreen(
              showSummary: true,
              search: Search.search(
                searchParameters: _searchParameters,
              ),
            ),
          ),
        ),
        icon: const Icon(Icons.search),
        label: const Text("Search"),
      ),
      appBar: AppBar(title: const Text("Search")),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            TextFormField(
              controller: _query,
              autofocus: false,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Must have at least one character';
                } else {
                  return null;
                }
              },
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              // enabled: !_sending,
              spellCheckConfiguration:
                  kIsWeb ? null : const SpellCheckConfiguration(),
              decoration: const InputDecoration(
                labelText: 'Search for...',
                // border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32.0),
            const SectionTitle(title: "Types to display"),
            const SizedBox(height: 8.0),
            Wrap(spacing: 8.0, children: [
              for (final thing in SearchType.values)
                FilterChip(
                  label: Text(
                    toBeginningOfSentenceCase(
                      thing.name.toString(),
                    )!,
                  ),
                  selected: _filters.contains(thing),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _filters.add(thing);
                      } else {
                        _filters.remove(thing);
                      }
                    });
                  },
                ),
            ]),
            const SizedBox(height: 16.0),
            const SectionTitle(title: "Filters"),
            CheckboxListTile(
              title: const Text("Following"),
              value: _following,
              onChanged: (newValue) {
                setState(() {
                  _following = newValue ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text("Has attachment"),
              value: _hasAttachment,
              onChanged: (newValue) {
                setState(() {
                  _hasAttachment = newValue ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text("Title matches search terms"),
              value: _inTitle,
              onChanged: (newValue) {
                setState(() {
                  _inTitle = newValue ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16.0),
            const SectionTitle(title: "Order by"),
            RadioListTile(
              title: const Text('Recency'),
              onChanged: (Ordering? value) {
                setState(() {
                  _sortBy = value;
                });
              },
              value: Ordering.recency,
              groupValue: _sortBy,
            ),
            RadioListTile(
              title: const Text('Relevancy'),
              value: Ordering.relevancy,
              groupValue: _sortBy,
              onChanged: (Ordering? value) {
                setState(() {
                  _sortBy = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  SearchParameters get _searchParameters {
    return SearchParameters(
      query: _query.text,
      type: _filters,
      inTitle: _inTitle,
      following: _following,
      hasAttachment: _hasAttachment,
      sort: _sortBy == Ordering.recency ? 'date' : null,
      // authorId: 1234,
      // since: -5,
      // until: -2,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
