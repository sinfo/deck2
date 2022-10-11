import 'package:flutter/cupertino.dart';
import 'package:frontend/models/session.dart';

class SessionsNotifier extends ChangeNotifier {
  List<Session> sessions;

  SessionsNotifier({required this.sessions});

  List<Session> getUpcoming() {
    return sessions.where((s) => DateTime.now().isBefore(s.begin)).toList();
  }

  List<Meeting> getPast() {
    return sessions.where((s) => DateTime.now().isAfter(s.begin)).toList();
  }

  void add(Session s) {
    sessions.add(s);
    notifyListeners();
  }

  void remove(Session s) {
    sessions.removeWhere((session) => s.id == session.id);
    notifyListeners();
  }

  void edit(Meeting s) {
    int index = sessions.indexWhere((session) => s.id == session.id);
    if (index != -1) {
      sessions[index] = s;
      notifyListeners();
    }
  }
}
