import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/routes/items_packages/items/ItemNotifier.dart';
import 'package:frontend/services/itemService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditItemForm extends StatefulWidget {
  final Item item;
  EditItemForm({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemFormState createState() => _EditItemFormState();
}

class _EditItemFormState extends State<EditItemForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  late TextEditingController _vatController;

  ItemService _itemService = ItemService();

  @override
  void initState() {
    super.initState();
    NumberFormat formatter = new NumberFormat("00");
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController =
        TextEditingController(text: widget.item.description);
    _typeController = TextEditingController(text: widget.item.type);
    _costController = TextEditingController(
        text: (widget.item.price ~/ 100).toString() + "." +
            formatter.format(widget.item.price % 100));
    _vatController = TextEditingController(text: widget.item.vat.toString());
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var description = _descriptionController.text;
      var type = _typeController.text;
      var parseCost = double.parse(_costController.text);
      var euros = parseCost.toInt();
      var cents = ((parseCost - euros) * 100).round();
      int cost = euros * 100 + cents;
      var vat = int.parse(_vatController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updating item...',
                style: TextStyle(color: Colors.white))),
      );

      Item? i = await _itemService.updateItem(
          widget.item.id, name, type, description, cost, vat);

      if (i != null) {
        ItemsNotifier notifier =
            Provider.of<ItemsNotifier>(context, listen: false);
        notifier.edit(i);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Done', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('An error occured.',
                  style: TextStyle(color: Colors.white))),
        );
      }
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _costController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the cost of the item';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.money),
                labelText: "Cost of item *",
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
            ),
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
    return _buildForm();
  }
}
