import 'package:flutter/widgets.dart';
import 'package:frontend/models/member.dart';
import 'package:frontend/routes/HomeScreen.dart';
import 'package:frontend/routes/LoginScreen.dart';
import 'package:provider/provider.dart';

class WrapperPage extends StatelessWidget {
  const WrapperPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Member? u = Provider.of<Member?>(context);

    if (u == null) {
      return LoginScreen();
    } else {
      return HomeScreen();
    }
  }
}
