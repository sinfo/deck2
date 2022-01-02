import 'package:flutter/cupertino.dart';
import 'package:frontend/models/member.dart';

class MemberTableNotifier extends ChangeNotifier {
  List<Member> members;

  MemberTableNotifier({required this.members});


  void add(Member m) {
    members.add(m);
    notifyListeners();
  }

  void remove(Member m) {
    members.remove(m);
    notifyListeners();
  }

  void edit(Member m) {
    int index = members.indexOf(m);
    if (index != -1) {
      members[index] = m;
      notifyListeners();
    }
  }
}
