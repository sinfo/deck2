import 'package:flutter/cupertino.dart';
import 'package:frontend/models/team.dart';

class TeamsNotifier extends ChangeNotifier {
  List<Team> teams;

  TeamsNotifier({required this.teams});

  void add(Team s) {
    teams.add(s);
    notifyListeners();
  }

  void remove(Team t) {
    teams.removeWhere((team) => t.id == team.id);
    notifyListeners();
  }

  void edit(Team t) {
    int index = teams.indexWhere((team) => t.id == team.id);
    if (index != -1) {
      teams[index] = t;
      notifyListeners();
    }
  }
}
