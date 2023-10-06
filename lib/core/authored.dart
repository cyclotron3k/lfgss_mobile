import '../models/profile.dart';

abstract class Authored {
  Profile get createdBy;
  // Profile get editedBy;
  DateTime get created;
}
