class Flags {
  final bool sticky;
  final bool open;
  final bool deleted;
  final bool moderated;
  final bool visible;
  bool unread;
  bool watched;
  bool sendEmail;
  bool sendSMS;

  Flags({
    this.sticky = false,
    this.open = false,
    this.deleted = false,
    this.moderated = false,
    this.visible = false,
    this.unread = false,
    this.watched = false,
    this.sendEmail = false,
    this.sendSMS = false,
  });

  Flags.fromJson({required Map<String, dynamic> json})
      : sticky = json['sticky'] ?? false,
        open = json['open'] ?? false,
        deleted = json['deleted'] ?? false,
        moderated = json['moderated'] ?? false,
        visible = json['visible'] ?? false,
        unread = json['unread'] ?? false,
        watched = json['watched'] ?? false,
        sendEmail = json['sendEmail'] ?? false,
        sendSMS = json['sendSMS'] ?? false;
}
