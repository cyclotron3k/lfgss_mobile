enum SearchType {
  microcosm,
  conversation,
  event,
  profile,
  huddle,
  comment,
}

class SearchParameters {
  final String query;
  final Set<SearchType>? type;
  final bool? inTitle;
  final bool? following;
  final bool? hasAttachment;
  final int? authorId;
  final int? since;
  final int? until;
  final String? sort;

  // Types:
  // comment, conversation, event, huddle, microcosm, poll, profile

  // q           string
  // inTitle     bool
  // hashtags    []string
  // forumId     []int64
  // type        []string
  // id          []int64
  // authorId    int64
  // email       []string - admin only
  // following   bool
  // since       int offset (days) | date | datetime
  // until       int offset (days) | date | datetime
  // eventAfter  int offset (days) | date | datetime
  // eventBefore int offset (days) | date | datetime
  // attendee    bool
  // has         []string
  // sort        string

  SearchParameters({
    required this.query,
    this.type,
    this.inTitle,
    this.following,
    this.hasAttachment,
    this.authorId,
    this.since,
    this.until,
    this.sort,
  });

  SearchParameters.fromUri(Uri uri)
      : query = uri.queryParameters['q'] ?? '',
        type = uri.queryParameters.containsKey('type')
            ? uri.queryParametersAll['type']!
                .map(
                  (e) => SearchType.values.byName(e),
                )
                .toSet()
            : null,
        inTitle = uri.queryParameters.containsKey('inTitle')
            ? bool.parse(uri.queryParameters['inTitle']!)
            : null,
        following = uri.queryParameters.containsKey('following')
            ? bool.parse(uri.queryParameters['following']!)
            : null,
        hasAttachment = uri.queryParameters.containsKey('hasAttachment')
            ? bool.parse(uri.queryParameters['hasAttachment']!)
            : null,
        authorId = uri.queryParameters.containsKey('authorId')
            ? int.parse(uri.queryParameters['authorId']!)
            : null,
        since = uri.queryParameters.containsKey('since')
            ? int.parse(uri.queryParameters['since']!)
            : null,
        until = uri.queryParameters.containsKey('until')
            ? int.parse(uri.queryParameters['until']!)
            : null,
        sort = uri.queryParameters.containsKey('sort')
            ? uri.queryParameters['sort']!
            : null;

  Map<String, dynamic> get asQueryParameters {
    Map<String, dynamic> parameters = {"q": query};

    if (type != null) {
      parameters["type"] = type?.map<String>((e) => e.name).toList();
    }

    if (inTitle ?? false) {
      parameters["inTitle"] = "true";
    }

    if (following ?? false) {
      parameters["following"] = "true";
    }

    if (hasAttachment ?? false) {
      // Should probably use a Set, but only one type has been implemented
      parameters["hasAttachment"] = "true";
    }

    if (authorId != null) {
      parameters["authorId"] = authorId.toString();
    }

    if (since != null) {
      parameters["since"] = since.toString();
    }

    if (until != null) {
      parameters["until"] = until.toString();
    }

    if (sort != null) {
      parameters["sort"] = sort;
    }

    return parameters;
  }
}
