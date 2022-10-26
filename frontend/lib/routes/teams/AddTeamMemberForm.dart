import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';

class AddTeamMemberForm extends StatefulWidget {
  AddTeamMemberForm({Key? key}) : super(key: key);

  @override
  _AddTeamMemberFormState createState() => _AddTeamMemberFormState();
}

class _AddTeamMemberFormState extends State<AddTeamMemberForm> {
  final _formKey = GlobalKey<FormState>();
  MemberService _memberService = new MemberService();
  final _searchMembersController = TextEditingController();
  late Future<List<Member>> membs;
  String memberRole = "";

  Widget _buildForm() {
    return Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(children: [
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
                      icon: const Icon(Icons.groups),
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
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: ElevatedButton(
            //     onPressed: () => _submit(),
            //     child: const Text('Submit'),
            //   ),
            // ),
          ]),
        ));
  }

  List<Widget> getResults(double height) {
    if (_searchMembersController.text.length > 1) {
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

  List<Widget> getListCards(List<Member> members) {
    List<Widget> results = [];
    if (members.length != 0) {
      results.add(getDivider("Members"));
      results.addAll(members.map((e) => SearchResultWidget(member: e)));
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
