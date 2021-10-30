import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/services/teamService.dart';

import '../../main.dart';

class EditMembers extends StatefulWidget {
  final String teamId;
  final List<Member?> previousMembers;
  const EditMembers(
      {Key? key, required this.teamId, required this.previousMembers})
      : super(key: key);

  @override
  _EditMembersState createState() => _EditMembersState();
}

class _EditMembersState extends State<EditMembers> {
  MemberService memberService = new MemberService();
  TeamService teamService = new TeamService();
  late Future<List<Member>> members;
  static var selectedMembers = List<Member>.empty(growable: true);
  static var removedMembers = List<Member>.empty(growable: true);

  @override
  void initState() {
    super.initState();
    this.members =
        memberService.getMembers(event: App.localStorage.getInt("event"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          disableEventChange: false,
        ),
        body: FutureBuilder<List<Member>>(
            future: members,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<Member> membs = snapshot.data as List<Member>;
                membs.sort((a, b) => a.name.compareTo(b.name));

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: membs.map((m) {
                          final isSelected = selectedMembers.contains(m) ||
                              (widget.previousMembers.contains(m) &&
                                  !removedMembers.contains(m));

                          return MemberListTile(
                            member: m,
                            isSelected: isSelected,
                            onSelectedMember: selectMember,
                          );
                        }).toList(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text("CANCEL",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).accentColor)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).accentColor,
                              padding: EdgeInsets.symmetric(horizontal: 50),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () => _submit(),
                            child: const Text('SUBMIT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }));
  }

  _submit() async {
    // Add selected members to the team

    await teamService.addTeamMember(
        widget.teamId, selectedMembers[0].id, 'MEMBER');

    print('added');

    selectedMembers.map((m) async {
      await teamService.addTeamMember(widget.teamId, m.id, 'MEMBER');
      print("added member:" + m.name);
    });

    // Removed unselected members to the team
    removedMembers.map((m) async {
      await teamService.deleteTeamMember(widget.teamId, m.id);
      print("deleted member:" + m.name);
    });

    print(selectedMembers);

    Navigator.pop(context);
  }

  removeMember(Member member) {
    selectedMembers.remove(member);
    if (widget.previousMembers.contains(member)) {
      removedMembers.add(member);
    }
  }

  // addMember(Member member) async {
  //   selectedMembers.add(member);
  //   await teamService.addTeamMember(widget.team.id!, member.id, 'MEMBER');
  // }

  void selectMember(Member member) {
    final isSelected = selectedMembers.contains(member);
    setState(
        () => isSelected ? removeMember(member) : selectedMembers.add(member));
  }
}

class MemberListTile extends StatelessWidget {
  final Member member;
  final bool isSelected;
  final ValueChanged<Member> onSelectedMember;

  const MemberListTile(
      {Key? key,
      required this.member,
      required this.isSelected,
      required this.onSelectedMember})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = isSelected
        ? TextStyle(
            fontSize: 18,
            color: Theme.of(context).accentColor,
            fontWeight: FontWeight.bold)
        : TextStyle(fontSize: 18);

    return ListTile(
      onTap: () => onSelectedMember(member),
      leading: (member.image != '')
          ? Image.network(member.image!)
          : Image.asset('assets/noImage.png'),
      title: Text(member.name, style: style),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).accentColor, size: 26)
          : null,
    );
  }
}
