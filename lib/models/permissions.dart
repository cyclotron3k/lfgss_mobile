class Permissions {
  final bool create;
  final bool read;
  final bool update;
  final bool delete;
  final bool closeOwn;
  final bool openOwn;
  final bool readOthers;
  final bool guest;
  final bool banned;
  final bool owner;
  final bool moderator;
  final bool siteOwner;

  Permissions({
    this.create = false,
    this.read = false,
    this.update = false,
    this.delete = false,
    this.closeOwn = false,
    this.openOwn = false,
    this.readOthers = false,
    this.guest = false,
    this.banned = false,
    this.owner = false,
    this.moderator = false,
    this.siteOwner = false,
  });

  Permissions.fromJson({required Map<String, dynamic>? json})
      : create = json?['create'] ?? false,
        read = json?['read'] ?? false,
        update = json?['update'] ?? false,
        delete = json?['delete'] ?? false,
        closeOwn = json?['closeOwn'] ?? false,
        openOwn = json?['openOwn'] ?? false,
        readOthers = json?['readOthers'] ?? false,
        guest = json?['guest'] ?? false,
        banned = json?['banned'] ?? false,
        owner = json?['owner'] ?? false,
        moderator = json?['moderator'] ?? false,
        siteOwner = json?['siteOwner'] ?? false;
}
