class Flags {
  final bool sticky;
  final bool open;
  final bool deleted;
  final bool moderated;
  final bool visible;
  bool ignored;
  bool unread;
  bool watched;
  bool sendEmail;
  bool sendSMS;
  bool attending;

  Flags({
    this.sticky = false,
    this.open = false,
    this.deleted = false,
    this.moderated = false,
    this.visible = false,
    this.unread = false,
    this.watched = false,
    this.ignored = false,
    this.sendEmail = false,
    this.sendSMS = false,
    this.attending = false,
  });

  Flags.fromJson({required Map<String, dynamic> json})
      : sticky = json['sticky'] ?? false,
        open = json['open'] ?? false,
        deleted = json['deleted'] ?? false,
        moderated = json['moderated'] ?? false,
        visible = json['visible'] ?? false,
        unread = json['unread'] ?? false,
        watched = json['watched'] ?? false,
        ignored = json['ignored'] ?? false,
        sendEmail = json['sendEmail'] ?? false,
        sendSMS = json['sendSMS'] ?? false,
        attending = json['attending'] ?? false;
}
