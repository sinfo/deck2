import 'package:flutter/cupertino.dart';
import 'package:frontend/components/status.dart';
import 'package:frontend/models/participation.dart';
import 'package:frontend/models/speaker.dart';

class SpeakerTableNotifier extends ChangeNotifier {
  List<Speaker> speakers;

  SpeakerTableNotifier({required this.speakers});

  List<Speaker> getByMember(String id, int event, ParticipationStatus status) {
    var s = speakers
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

  void add(Speaker s) {
    speakers.add(s);
    notifyListeners();
  }

  void remove(Speaker s) {
    speakers.remove(s);
    notifyListeners();
  }

  void edit(Speaker s) {
    int index = speakers.indexOf(s);
    if (index != -1) {
      speakers[index] = s;
      notifyListeners();
    }
  }
}