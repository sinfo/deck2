import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/ListViewCard2.dart';
import 'package:frontend/components/memberSearchDelegate.dart';
import 'package:frontend/components/router.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/memberService.dart';
import 'package:frontend/routes/member/MemberScreen.dart';

class MemberListWidget2 extends StatefulWidget {
  const MemberListWidget2({Key? key}) : super(key: key);

  @override
  _MemberListWidgetState createState() => _MemberListWidgetState();
}

class _MemberListWidgetState extends State<MemberListWidget2> {
  MemberService memberService = new MemberService();
  late Future<List<Member>> members;

  @override
  void initState() {
    super.initState();
    this.members = memberService.getMembers(event: App.localStorage.getInt("event"));
  }

  Widget memberGrid(){
    return FutureBuilder<List<Member>>(
      future: members,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Member> membs = snapshot.data as List<Member>;
          return LayoutBuilder(builder: (context, constraints) {
            double cardWidth = 250;
            bool isSmall = false;
            if (constraints.maxWidth < 1500) {
              cardWidth = 200;
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
                    return ListViewCard2(
                        small: isSmall,
                        member: membs[index],);
                  });

        });
      } else {
            return Center(child: CircularProgressIndicator());
      }
      });
}

  @override
  Widget build(BuildContext context){
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
      body: memberGrid(),
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

  }
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