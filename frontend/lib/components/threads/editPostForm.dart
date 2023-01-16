import 'package:flutter/material.dart';
import 'package:frontend/models/post.dart';
import 'package:frontend/services/postService.dart';

class EditPostForm extends StatefulWidget {
  final Post post;
  final void Function(BuildContext, Post?)? onEditPost;

  EditPostForm({Key? key, required this.post, required this.onEditPost})
      : super(key: key);

  @override
  _EditPostFormState createState() => _EditPostFormState();
}

class _EditPostFormState extends State<EditPostForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.post.text);
  }

  void _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      var text = _textController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editing...')),
      );

      PostService _postService = PostService();
      Post? p = await _postService.updatePost(widget.post.id, text);
      if (p != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Done'),
            duration: Duration(seconds: 2),
          ),
        );
        widget.onEditPost!(context, p);

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occured.')),
        );

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              controller: _textController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please put the contents of communication';
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
