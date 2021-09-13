import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/components/ListViewCard.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/company.dart';
import 'package:frontend/models/speaker.dart';

class GridLayout extends StatelessWidget {
  final List<SpeakerLight>? speakers;
  final List<CompanyLight>? companies;

  GridLayout({Key? key, this.speakers, this.companies}) : super(key: key) {}

  int getNumberOfItems() {
    if (speakers != null) {
      return speakers!.length;
    } else {
      return companies!.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double cardWidth = 250;
      bool isSmall = false;
      if (constraints.maxWidth < App.SIZE) {
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
            return ListViewCard(
                small: isSmall,
                speakerLight: speakers![index],
                participationsInfo: true);
          } else {
            return ListViewCard(
                small: isSmall,
                companyLight: companies![index],
                participationsInfo: true);
          }
        },
      );
    });
  }
}
