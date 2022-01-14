//https://stackoverflow.com/a/43486389
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logk8s/models/log_line.dart';
import 'package:logk8s/services/auth.dart';
import 'package:socket_io_client/socket_io_client.dart';

const maxLinesInMem = 100;
const msg =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum";

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  Queue<LogLine> lines = Queue<LogLine>();
  final AuthService _authService = AuthService();
  late final Socket socket;
  dynamic k8sStructure;
  String namespace = "";
  List<String> namespaces = [];
  Map<String, List<String>> pods = {};

  HomeState() {
    //socket.io.options['extraHeaders'] = {'Authorization': "Bearer authorization_token_here"};
    socket = io(
        'ws://localhost:3000',
        OptionBuilder()
            .setExtraHeaders({'Authorization': _authService.userId}).build());

    socket.on('logline', (data) {
      //debugPrint(data);
      final ll = LogLine.fromJson(json.decode(data));
      addLogLine(ll);
    });

    socket.on('structure', (data) {
      setState(() {
        k8sStructure = json.encode(data);
        data['namespaces'].forEach((k, v) {
          namespaces.add(k);
          debugPrint(json.encode(k));
        });
      });
    });

    // for (var i = 0; i < 100; i++) {
    //   lines.add(LogLine(
    //       cluster: "cluster1",
    //       timestamp: DateTime.now().microsecondsSinceEpoch,
    //       namespace: "namespace",
    //       pod: "pod" + i.toString(),
    //       ip: "0.0.0.0",
    //       port: 27001,
    //       level: "debug",
    //       line: msg));
    // }
  }

  @override
  void dispose() {
    // channel.sink.close();
    super.dispose();
  }

  addLogLine(LogLine logLine) {
    // Put your code here, which you want to execute on onPress event.
    setState(() {
      lines.add(logLine);
      if (lines.length > maxLinesInMem) {
        lines.removeFirst();
      }
    });
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
    //TODO: Send acknollegment
    //socket.emit('acknoledge', logLine.timestamp);
  }

  generateAndAddLine() {
    debugPrint('Function on Click Event Called.');
    // Put your code here, which you want to execute on onPress event.
    setState(() {
      var logLine = LogLine(
          cluster: "cluster1",
          timestamp: DateTime.now().microsecondsSinceEpoch,
          namespace: "namespace",
          pod: "pod",
          ip: "0.0.0.0",
          port: 27001,
          level: "debug",
          line: msg);
      lines.add(logLine);
      if (lines.length > maxLinesInMem) {
        lines.removeFirst();
      }
      socket.emit('message', 'test');
      // channel.sink.add('received!');
    });
    _scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  structure() {
    socket.emit('structure', json.encode({'subject': 'structure'}));
  }

  listen() {
    socket.emit('structure', json.encode({'subject': 'listen'}));
  }

  final ScrollController _scrollController = ScrollController();

  namespaceSelected(String? value) {
    debugPrint('namespaceSelected: ' + value!);
    setState(() {
      namespace = value;
    });
  }

  Widget namespacesDropdown(
      BuildContext context, Function(String?) namespaceSelected) {
    var mamespacesDropdown = DropdownButton<String>(
      items: namespaces.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (_value) => namespaceSelected(_value),
      icon: const Icon(Icons.arrow_drop_down),
      elevation: 16,
      style: const TextStyle(color: Colors.brown),
      underline: Container(
        height: 2,
        color: Colors.brown[50],
      ),
      hint: const Text("Select Namespace"),
    );

    if(namespace != "") {
      mamespacesDropdown = DropdownButton<String>(
        items: namespaces.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_value) => namespaceSelected(_value),
        value: namespace,
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.brown),
        underline: Container(
          height: 2,
          color: Colors.brown[50],
        ),
        hint: const Text("Select Namespace"),
      );
    }

    return mamespacesDropdown;
  }

  @override
  Widget build(BuildContext context) {
    // double width = MediaQuery.of(context).size.width;

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
              // Expanded(
              //   flex: 2,
              //   child: StreamBuilder(
              //       stream: channel.stream,
              //       builder: (context, snapshot) {
              //         return Text(snapshot.hasData ? '${snapshot.data}' : '');
              //       }
              //     )),
              Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.brown[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        namespacesDropdown(context, namespaceSelected)
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
                            children: lines.map((LogLine logLine) {
                              return LogLineItem(logLine: logLine);
                            }).toList())),
                  )),
              Expanded(
                flex: 2,
                child: Container(
                    color: Colors.brown[100],
                    child: Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          child: const Text(" Add Log Line "),
                          onPressed: generateAndAddLine,
                        ),
                        ElevatedButton(
                          child: const Text(" Structure "),
                          onPressed: structure,
                        ),
                        ElevatedButton(
                          child: const Text(" Listen "),
                          onPressed: listen,
                        )
                      ],
                    ))),
              )
            ],
          ),
        ));
  }
}

