import 'package:flutter/material.dart';
import 'package:frontend/components/SearchResultWidget.dart';
import 'package:frontend/models/meeting.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/meetingService.dart';
import 'package:frontend/services/memberService.dart';

class AddMeetingMemberForm extends StatefulWidget {
  final Meeting? meeting;
  final void Function(BuildContext, Meeting?)? onEditMeeting;

  AddMeetingMemberForm({Key? key, this.meeting, this.onEditMeeting})
      : super(key: key);

  @override
  _AddMeetingMemberForm createState() => _AddMeetingMemberForm();
}

class _AddMeetingMemberForm extends State<AddMeetingMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  MeetingService service = MeetingService();
  MemberService _memberService = MemberService();
  late Future<List<Member>> membs;
  TextEditingController _searchMembersController = TextEditingController();
  String type = '';
  String _memberID = '';
  String _memberName = '';
  bool disappearSearchResults = false;

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adding member...')),
      );
      Meeting? m = await service.addMeetingParticipant(
          id: widget.meeting!.id, memberID: _memberID, type: type);
      if (m != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onEditMeeting!(context, m);

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
        );

        Navigator.pop(context);
      }
    }
  }

  List<Widget> getResults(double height) {
    if (_searchMembersController.text.length > 1 && !disappearSearchResults) {
      return [
        Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: FutureBuilder(
                future: this.membs,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Member> membsMatched = snapshot.data as List<Member>;
                    print("membs matched:" + membsMatched.toString());
                    return searchResults(membsMatched, height);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                }))
      ];
    } else {
      return [];
    }
  }

  Widget searchResults(List<Member> members, double listHeight) {
    List<Widget> results = getListCards(members);
    return Container(
        constraints: BoxConstraints(maxHeight: listHeight),
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (BuildContext context, int index) {
              return results[index];
            }));
  }

  void _getMemberData(String id, String name) {
    _memberID = id;
    _memberName = name;
    _searchMembersController.text = name;
    disappearSearchResults = true;
    setState(() {});
  }

  List<Widget> getListCards(List<Member> members) {
    List<Widget> results = [];
    if (members.length != 0) {
      results.add(getDivider("Members"));
      results.addAll(members.map((e) => SearchResultWidget(
            member: e,
            getMemberData: _getMemberData,
          )));
    }
    return results;
  }

  Widget getDivider(String name) {
    return Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              child: Text(name, style: TextStyle(fontSize: 18)),
              margin: EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    List<String> types = ["Member", "Company Representative"];
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                    controller: _searchMembersController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a member';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                        icon: const Icon(Icons.groups), labelText: "Member *"),
                    onChanged: (newQuery) {
                      setState(() {});
                      if (_searchMembersController.text.length > 1) {
                        this.membs = _memberService.getMembers(
                            name: _searchMembersController.text);
                      }
                    })),
            ...getResults(MediaQuery.of(context).size.height * 0.3),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                icon: Icon(Icons.tag),
                items: types
                    .map((e) =>
                        DropdownMenuItem<String>(value: e, child: Text(e)))
                    .toList(),
                value: types[0],
                selectedItemBuilder: (BuildContext context) {
                  return types.map((e) {
                    return Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(child: Text(e)),
                    );
                  }).toList();
                },
                onChanged: (next) {
                  setState(() {
                    if (next == "Company Representative") {
                      type = "COMPANYREP";
                    } else if (next == "Member") {
                      type = "MEMBER";
                    }
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => _submit(context),
                child: const Text('Submit'),
              ),
            ),
          ],
        ));
  }
}
