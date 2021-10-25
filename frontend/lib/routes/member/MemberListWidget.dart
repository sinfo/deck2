import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/memberSearchDelegate.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:provider/provider.dart';

class MemberListWidget extends StatefulWidget {
  const MemberListWidget({Key? key}) : super(key: key);

  @override
  _MemberListWidgetState createState() => _MemberListWidgetState();
}

class _MemberListWidgetState extends State<MemberListWidget> {
  MemberService memberService = new MemberService();
  late Future<List<Member>> members;

  @override
  void initState() {
    super.initState();
    this.members =
        memberService.getMembers(event: App.localStorage.getInt("event"));
  }

  Widget memberGrid() {
    return FutureBuilder<List<Member>>(
        future: members,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Member> membs = snapshot.data as List<Member>;
            membs.sort((a, b) => a.name.compareTo(b.name));

            return LayoutBuilder(builder: (context, constraints) {
              double cardWidth = 200;
              bool isSmall = false;
              if (constraints.maxWidth < App.SIZE) {
                cardWidth = 125;
                isSmall = true;
              }
              return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width ~/ cardWidth,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: membs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListViewCard(
                      small: isSmall,
                      member: membs[index],
                    );
                  });
            });
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }

  _isEditable() {
    return FutureBuilder(
        future: Provider.of<AuthService>(context).role,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Role r = snapshot.data as Role;

            if (r == Role.ADMIN || r == Role.COORDINATOR){
              return FloatingActionButton.extended(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.AddMember,
                  );
                },
                label: const Text('Add New Member'),
                icon: const Icon(Icons.edit),
                backgroundColor: Color(0xff5C7FF2),
              );
            } else
              return Container();
          } else
            return Container();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(disableEventChange: true, actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search member',
          onPressed: () {
            showSearch(context: context, delegate: MemberSearchDelegate());
          },
        ),
      ]),
      body: memberGrid(),
      floatingActionButton: _isEditable(),
    );
  }
}
