import 'dart:io';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/services/authService.dart';
import 'package:frontend/services/memberService.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditMemberForm extends StatefulWidget {
  final Member member;
  final void Function(BuildContext, Member?) onEdit;
  EditMemberForm({Key? key, required this.member, required this.onEdit})
      : super(key: key);

  @override
  _EditMemberFormState createState() => _EditMemberFormState();
}

class _EditMemberFormState extends State<EditMemberForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _istIdController;
  final _memberService = MemberService();
  final _imagePicker = ImagePicker();
  XFile? _image;
  int? _size;
  String? _prevImage;
  late DropzoneViewController _controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _istIdController = TextEditingController(text: widget.member.istId);
    _prevImage = widget.member.image;
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      var name = _nameController.text;
      var istId = _istIdController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        //FIXME try to use themes to avoid using style property
        const SnackBar(
            content: Text('Uploading', style: TextStyle(color: Colors.white))),
      );

      Member me = Provider.of<Member?>(context, listen: false)!;
      Member? m;
      var role = await Provider.of<AuthService>(context, listen: false).role;

      if (role == Role.ADMIN || role == Role.COORDINATOR || role == Role.TEAMLEADER) {
        m = await _memberService.updateMember(
            id: widget.member.id, name: name, istid: istId);
      } else {
        m = widget.member;
      }

      if (m != null && _image != null) {
        if (me.id == m.id) {
          m = kIsWeb
              ? await _memberService.updateMyImageWeb(image: _image!)
              : await _memberService.updateMyImage(image: File(_image!.path));
        } else {
          m = kIsWeb
              ? await _memberService.updateImageWeb(id: m.id, image: _image!)
              : await _memberService.updateImage(
                  id: m.id, image: File(_image!.path));
        }
      }
      if (m != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        widget.onEdit(context, m);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
            'An error occured.',
            style: TextStyle(color: Colors.white),
          )),
        );
      }
    }
  }

  Widget _buildForm() {
    return FutureBuilder(
      future: Provider.of<AuthService>(context).role,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Role role = snapshot.data as Role;
          var adminOrCoordOrTeamLeader = role == Role.ADMIN || role == Role.COORDINATOR || role == Role.TEAMLEADER;
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: !adminOrCoordOrTeamLeader,
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
                      border: adminOrCoordOrTeamLeader ? null : InputBorder.none,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    readOnly: !adminOrCoordOrTeamLeader,
                    controller: _istIdController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ist id';
                      } else {
                        return null;
                      }
                    },
                    decoration: InputDecoration(
                      icon: const Icon(Icons.school),
                      labelText: "IstId *",
                      border: adminOrCoordOrTeamLeader ? null : InputBorder.none,
                    ),
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
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildPicture(double size) {
    Widget inkWellChild;

    if (_image == null && _prevImage == null) {
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
      String path = _image == null ? _prevImage! : _image!.path;
      inkWellChild = Center(
          child: Stack(children: <Widget>[
        Center(
          child: kIsWeb
              ? Image.network(path, fit: BoxFit.fill)
              : Image.file(File(path), fit: BoxFit.fill),
        ),
        ClipRRect(
          // Clip it cleanly.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.center,
              child: Text(
                'Change Photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ]));
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
  }

  @override
  Widget build(BuildContext context) {
    bool warning = _image != null && _size != null && _size! > 10485760;
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1000) {
            return Column(
              children: [
                _buildPicture(constraints.maxWidth / 3),
                warning
                    ? Text(
                        'Image selected is too big!',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      )
                    : Container(),
                _buildForm()
              ],
            );
          } else {
            return Column(
              children: [
                _buildPicture(constraints.maxWidth / 6),
                warning
                    ? Text(
                        'Image selected is too big!',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      )
                    : Container(),
                _buildForm()
              ],
            );
          }
        },
      ),
    );
  }
}
