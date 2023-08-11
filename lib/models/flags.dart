typedef Json = Map<String, dynamic>;

class Flags {
  final bool sticky;
  final bool open;
  final bool deleted;
  final bool moderated;
  final bool visible;
  final bool unread;

  Flags({
    this.sticky = false,
    this.open = false,
    this.deleted = false,
    this.moderated = false,
    this.visible = false,
    this.unread = false,
  });

  Flags.fromJson({required Json json})
      : sticky = json['sticky'] ?? false,
        open = json['open'] ?? false,
        deleted = json['deleted'] ?? false,
        moderated = json['moderated'] ?? false,
        visible = json['visible'] ?? false,
        unread = json['unread'] ?? false;
}
