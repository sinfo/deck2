import 'package:flutter/cupertino.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';

class CompanyTableNotifier extends ChangeNotifier {
  List<Company> companies;

  CompanyTableNotifier({required this.companies});

  List<Company> getByMember(String id, int event, ParticipationStatus status) {
    var s = companies
        .where((s) => s.participations!.any((p) {
              return p.event == event &&
                  p.memberId == id &&
                  (status == ParticipationStatus.NO_STATUS ||
                      p.status == status);
            }))
        .toList();
    s.sort((a, b) => STATUSORDER[a.participations!
            .firstWhere((element) => element.event == event)
            .status]!
        .compareTo(STATUSORDER[b.participations!
            .firstWhere((element) => element.event == event)
            .status]!));
    return s;
  }

  void add(Company s) {
    companies.add(s);
    notifyListeners();
  }

  void remove(Company s) {
    companies.remove(s);
    notifyListeners();
  }

  void edit(Company s) {
    int index = companies.indexOf(s);
    if (index != -1) {
      companies[index] = s;
      notifyListeners();
    }
  }
}
