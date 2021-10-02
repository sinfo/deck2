import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
            body: GridView.count(
              padding: EdgeInsets.all(10),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
              addAutomaticKeepAlives: true,
              children: membs.map((e) => MemberCard(member: e)).toList(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                //TODO: on tap
                // Add your onPressed code here!
              },
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddMemberForm()),
                  );
                }, 
                icon: Icon(Icons.add)),
              backgroundColor: Color.fromRGBO(92, 127, 242, 1),
            ),
          );
        } else {
          return CircularProgressIndicator();
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
          //FIXME: change 
          return CircularProgressIndicator();
        
        }
      });
}

// class MemberCard extends StatelessWidget {
//   final Member member;
//   final MemberService memberService = new MemberService();
//   MemberCard({Key? key, required this.member}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//         child: Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).cardColor,
//               borderRadius: BorderRadius.circular(5),
//             ),
//             child: Column(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(5),
//                       topRight: Radius.circular(5)),
//                   child: Image(
//                     image: (member.image == '')
//                         ? AssetImage("assets/noImage.png") as ImageProvider
//                         : NetworkImage(member.image),
//                     //image: NetworkImage(member.image),
//                   ),
//                 ),
//                 SizedBox(height: 12.5),
//                 Text(member.name!,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       //fontFamily: 'Inter',
//                       fontWeight: FontWeight.bold,
//                     )),
//                 Text(
//                   'Role',
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             )),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => MemberScreen(member: this.member)),
//           );
//         });
//   }
// }
