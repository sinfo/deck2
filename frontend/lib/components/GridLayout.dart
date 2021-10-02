import 'package:flutter/cupertino.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';

class GridLayout extends StatelessWidget {
  final List<SpeakerLight>? speakers;
  final List<CompanyLight>? companies;
  final List<Member>? members;

  GridLayout({Key? key, this.speakers, this.companies, this.members})
      : super(key: key) {}

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double cardWidth = 250;
      bool isSmall = false;
      if (constraints.maxWidth < 1500) {
        cardWidth = 200;
        isSmall = true;
      }
      List<Widget> results = getGridCards(isSmall);
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width ~/ cardWidth,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: 0.75,
        ),
        itemCount: results.length,
        itemBuilder: (BuildContext context, int index) {
          return results[index];
        },
      );
    });
  }

  List<Widget> getGridCards(bool isSmall) {
    List<Widget> results = [];
    if (speakers != null) {
      results.addAll(speakers!.map((e) => ListViewCard(
          small: isSmall, speakerLight: e, participationsInfo: true)));
    }
    if (companies != null) {
      results.addAll(companies!.map((e) => ListViewCard(
          small: isSmall, companyLight: e, participationsInfo: true)));
    }
    if (members != null) {
      results
          .addAll(members!.map((e) => ListViewCard(small: isSmall, member: e)));
    }
    return results;
  }
}
