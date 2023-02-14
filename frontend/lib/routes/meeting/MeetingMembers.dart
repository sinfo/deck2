import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/meeting/MeetingsNotifier.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:provider/provider.dart';

class MeetingMembers extends StatelessWidget {
  Meeting meeting;
  final bool small;
  final void Function(BuildContext, Meeting?)? onEditMeeting;

  MeetingMembers(
      {Key? key,
      required this.meeting,
      required this.small,
      required this.onEditMeeting})
      : super(key: key);

  double cardWidth = 200;
  MemberService _memberService = MemberService();
  MeetingService _meetingService = MeetingService();
  ScrollController _controller = ScrollController();

  void _deleteMeetingMember(context, id, type, name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete ${name} from meeting ${meeting.title}?',
            () async {
          Meeting? m = await _meetingService.deleteMeetingMember(
              id: meeting.id, memberID: id, type: type);
          if (m != null) {
            MeetingsNotifier notifier =
                Provider.of<MeetingsNotifier>(context, listen: false);
            notifier.edit(m);

            onEditMeeting!(context, m);

            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Done', style: TextStyle(color: Colors.white)),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('An error occured.',
                      style: TextStyle(color: Colors.white))),
            );
          }
        });
      },
    );
  }

  Widget MeetingMembersGrid(List<Future<Member?>> _members, String type) {
    if (_members != []) {
      return FutureBuilder(
          future: Future.wait(_members),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Member?> membs = snapshot.data as List<Member?>;
              membs.sort((a, b) => a!.name.compareTo(b!.name));

              cardWidth = small ? 125 : 200;

              return GridView.builder(
                  controller: _controller,
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width ~/ cardWidth,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: membs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(children: [
                      ListViewCard(small: small, member: membs[index]),
                      ElevatedButton.icon(
                          onPressed: () => _deleteMeetingMember(context,
                              membs[index]!.id, type, membs[index]!.name),
                          icon: Icon(Icons.delete),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          label: const Text("Delete member")),
                    ]);
                  });
            } else {
              return Center(child: CircularProgressIndicator());
            }
          });
    } else {
      return Text("Meeting without this kind of members");
    }
  }

  Widget Separator(_text) {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          child: Text(_text, style: TextStyle(fontSize: small ? 14 : 18)),
          margin: EdgeInsets.fromLTRB(0, 8, 8, 0),
        ),
        Divider(thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Future<Member?>> _futureMembers = [];
    if (meeting.participants.membersIds != []) {
      _futureMembers = meeting.participants.membersIds!
          .map((memberID) => _memberService.getMember(memberID))
          .toList();
    }

    List<Future<Member?>> _futureCompanyReps = [];
    if (meeting.participants.companyRepIds != []) {
      _futureCompanyReps = meeting.participants.companyRepIds!
          .map((memberID) => _memberService.getMember(memberID))
          .toList();
    }

    return SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
                child: Column(children: [
              Separator("Members"),
              Container(
                  child: Center(
                      child: MeetingMembersGrid(_futureMembers, "MEMBER"))),
              Separator("Company Reps"),
              Container(
                  child: Center(
                      child: MeetingMembersGrid(
                          _futureCompanyReps, "COMPANYREP"))),
            ]))));
  }
}
