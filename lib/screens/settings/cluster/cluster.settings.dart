import 'package:flutter/material.dart';
import 'package:logk8s/services/auth.dart';

class Prefrences extends StatefulWidget {
  const Prefrences({Key? key}) : super(key: key);

  @override
  PrefrencesState createState() => PrefrencesState();
}

class PrefrencesState extends State<Prefrences> {
  final AuthService _authService = AuthService();

  PrefrencesState();

  @override
  Widget build(BuildContext context) {
  final ScrollController _scrollController = ScrollController();
    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: const Text('Prefrences'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                },
                icon: const Icon(Icons.person),
                label: const Text('Logout'),
                style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                ),
              ),
            )
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black26,
          ),
          child: Column(
            children: [
              Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.brown[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              //iconSize: 42,
                              color: Colors.brown[400],
                              icon: const Icon(Icons.post_add),
                              tooltip: 'Add to track logs',
                              onPressed: () {},
                            ),
                            IconButton(
                              //iconSize: 36,
                              color: Colors.brown[400],
                              icon: const Icon(Icons.delete),
                              tooltip: "Remove tracking",
                              onPressed: () {},
                            ),
                          ],
                        )
                      ],
                    ),
                  )),
              Expanded(
                  flex: 20,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.brown[50],
                    child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        primary: false,
                        reverse: true,
                        controller: _scrollController,
                        child: Wrap(
                            direction: Axis.horizontal,
                            spacing: 1,
                            runSpacing: 1,
                            children: const []
                        )
                    )
                  )),
              Expanded(
                flex: 2,
                child: Container(
                    color: Colors.brown[100],
                    child: Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [],
                    ))),
              )
            ],
          ),
        ));
  }
}
