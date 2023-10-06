typedef Json = Map<String, dynamic>;

class Link {
  final String rel;
  final Uri href;
  final String? title;

  Link.fromJson({required Json json})
      : rel = json["rel"],
        href = Uri.parse(json["href"]),
        title = json["title"];
}

class Links {
  final Map<String, Link> links;

  static Map<String, Link> _linkParser({required List<dynamic>? json}) {
    Map<String, Link> links = {};

    if (json != null) {
      for (Json jlink in json) {
        var link = Link.fromJson(json: jlink);
        links[link.rel] = link;
      }
    }

    return links;
  }

  Links.fromJson({required List<dynamic>? json})
      : links = _linkParser(json: json);

  Link? operator [](String key) => links[key]; // get

  bool containsKey(String key) => links.containsKey(key);
}
