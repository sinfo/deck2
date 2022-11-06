import 'package:flutter/cupertino.dart';
import 'package:frontend/models/team.dart';

class TeamsNotifier extends ChangeNotifier {
  List<Team> team;

  TeamsNotifier({required this.team});

  void add(Team s) {
    team.add(s);
    notifyListeners();
  }

  void remove(Team s) {
    team.remove(s);
    notifyListeners();
  }

  void edit(Team s) {
    int index = team.indexOf(s);
    if (index != -1) {
      team[index] = s;
      notifyListeners();
    }
  }
}
