import 'package:flutter/material.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/models/thread.dart';
import 'package:frontend/services/postService.dart';
import 'package:frontend/services/threadService.dart';

class EditThreadForm extends StatefulWidget {
  final Thread? thread;
  final Post? post;
  final void Function(BuildContext, Thread?)? onEditThread;

  EditThreadForm({Key? key, this.thread, this.post, this.onEditThread})
      : super(key: key);

  @override
  _EditThreadFormState createState() => _EditThreadFormState();
}

class _EditThreadFormState extends State<EditThreadForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  String kind = 'TEMPLATE';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.post!.text);
  }

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      var text = _textController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Editing...', style: TextStyle(color: Colors.white))),
      );

      PostService _postService = PostService();
      ThreadService _threadService = ThreadService();

      Post? p = await _postService.updatePost(widget.post!.id, text);
      Thread? t =
          await _threadService.updateThread(id: widget.thread!.id, kind: kind);

      if (p != null && t != null) {
        widget.onEditThread!(context, t);

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

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> kinds = ["TEMPLATE", "TO", "FROM", "PHONE_CALL", "MEETING"];
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: null,
              controller: _textController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please add the content of communication';
                }
                return null;
              },
              decoration: const InputDecoration(
                icon: const Icon(Icons.work),
                labelText: "Content *",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              icon: Icon(Icons.tag),
              items: kinds
                  .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              value: kinds[0],
              selectedItemBuilder: (BuildContext context) {
                return kinds.map((e) {
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(child: Text(e)),
                  );
                }).toList();
              },
              onChanged: (next) {
                setState(() {
                  kind = next!;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _submit(context),
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
