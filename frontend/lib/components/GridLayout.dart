import 'package:flutter/cupertino.dart';
import 'package:frontend/components/ListViewCard2.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/models/speaker.dart';

class GridLayout extends StatelessWidget {
  final List<SpeakerLight>? speakers;
  final List<CompanyLight>? companies;
  final List<Member>? members;

  GridLayout({Key? key, this.speakers, this.companies, this.members})
      : super(key: key) {}

  int getNumberOfItems() {
    if (speakers != null) {
      return speakers!.length;
    } else if (companies != null) {
      return companies!.length;
    } else {
      return members!.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double cardWidth = 250;
      bool isSmall = false;
      if (constraints.maxWidth < 1500) {
        cardWidth = 200;
        isSmall = true;
      }
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width ~/ cardWidth,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: 0.75,
        ),
        itemCount: getNumberOfItems(),
        itemBuilder: (BuildContext context, int index) {
          if (speakers != null) {
            return ListViewCard2(
                small: isSmall,
                speakerLight: speakers![index],
                participationsInfo: true);
          } else if (companies != null) {
            return ListViewCard2(
                small: isSmall,
                companyLight: companies![index],
                participationsInfo: true);
          } else {
            return ListViewCard2(
              small: isSmall,
              member: members![index],
            );
          }
        },
      );
    });
  }
}
