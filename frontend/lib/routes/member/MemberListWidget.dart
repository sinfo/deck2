import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/memberSearchDelegate.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/components/speakerSearchDelegate.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/routes/member/MemberScreen.dart';
import 'package:frontend/routes/member/AddMemberForm.dart';

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
    //FIXME: int do event
    this.members = memberService.getMembers(event: 29);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: members,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Member> membs = snapshot.data as List<Member>;

          return Scaffold(
            appBar: AppBar(
              title: GestureDetector(
                  child: Image.asset(
                'assets/logo-branco2.png',
                height: 100,
                width: 100,
              )),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search member',
                  onPressed: () {
                    showSearch(context: context, delegate: MemberSearchDelegate());
                  },
                ),
                
              ]),
            body: GridView.count(
              padding: EdgeInsets.all(10),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
              addAutomaticKeepAlives: true,
              children: membs.map((e) => MemberCard(member: e)).toList(),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.AddMember,
                );
              },
              label: const Text('Create New Member'),
              icon: const Icon(Icons.person_add),
              backgroundColor: Color(0xff5C7FF2),
            ),
          );
        } else {
          return Container(
                child: Center(
                  child: Container(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
        }
      });
}

class MemberCard extends StatefulWidget {
  final Member member;
  const MemberCard({Key? key, required this.member}) : super(key: key);

  @override
  _MemberCardState createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> with AutomaticKeepAliveClientMixin{
  MemberService memberService = new MemberService();
  late Future<String?> role;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    this.role = memberService.getMemberRole(widget.member.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: role,
      builder: (context, snapshot) {
        print(snapshot.hasData);
        if (snapshot.hasData) {
          String rol = snapshot.data as String;

          return InkWell(
              child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5)),
                        child: Image(
                          image: (widget.member.image == '')
                              ? AssetImage("assets/noImage.png")
                                  as ImageProvider
                              : NetworkImage(widget.member.image!),
                          //image: NetworkImage(member.image),
                        ),
                      ),
                      SizedBox(height: 12.5),
                      Text(widget.member.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            //fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          )),
                      Text(
                        rol.toLowerCase(),
                        textAlign: TextAlign.center,
                        
                      ),
                    ],
                  )),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MemberScreen(member: widget.member, role: rol)),
                );
              });
        } else {
          return Container(
                child: Center(
                  child: Container(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
        
        }
      });
}