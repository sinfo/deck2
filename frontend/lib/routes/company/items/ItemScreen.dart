import 'package:flutter/material.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/routes/company/items/ItemCard.dart';
import 'package:frontend/routes/company/items/ItemNotifier.dart';
import 'package:provider/provider.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({Key? key}) : super(key: key);

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Event ev = Provider.of<EventNotifier>(context).event;
    return FutureBuilder(
      future: ev.items,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          ItemsNotifier notifier = Provider.of<ItemsNotifier>(context);

          notifier.items = snapshot.data as List<Item>;

          if (notifier.items.isEmpty) {
            return Container(child: Center(child: Text("0 items found")));
          }

          return Consumer<ItemsNotifier>(builder: (context, cart, child) {
            return LayoutBuilder(builder: (context, constraints) {
              bool small = constraints.maxWidth < App.SIZE;
              return ListView(
                children: notifier
                    .getItems()
                    .map((e) => ItemCard(item: e, small: small))
                    .toList(),
              );
            });
          });
        } else {
          return Container(child: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}
