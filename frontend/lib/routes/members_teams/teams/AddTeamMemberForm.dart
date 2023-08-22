import 'package:flutter/material.dart';
import 'package:frontend/components/SearchResultWidget.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/teamService.dart';
import 'package:frontend/services/memberService.dart';

final Map<String, String> roles = {
  "MEMBER": "Member",
  "TEAMLEADER": "Team Leader"
};

class AddTeamMemberForm extends StatefulWidget {
  final Team? team;
  final void Function(BuildContext, Team?)? onEditTeam;
  final Role? role2;

  AddTeamMemberForm({Key? key, this.role2, this.team, this.onEditTeam})
      : super(key: key);

  @override
  _AddTeamMemberFormState createState() => _AddTeamMemberFormState();
}

class _AddTeamMemberFormState extends State<AddTeamMemberForm> {
  final _formKey = GlobalKey<FormState>();
  MemberService _memberService = new MemberService();
  final _searchMembersController = TextEditingController();
  TeamService service = TeamService();
  late Future<List<Member>> membs;
  String memberRole = "";
  String _memberID = '';
  bool disappearSearchResults = false;
  String role = "";

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adding member...',
                style: TextStyle(color: Colors.white))),
      );
      Team? t = await service.addTeamMember(
          id: widget.team!.id, memberId: _memberID, role: role);
      if (t != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        widget.onEditTeam!(context, t);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );

        Navigator.pop(context);
      }
    }
  }

  Widget _buildForm() {
    var r = widget.role2;
    debugPrint('Role in add team member form: $r');
    if (widget.role2 == Role.ADMIN) {
      roles['COORDINATOR'] = 'Coordinator';
      debugPrint('In if');
    }
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
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
                      icon: const Icon(Icons.person_add),
                      labelText: "Member *",
                    ),
                    onChanged: (newQuery) {
                      setState(() {});
                      if (_searchMembersController.text.length > 1) {
                        this.membs = _memberService.getMembers(
                            name: _searchMembersController.text);
                      }
                    })),
            ...getResults(MediaQuery.of(context).size.height * 0.7),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField(
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.grid_3x3),
                    labelText: "Role *",
                  ),
                  items: roles.keys.map((e) {
                    return new DropdownMenuItem(
                        value: e, child: Text(roles[e]!));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => role = newValue.toString());
                  }),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _submit(context),
                child: const Text('SUBMIT'),
              ),
            ),
          ],
        ),
      ),
    );
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
    widget.team!.members!.map((memberteam) {
      if (id == memberteam.memberID) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Member already exist"),
              content: Text("Can't add again"),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
        return;
      }
    }).toList();

    _memberID = id;
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
    return _buildForm();
  }
}
