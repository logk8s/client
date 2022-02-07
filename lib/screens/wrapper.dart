import 'package:flutter/material.dart';
import 'package:logk8s/models/logk8s_user.dart';
import 'package:logk8s/screens/authenticate/authenticate.dart';
import 'package:logk8s/screens/log/viewer.dart';
import 'package:logk8s/services/auth.dart';
import 'package:provider/provider.dart';


class Wrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Logk8sUser>(context);
    if(_authService.isSignedIn) {
      return const LogsViewer();
    }

    if (user.uid == "") {
      return const Authenticate();
    } else {
      return const LogsViewer();
    }
  }
}
