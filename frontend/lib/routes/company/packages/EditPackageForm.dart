import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/routes/company/items/ItemNotifier.dart';
import 'package:frontend/routes/company/packages/PackageNotifier.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:provider/provider.dart';

class EditPackageForm extends StatefulWidget {
  final EventPackage eventPackage;
  final Package package;
  EditPackageForm({Key? key, required this.eventPackage, required this.package})
      : super(key: key);

  @override
  _EditPackageFormState createState() => _EditPackageFormState();
}

class _EditPackageFormState extends State<EditPackageForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _publicNameController;
  late bool _available;
  late TextEditingController _packageNameController;
  late TextEditingController _valueEurosController;
  late TextEditingController _valueCentsController;
  late TextEditingController _vatController;

  PackageService _packageService = PackageService();
  EventService _eventService = EventService();

  List<Item> _items = [];
  Map<String, bool> _itemPublic = new Map();

  @override
  void initState() {
    super.initState();
    _publicNameController =
        TextEditingController(text: widget.eventPackage.publicName);
    _available = widget.eventPackage.available;
    _packageNameController = TextEditingController(text: widget.package.name);
    _valueEurosController =
        TextEditingController(text: (widget.package.price ~/ 100).toString());
    _valueCentsController =
        TextEditingController(text: (widget.package.price % 100).toString());
    _vatController = TextEditingController(text: widget.package.vat.toString());
  }

  Widget quantityField(
      TextEditingController _controller, Item i, StateSetter setState) {
    return Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              icon: const Icon(Icons.tag),
              labelText: "Quantity of item ${i.name} (optional) *",
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
          ),
          CheckboxListTile(
            value: _itemPublic[i.id],
            onChanged: (bool? val) {
              setState(() {
                if (val == null) {
                  _itemPublic[i.id] = false;
                } else {
                  _itemPublic[i.id] = val;
                }
              });
            },
            title: new Text('${i.name} visible'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
        ]));
  }

  Future<List<PackageItem>?> createPackageItemList() async {
    if (_items.length == 0) {
      return null;
    }

    bool _formEdit = false;
    List<PackageItem> packageItems = [];

    // Has Item ID as key
    Map<String, TextEditingController> _controllers = new Map();

    for (Item i in _items) {
      _controllers[i.id] = TextEditingController();
      _itemPublic[i.id] = false;
    }

    await showDialog(
      context: context,
      builder: (BuildContext mainContext) => AlertDialog(
        title: const Text("Edit quantities and visibility of items in package"),
        content: StatefulBuilder(
            builder: (BuildContext secondaryContext, StateSetter setState) {
          return Column(
              mainAxisSize: MainAxisSize.min,
              children: _items
                  .map((i) => quantityField(_controllers[i.id]!, i, setState))
                  .toList());
        }),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(mainContext);
              _formEdit = true;
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              for (Item i in _items) {
                int? quant = _controllers[i.id]!.text == ""
                    ? null
                    : int.parse(_controllers[i.id]!.text);
                PackageItem pi = new PackageItem(
                    itemID: i.id, quantity: quant, public: _itemPublic[i.id]);
                packageItems.add(pi);
              }
              Navigator.pop(mainContext);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (_formEdit) {
      return null;
    } else {
      return packageItems;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var publicName = _publicNameController.text;
      var packageName = _packageNameController.text;
      var price = int.parse(_valueEurosController.text) * 100 +
          int.parse(_valueCentsController.text);
      var vat = int.parse(_vatController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Updating package...',
                style: TextStyle(color: Colors.white))),
      );

      List<PackageItem>? itemsPack = await createPackageItemList();
      if (itemsPack == null) {
        itemsPack = [];
      }

      Package? pi = await _packageService.updatePackageItems(
          widget.package.id, itemsPack);

      if (pi != null) {
        PackageNotifier notifier =
            Provider.of<PackageNotifier>(context, listen: false);
        notifier.edit(pi);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: package items not edited in package.',
                  style: TextStyle(color: Colors.white))),
        );
        return;
      }

      Package? p = await _packageService.updatePackage(
          widget.package.id, packageName, price, vat);

      if (p != null) {
        PackageNotifier notifier =
            Provider.of<PackageNotifier>(context, listen: false);
        notifier.edit(p);

        Event? e = await _eventService.updatePackageInEvent(
            publicName: publicName, template: p.id, available: _available);

        if (e == null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: package not edited in current event.',
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

  List<Item> getItems() {
    ItemsNotifier notifier = Provider.of<ItemsNotifier>(context);
    return notifier.getItems();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _packageNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Package private name *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _publicNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.title),
                labelText: "Package Public Name *",
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
                        return 'Please enter the cost of the package';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of package (only euros) *",
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
                        return 'Please enter the cost of the package';
                      }
                      int val = int.parse(value);
                      if (val < 0 || val > 100) {
                        return 'Cents must be a number between 0 and 100';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      icon: const Icon(Icons.money),
                      labelText: "Cost of package (only cents) *",
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
                  return 'Please enter the VAT (IVA) of the package';
                }
                int val = int.parse(value);
                if (val < 0 || val > 100) {
                  return 'VAT must be a number between 0 and 100';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.money),
                labelText: "Package VAT (IVA) *",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ),
          CheckboxListTile(
            value: _available,
            onChanged: (val) {
              setState(() {
                this._available = !this._available;
              });
            },
            title: new Text('Event package available.'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          ),
          DropdownSearch<Item>.multiSelection(
            items: getItems(),
            itemAsString: (Item i) => i.name,
            popupProps: PopupPropsMultiSelection.menu(
              showSearchBox: true,
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: const InputDecoration(
                icon: const Icon(Icons.shopping_cart),
                labelText: "Items (select all items again) *",
              ),
            ),
            onChanged: (List<Item> items) {
              _items = items;
            },
            clearButtonProps: ClearButtonProps(isVisible: true),
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
