import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';

import '../../main.dart';

class EditMembers extends StatefulWidget {
  const EditMembers({Key? key}) : super(key: key);

  @override
  _EditMembersState createState() => _EditMembersState();
}

class _EditMembersState extends State<EditMembers> {
  MemberService memberService = new MemberService();
  late Future<List<Member>> members;
  static var selectedMembers = List<Member>.empty(growable: true);

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

                return ListView(
                  children: membs.map((m) {
                     final isSelected =_EditMembersState.selectedMembers.contains(m);

                    return MemberListTile(
                      member: m,
                      isSelected: isSelected,
                      onSelectedMember: selectMember,
                    );
                  }).toList(),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }));
  }

  void selectMember(Member member){
    final isSelected = selectedMembers.contains(member);
      setState(() => isSelected
          ? selectedMembers.remove(member)
          : selectedMembers.add(member));
    
  }
}

class MemberListTile extends StatelessWidget {
  final Member member;
  final bool isSelected;
  final ValueChanged<Member> onSelectedMember;

  const MemberListTile({Key? key, required  this.member, required this.isSelected, required this.onSelectedMember}) : super(key: key);

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
      leading: (member.image != '') ? Image.network(member.image!) : Image.asset('assets/noImage.png') ,
      title: Text(member.name, style: style),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).accentColor, size: 26)
          : null,
    );
  }
}
