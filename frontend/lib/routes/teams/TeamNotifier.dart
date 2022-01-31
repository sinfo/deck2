import 'package:flutter/cupertino.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/models/member.dart';
import 'package:collection/collection.dart';

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

  void removeMember(Member m) {
    // Procurar por teams
    for (Team t in tms) {
      int index = t.membersID!.indexWhere(
          (TeamMember tm) => tm.memberID != null && tm.memberID == m.id);

      // Remove member from this team
      if (index != -1) {
        t.membersID!.remove(index);
        notifyListeners();
      }
    }
  }

  void editMember(Member m) {
    // Procurar por teams
    for (Team t in tms) {
      print("Here");
      int index = t.membersID!.indexWhere(
              (TeamMember tm) => tm.memberID != null && tm.memberID == m.id);

      //Membro está na team
      if (index != -1) {
        
        notifyListeners();
      }
    }
  }
}
