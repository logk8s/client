//https://stackoverflow.com/a/43486389
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:logk8s/models/log_line.dart';
import 'package:logk8s/services/auth.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  Socket socket;

  // final channel = WebSocketChannel.connect(
  //   //Uri.parse('wss://echo.websocket.org'),
  //   Uri.parse('ws://localhost:3000')
  // );

  HomeState() : socket = io('ws://localhost:3000') {
    socket.on('message', (data) => debugPrint(data));

    for (var i = 0; i < 100; i++) {
      lines.add(LogLine(
          cluster: "cluster1",
          timestamp: DateTime.now().microsecondsSinceEpoch,
          namespace: "namespace",
          pod: "pod" + i.toString(),
          ip: "0.0.0.0",
          port: 27001,
          level: "debug",
          line: msg));
    }

    //socket.on('msgToClient', (_) => debugPrint(_));
    // channel.stream.listen((event) {
    //   debugPrint("HI");
    // });
  }

  @override
  void dispose() {
    // channel.sink.close();
    super.dispose();
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

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;

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
              Expanded(flex: 2, child: Container(color: Colors.brown[100])),
              Expanded(
                  flex: 20,
                  child: Container(
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
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: const Text(" Add Log Line "),
                          onPressed: generateAndAddLine,
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

    return Column(
      children: [
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            //text: 'Hello', // default text style
            children: <TextSpan>[
              timestamp,
              semicolon,
              level,
              space,
              cluster,
              direct,
              namespace,
              direct,
              pod,
              openSegment,
              ip,
              semicolonNs,
              port,
              closeSegment,
              dash,
              theLine
            ],
          ),
        ),
      ],
    );
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
