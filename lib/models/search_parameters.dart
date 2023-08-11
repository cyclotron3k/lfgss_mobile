class SearchParameters {
  final String query;
  final Set<String>? type;
  final bool? inTitle;
  final bool? following;
  final bool? hasAttachment;
  final int? authorId;
  final int? since;

  // Types:
  // comment, conversation, event, huddle, microcosm, poll, profile

  // Query             string    `json:"q,omitempty"`
  // InTitle           bool      `json:"inTitle,omitempty"`
  // Hashtags          []string  `json:"hashtags,omitempty"`
  // MicrocosmIDsQuery []int64   `json:"forumId,omitempty"`
  // MicrocosmIDs      []int64   `json:"-"`
  // ItemTypesQuery    []string  `json:"type,omitempty"`
  // ItemTypeIDs       []int64   `json:"-"`
  // ItemIDsQuery      []int64   `json:"id,omitempty"`
  // ItemIDs           []int64   `json:"-"`
  // ProfileID         int64     `json:"authorId,omitempty"`
  // Emails            []string  `json:"email,omitempty"` // admin only
  // Following         bool      `json:"following,omitempty"`
  // Since             string    `json:"since,omitempty"`
  // SinceTime         time.Time `json:"-"`
  // Until             string    `json:"until,omitempty"`
  // UntilTime         time.Time `json:"-"`
  // EventAfter        string    `json:"eventAfter,omitempty"`
  // EventAfterTime    time.Time `json:"-"`
  // EventBefore       string    `json:"eventBefore,omitempty"`
  // EventBeforeTime   time.Time `json:"-"`
  // Attendee          bool      `json:"attendee,omitempty"`
  // Has               []string  `json:"has,omitempty"`
  // Sort              string    `json:"sort,omitempty"`

  SearchParameters({
    required this.query,
    this.type,
    this.inTitle,
    this.following,
    this.hasAttachment,
    this.authorId,
    this.since,
  });

  Map<String, dynamic> get asQueryParameters {
    Map<String, dynamic> parameters = {"q": query};

    if (type != null) {
      parameters["type"] = type;
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

    return parameters;
  }
}
