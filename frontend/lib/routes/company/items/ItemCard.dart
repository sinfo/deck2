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

class ItemCard extends StatefulWidget {
  Item item;
  final bool small;
  ItemCard({Key? key, required this.item, required this.small})
      : super(key: key);

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> itemChangedCallback(BuildContext context, {Item? item}) async {
    setState(() {
      widget.item = item!;
    });
  }

  void _editItemModal(context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
            heightFactor: 0.7,
            child: Container(
              child: EditItemForm(
                  item: widget.item,
                  onItemEdit: (context, _item) {
                    itemChangedCallback(context, item: _item);
                  }),
            ));
      },
    );
  }

  void _deleteItemDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlurryDialog('Warning',
            'Are you sure you want to delete item ${widget.item.name}?', () {
          _deleteItem(context);
        });
      },
    );
  }

  void _deleteItem(context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting item...')),
    );

    EventService _eventService = EventService();
    Event? e = await _eventService.removeItemFromEvent(itemId: widget.item.id);

    if (e != null) {
      EventNotifier eventNotifier =
          Provider.of<EventNotifier>(context, listen: false);

      eventNotifier.event = e;

      ItemService _itemService = ItemService();
      Item? i = await _itemService.deleteItem(widget.item.id);
      if (i != null) {
        ItemsNotifier notifier =
            Provider.of<ItemsNotifier>(context, listen: false);
        notifier.remove(i);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: item not deleted from current event')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                Text("Item Name: " + widget.item.name,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: widget.small ? 16 : 22,
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
                        padding: EdgeInsets.all(widget.small ? 4.0 : 8.0),
                        child: Text(
                          widget.item.type,
                          style: TextStyle(
                              fontSize: widget.small ? 12 : 16,
                              color: Colors.white),
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
                    Icon(Icons.receipt_long, size: 48),
                    Text(
                      widget.item.vat.toString() + '%',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'VAT (IVA)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.monetization_on, size: 48),
                    Text(
                      (widget.item.price ~/ 100).toString() +
                          "," +
                          (widget.item.price % 100).toString(),
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Price',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            Text("Item description: " + widget.item.description,
                textAlign: TextAlign.left, style: TextStyle(fontSize: 18))
          ],
        ),
      ),
    );
  }
}