class LogLineItem extends StatelessWidget {
  final LogLine logLine;

  LogLineItem({
    required this.logLine,
  }) : super(key: ObjectKey(logLine));

  TextStyle stdStyle(BuildContext context) {
    return const TextStyle(
      color: Colors.black,
      overflow: TextOverflow.fade,
    );
  }

  TextStyle k8sStyle(BuildContext context) {
    return const TextStyle(
      color: Colors.black,
      overflow: TextOverflow.fade,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextSpan timestamp = TextSpan(
        text: DateTime.fromMicrosecondsSinceEpoch(logLine.timestamp).toString(),
        style: stdStyle(context));
    TextSpan cluster =
        TextSpan(text: logLine.cluster, style: stdStyle(context));
    TextSpan namespace =
        TextSpan(text: logLine.namespace, style: stdStyle(context));
    TextSpan pod = TextSpan(text: logLine.pod, style: stdStyle(context));
    TextSpan ip = TextSpan(text: logLine.ip, style: stdStyle(context));
    TextSpan port =
        TextSpan(text: logLine.port.toString(), style: stdStyle(context));
    TextSpan level = TextSpan(text: logLine.level, style: stdStyle(context));
    TextSpan theLine = TextSpan(text: logLine.line, style: stdStyle(context));
    TextSpan openSegment = TextSpan(text: ' [', style: stdStyle(context));
    TextSpan closeSegment = TextSpan(text: '] ', style: stdStyle(context));
    TextSpan semicolon = TextSpan(text: ': ', style: stdStyle(context));
    TextSpan semicolonNs = TextSpan(text: ':', style: stdStyle(context));
    TextSpan space = TextSpan(text: '  ', style: stdStyle(context));
    TextSpan direct = TextSpan(text: '->', style: stdStyle(context));
    TextSpan dash = TextSpan(text: ' - ', style: stdStyle(context));
    var children = <TextSpan>[
      timestamp,
      semicolon,
      level,
      space,
      cluster,
      direct,
      namespace,
      direct,
      pod
    ];
    if (logLine.ip != "" && logLine.port != 0) {
      children.addAll([openSegment, ip, semicolonNs, port, closeSegment]);
    }
    children.addAll([dash, theLine]);

    return Container(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: children,
                  ),
                ),
              ],
            )));
  }
}

List<LogLine> lines = [];
var layout = Container(
  decoration: const BoxDecoration(
    color: Colors.black26,
  ),
  child: Column(
    children: [
      Expanded(
          flex: 3,
          child: Container(
            color: Colors.amber[600],
          )),
      Expanded(
        flex: 20,
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            primary: false,
            child: Wrap(
                direction: Axis.horizontal,
                spacing: 1,
                runSpacing: 1,
                children: lines.map((LogLine logLine) {
                  return LogLineItem(logLine: logLine);
                }).toList())),
      ),
      Expanded(flex: 2, child: Container()),
    ],
  ),
);
