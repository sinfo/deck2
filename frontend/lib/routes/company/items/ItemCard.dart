import 'package:flutter/material.dart';
import 'package:frontend/components/blurryDialog.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/routes/company/items/EditItemForm.dart';
import 'package:frontend/routes/company/items/ItemNotifier.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/itemService.dart';
import 'package:provider/provider.dart';

class ItemCard extends StatelessWidget {
  Item item;
  final bool small;
  ItemCard({Key? key, required this.item, required this.small})
      : super(key: key);

  void _editItemModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditItemForm(item: item),
            ));
      },
    );
  }

  void _deleteItemDialog(mainContext) {
    showDialog(
      context: mainContext,
      builder: (BuildContext secondaryContext) {
        return BlurryDialog(
            'Warning', 'Are you sure you want to delete item ${item.name}?',
            () {
          _deleteItem(mainContext);
        });
      },
    );
  }

  void _deleteItem(context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Deleting item...', style: TextStyle(color: Colors.white))),
    );

    EventService _eventService = EventService();
    Event? e = await _eventService.removeItemFromEvent(itemId: item.id);

    if (e != null) {
      EventNotifier eventNotifier =
          Provider.of<EventNotifier>(context, listen: false);

      eventNotifier.event = e;

      ItemService _itemService = ItemService();
      Item? i = await _itemService.deleteItem(item.id);
      if (i != null) {
        ItemsNotifier notifier =
            Provider.of<ItemsNotifier>(context, listen: false);
        notifier.remove(i);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: item not deleted from current event',
                style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: EdgeInsets.fromLTRB(17, 15, 17, 15),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Item Name: " + item.name,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: small ? 16 : 22,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            _editItemModal(context);
                          },
                          color: const Color(0xff5c7ff2),
                          icon: Icon(Icons.edit)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                          onPressed: () {
                            _deleteItemDialog(context);
                          },
                          color: Colors.red,
                          icon: Icon(Icons.delete)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 63, 81, 181),
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: EdgeInsets.all(small ? 4.0 : 8.0),
                        child: Text(
                          item.type,
                          style: TextStyle(
                              fontSize: small ? 12 : 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            Divider(
              color: Colors.grey[600],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.monetization_on, size: 48),
                    Text(
                      (item.price ~/ 100).toString() +
                          "," +
                          (item.price % 100).toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Price',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48),
                    Text(
                      item.vat.toString() + '%',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'VAT (IVA)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            Text("Item description: " + item.description,
                textAlign: TextAlign.left, style: TextStyle(fontSize: 18))
          ],
        ),
      ),
    );
  }
}
