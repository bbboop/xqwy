import 'package:flutter/foundation.dart';

class HealthSyncProvider with ChangeNotifier {
  bool _hasSyncedThisSession = false;

  bool get hasSyncedThisSession => _hasSyncedThisSession;

  void setHasSyncedThisSession(bool value) {
    _hasSyncedThisSession = value;
    notifyListeners();
  }
}
