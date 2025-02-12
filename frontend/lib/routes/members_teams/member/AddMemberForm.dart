import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/members_teams/member/MemberScreen.dart';
import 'package:frontend/services/memberService.dart';

class AddMemberForm extends StatefulWidget {
  AddMemberForm({Key? key}) : super(key: key);

  @override
  _AddMemberFormState createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<AddMemberForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _istIdController = TextEditingController();
  final _sinfoIdController = TextEditingController();
  MemberService _memberService = new MemberService();
  CustomAppBar appBar = CustomAppBar(disableEventChange: true);

  //final _imagePicker = ImagePicker();
  //XFile? _image;
  //int? _size;
  //late DropzoneViewController _controller;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var istid = _istIdController.text;
      var sinfoid = _sinfoIdController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Uploading', style: TextStyle(color: Colors.white))),
      );

      Member? m = await _memberService.createMember(
          istid: istid, name: name, sinfoid: sinfoid);
      // if (m != null && _image != null) {
      //   m = kIsWeb
      //       ? await _memberService.updateInternalImageWeb(
      //           id: m.id, image: _image!)
      //       : await _memberService.updateInternalImage(
      //           id: m.id, image: File(_image!.path));
      // }
      if (m != null) {
        // Taking the AddMemberForm screen from navigator
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MemberScreen(member: m)),
        );

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

        Navigator.pop(context);
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
              decoration: InputDecoration(
                icon: const Icon(Icons.person),
                labelText: "Name *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _istIdController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ist id';
                }
                return null;
              },
              decoration: InputDecoration(
                icon: const Icon(Icons.school),
                labelText: "IstID *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _sinfoIdController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter sinfo id';
                } else {
                  return null;
                }
              },
              decoration: InputDecoration(
                icon: ImageIcon(
                  AssetImage("assets/PowerOnIcon.png"),
                  size: 15,
                ),
                labelText: "SinfoID *",
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("CANCEL",
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _submit(),
                  child: const Text('SUBMIT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /*Widget _buildPicture(double size) {
    Widget inkWellChild;

    if (_image == null) {
      inkWellChild = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: size / 3,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Click to upload or drag and drop image",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  )),
            ),
          ],
        ),
      );
    } else {
      inkWellChild = Center(
        child: kIsWeb
            ? Image.network(
                _image!.path,
                fit: BoxFit.fill,
              )
            : Image.file(
                File(_image!.path),
                fit: BoxFit.fill,
              ),
      );
    }

    Widget outerBox;

    if (kIsWeb) {
      outerBox = Padding(
        padding: const EdgeInsets.all(8.0),
        child: DottedBorder(
          child: SizedBox(
            width: size,
            height: size,
            child: InkWell(
              child: Stack(children: [
                DropzoneView(
                  operation: DragOperation.copy,
                  onCreated: (controller) => this._controller = controller,
                  cursor: CursorType.grab,
                  onDrop: _acceptFile,
                ),
                inkWellChild,
              ]),
              onTap: () {
                _pickImage();
              },
            ),
          ),
          strokeWidth: 1,
        ),
      );
    } else {
      outerBox = Padding(
        padding: const EdgeInsets.all(8.0),
        child: DottedBorder(
          child: SizedBox(
            width: size,
            height: size,
            child: InkWell(
              child: inkWellChild,
              onTap: () {
                _pickImage();
              },
            ),
          ),
          strokeWidth: 1,
        ),
      );
    }

    return outerBox;
  }

  _acceptFile(dynamic event) async {
    final name = event.name;
    final mime = await _controller.getFileMIME(event);
    final bytes = await _controller.getFileSize(event);
    final url = await _controller.createFileUrl(event);
    XFile f = XFile(url, mimeType: mime, length: bytes, name: name);
    setState(() {
      _size = bytes;
      _image = f;
    });
  }

  _pickImage() async {
    XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      int size = await image.length();
      setState(() {
        _size = size;
        _image = image;
      });
    }
  }*/

  @override
  Widget build(BuildContext context) {
    //bool warning = _image != null && _size != null && _size! > 102400;
    return Scaffold(
        body: Stack(children: [
      Container(
          margin: EdgeInsets.fromLTRB(0, appBar.preferredSize.height, 0, 0),
          child: LayoutBuilder(builder: (contex, constraints) {
            return Column(children: [
              _buildForm(),
            ]);
          })),
      appBar,
    ]));
    // }
    // builder: (context, constraints) {
    //   if (constraints.maxWidth < 1000) {
    //     return Column(
    //       children: [
    //         //_buildPicture(constraints.maxWidth / 3),
    //         _buildForm()
    //       ],
    //     );
    //   } else {
    //     return Column(
    //       children: [
    //         _buildPicture(constraints.maxWidth / 6),
    //         warning
    //             ? Text(
    //                 'Image selected is too big!',
    //                 style: TextStyle(
    //                   color: Colors.red,
    //                 ),
    //               )
    //             : Container(),
    //         _buildForm()
    //       ],
    //     );
    //   }
    // },
    // ));
  }
}
