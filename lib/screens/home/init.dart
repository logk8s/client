import 'package:flutter/material.dart';

class Init extends StatelessWidget {
  const Init({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.brown[400],
        elevation: 0.0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: TextButton.icon(
              onPressed: () async {
                //await _authService.signOut();
              },
              icon: const Icon(Icons.person),
              label: const Text('Logout'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
            ),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [Text('Initializing')],
        ),
      ),
    );
  }
}




