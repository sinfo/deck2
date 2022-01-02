import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:frontend/models/team.dart';

class TeamTableNotifier extends ChangeNotifier {
  List<Team> teams;

  TeamTableNotifier({required this.teams});

  UnmodifiableListView<Team> get tms => UnmodifiableListView(this.teams);

  void add(Team t) {
    teams.add(t);
    notifyListeners();
  }

  void remove(Team t) {
    teams.remove(t);
    notifyListeners();
  }

  void edit(Team t) {
    int index = teams.indexOf(t);
    if (index != -1) {
      teams[index] = t;
      notifyListeners();
    }
  }
}
