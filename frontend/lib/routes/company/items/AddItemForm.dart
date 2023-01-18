import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/routes/company/items/ItemNotifier.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/itemService.dart';
import 'package:provider/provider.dart';

class AddItemForm extends StatefulWidget {
  AddItemForm({Key? key}) : super(key: key);

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _valueEurosController = TextEditingController();
  final _valueCentsController = TextEditingController();
  final _vatController = TextEditingController();
  ItemService _itemService = ItemService();
  EventService _eventService = EventService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var description = _descriptionController.text;
      var type = _typeController.text;
      var price = int.parse(_valueEurosController.text) * 100 +
          int.parse(_valueCentsController.text);
      var vat = int.parse(_vatController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Creating Item...',
                style: TextStyle(color: Colors.white))),
      );

      Item? i =
          await _itemService.createItem(name, type, description, price, vat);

      if (i != null) {
        ItemsNotifier notifier =
            Provider.of<ItemsNotifier>(context, listen: false);
        notifier.add(i);

        Event? e = await _eventService.addItemToEvent(itemId: i.id);

        if (e == null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: item not added to current event.',
                    style: TextStyle(color: Colors.white))),
          );
        } else {
          EventNotifier eventNotifier =
              Provider.of<EventNotifier>(context, listen: false);

          eventNotifier.event = e;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Done', style: TextStyle(color: Colors.white)),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );
      }
      Navigator.pop(context);
    }
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Name *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _descriptionController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Description *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _typeController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a type';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText:
                    "Type * (e.g Publicity, Merchandise, Stands, Talk or other)",
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _valueEurosController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost of the item';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of item (only euros) *",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _valueCentsController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost of the item';
                      }
                      int val = int.parse(value);
                      if (val < 0 || val > 100) {
                        return 'Cents must be a number between 0 and 100';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of item (only cents) *",
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _vatController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the VAT (IVA) of the item';
                }
                int val = int.parse(value);
                if (val < 0 || val > 100) {
                  return 'VAT must be a number between 0 and 100';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.money),
                labelText: "Item VAT (IVA) *",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _submit(),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    CustomAppBar appBar = CustomAppBar(
      disableEventChange: true,
    );
    return Scaffold(
      body: Stack(children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
            child: _buildForm()),
        appBar,
      ]),
    );
  }
}
