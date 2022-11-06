import 'package:flutter/cupertino.dart';
import 'package:frontend/models/meeting.dart';

class MeetingsNotifier extends ChangeNotifier {
  List<Meeting> meetings;

  MeetingsNotifier({required this.meetings});

  List<Meeting> getUpcoming() {
    return meetings.where((m) => DateTime.now().isBefore(m.begin)).toList();
  }

  List<Meeting> getPast() {
    return meetings.where((m) => DateTime.now().isAfter(m.begin)).toList();
  }

  void add(Meeting m) {
    meetings.add(m);
    notifyListeners();
  }

  void remove(Meeting m) {
    meetings.removeWhere((meet) => m.id == meet.id);
    notifyListeners();
  }

  void edit(Meeting m) {
    int index = meetings.indexWhere((meet) => m.id == meet.id);
    if (index != -1) {
      meetings[index] = m;
      notifyListeners();
    }
  }
}
