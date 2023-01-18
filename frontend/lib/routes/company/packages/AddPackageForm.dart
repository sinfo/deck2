import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/eventNotifier.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/item.dart';
import 'package:frontend/models/package.dart';
import 'package:frontend/routes/company/items/ItemNotifier.dart';
import 'package:frontend/routes/company/packages/PackageNotifier.dart';
import 'package:frontend/services/eventService.dart';
import 'package:frontend/services/packageService.dart';
import 'package:provider/provider.dart';

class AddPackageForm extends StatefulWidget {
  AddPackageForm({Key? key}) : super(key: key);

  @override
  _AddPackageFormState createState() => _AddPackageFormState();
}

class _AddPackageFormState extends State<AddPackageForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueEurosController = TextEditingController();
  final _valueCentsController = TextEditingController();
  final _vatController = TextEditingController();
  final _publicNameController = TextEditingController();

  PackageService _packageService = PackageService();
  EventService _eventService = EventService();

  List<Item> _items = [];

  List<PackageItem> createPackageItemList() {
    List<PackageItem> packageItems = [];
    for (Item i in _items) {
      PackageItem pi = new PackageItem(itemID: i.id, quantity: 0, public: true);
      packageItems.add(pi);
    }
    return packageItems;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var price = int.parse(_valueEurosController.text) * 100 +
          int.parse(_valueCentsController.text);
      var vat = int.parse(_vatController.text);
      var publicName = _publicNameController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Creating Package...',
                style: TextStyle(color: Colors.white))),
      );

      List<PackageItem> itemsPack = createPackageItemList();

      Package? p = await _packageService.createPackage(
          name: name, price: price, vat: vat, items: itemsPack);

      if (p != null) {
        PackageNotifier notifier =
            Provider.of<PackageNotifier>(context, listen: false);
        notifier.add(p);

        Event? e = await _eventService.addPackageToEvent(
            publicName: publicName, template: p.id);

        if (e == null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: package not added to current event.',
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
              controller: _nameController,
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
          DropdownSearch<Item>.multiSelection(
            items: getItems(),
            itemAsString: (Item i) => i.name,
            popupProps: PopupPropsMultiSelection.menu(
              showSearchBox: true,
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: const InputDecoration(
                icon: const Icon(Icons.shopping_cart),
                labelText: "Items (optional) *",
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
