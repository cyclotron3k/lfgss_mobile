import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;
import 'package:provider/provider.dart';

import '../../models/search.dart';
import '../../models/search_parameters.dart';
import '../../services/settings.dart';
import 'future_search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final SearchParameters? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum Ordering { recency, relevancy }

class _SearchScreenState extends State<SearchScreen> {
  static const String _searchHistoryKey = 'searchHistory';
  static const int _maxSearchHistoryItems = 10;

  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();
  Ordering? _sortBy = Ordering.recency;
  final Set<SearchType> _filters = {};
  bool _following = false;
  bool _hasAttachment = false;
  bool _inTitle = true;
  List<String> _searchHistory = const [];

  @override
  void initState() {
    super.initState();
    _queryFocusNode.addListener(_handleQueryFocusChange);
    if (widget.initialQuery == null) return;
    final SearchParameters iq = widget.initialQuery!;
    _query.text = iq.query;
    if (iq.following != null) _following = iq.following!;
    if (iq.hasAttachment != null) _hasAttachment = iq.hasAttachment!;
    if (iq.inTitle != null) _inTitle = iq.inTitle!;
    if (iq.type != null) _filters.addAll(iq.type!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _queryFocusNode
      ..removeListener(_handleQueryFocusChange)
      ..dispose();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ElevatedButton.icon(
        onPressed: () async {
          final query = _query.text.trim();
          if (query.isEmpty) return;

          await _saveSearchTerm(query);
          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              maintainState: true,
              builder: (context) => FutureSearchResultsScreen(
                search: Search.search(
                  searchParameters: _searchParameters,
                ),
              ),
            ),
          );
        },
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
              focusNode: _queryFocusNode,
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
            if (_queryFocusNode.hasFocus && _searchHistory.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Card(
                child: Column(
                  children: [
                    for (final term in _searchHistory)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.history),
                        title: Text(term),
                        onTap: () => _applySearchTerm(term),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Delete search',
                          onPressed: () => _deleteSearchTerm(term),
                        ),
                      ),
                  ],
                ),
              ),
            ],
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
            const SizedBox(height: 22.0),
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
            RadioGroup<Ordering>(
              groupValue: _sortBy,
              onChanged: (Ordering? value) {
                if (value == null) return;
                setState(() {
                  _sortBy = value;
                });
              },
              child: Column(
                children: const [
                  RadioListTile<Ordering>(
                    title: Text('Recency'),
                    value: Ordering.recency,
                  ),
                  RadioListTile<Ordering>(
                    title: Text('Relevancy'),
                    value: Ordering.relevancy,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SearchParameters get _searchParameters {
    return SearchParameters(
      query: _query.text.trim(),
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

  void _handleQueryFocusChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _loadSearchHistory() {
    final history =
        context.read<Settings>().getStringList(_searchHistoryKey) ?? const [];
    if (_listsEqual(_searchHistory, history)) return;
    setState(() {
      _searchHistory = List<String>.from(history);
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    final settings = context.read<Settings>();
    final updatedHistory = [
      term,
      ..._searchHistory.where((item) => item != term),
    ];
    if (updatedHistory.length > _maxSearchHistoryItems) {
      updatedHistory.removeRange(
        _maxSearchHistoryItems,
        updatedHistory.length,
      );
    }

    await settings.setStringList(_searchHistoryKey, updatedHistory);
    if (!mounted) return;
    setState(() {
      _searchHistory = updatedHistory;
    });
  }

  Future<void> _deleteSearchTerm(String term) async {
    final updatedHistory =
        _searchHistory.where((item) => item != term).toList(growable: false);
    await context
        .read<Settings>()
        .setStringList(_searchHistoryKey, updatedHistory);
    if (!mounted) return;
    setState(() {
      _searchHistory = updatedHistory;
    });
  }

  void _applySearchTerm(String term) {
    _query.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _queryFocusNode.requestFocus();
    setState(() {});
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
