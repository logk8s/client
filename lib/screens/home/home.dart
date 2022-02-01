//https://stackoverflow.com/a/43486389
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logk8s/models/log_line.dart';
import 'package:logk8s/models/selected_listener.dart';
import 'package:logk8s/models/selected_listeners.dart';
import 'package:logk8s/screens/settings/preferences/prefrences.dart';
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
  String pod = "";
  String container = "";
  List<String> namespaces = [];
  List<String> selectedNamespases = [];
  Map<String, List<String>> namespace2pods = {};
  Map<String, List<String>> pod2Containers = {};
  SelectedListeners listens = SelectedListeners();

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

    socket.on('connect', (data) {
      debugPrint('connect');
      setState(() {
        resetState();
      });
    });

    socket.on("disconnect", (reason) {
      debugPrint('disconnect reason ' + reason);
      setState(() {
        resetState();
      });
    });

    socket.on('connected', (data) {
      debugPrint('connected as ' + data);
      structure();
    });

    socket.on('structure', (data) {
      setState(() {
        k8sStructure = json.encode(data);
        namespaces = [];
        namespace2pods = {};
        data['namespaces'].forEach((k, v) {
          namespaces.add(k);
          debugPrint(json.encode(k));
        });
        data['namespace2podNames'].forEach((ns, pd) {
          if (!namespace2pods.containsKey(ns)) {
            namespace2pods[ns] = [];
          }
          pd.forEach((podName) {
            namespace2pods[ns]!.add(podName);
          });
        });
        data["podContainers"].forEach((pod, containers) {
          if (!pod2Containers.containsKey(pod)) {
            pod2Containers[pod] = [];
          }
          containers.forEach((containerName) {
            pod2Containers[pod]!.add(containerName);
          });
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

  void resetState() {
    namespace = "";
    pod = "";
    container = "";
    namespaces = [];
    selectedNamespases = [];
    namespace2pods = {};
    pod2Containers = {};
    listens = SelectedListeners();
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
    //TODO: Send acknowllegment
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

  testMessage() {
    socket.emit('message', 'test');
  }

  addListener() {
    var listener =
        SelectedListener(namespace: namespace, pod: pod, container: container);
    if (listens.contains(listener)) {
      debugPrint('listener already exist');
    } else {
      debugPrint('addListener - ' +
          json.encode({'subject': 'listen', 'listener': listener}));
      listens.addSelectedListener(listener);
      socket.emit('structure',
          json.encode({'subject': 'listen', 'listener': listener}));
    }
  }

  removeListener() {
    var listener =
        SelectedListener(namespace: namespace, pod: pod, container: container);
    if (!listens.contains(listener)) {
      debugPrint('listener not exist');
    } else {
      debugPrint('removeListener - ' +
          json.encode({'subject': 'listen', 'listener': listener}));
      listens.removeSelectedListener(listener);
      socket.emit('structure',
          json.encode({'subject': 'remove', 'listener': listener}));
    }
  }

  final ScrollController _scrollController = ScrollController();

  namespaceSelected(String? value) {
    debugPrint('namespaceSelected: ' + value!);
    setState(() {
      namespace = value;
      pod = "";
      container = "";
    });
  }

  podSelected(String? value) {
    debugPrint('podSelected: ' + value!);
    setState(() {
      pod = value;
      container = "";
    });
  }

  containerSelected(String? value) {
    debugPrint('containerSelected: ' + value!);
    setState(() {
      container = value;
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

    if (namespace != "") {
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

  Widget podsDropdown(BuildContext context, Function(String?) podSelected) {
    if (namespace == "") {
      return DropdownButton<String>(
        items: <String>[].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_value) => podSelected(_value),
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.brown),
        underline: Container(
          height: 2,
          color: Colors.brown[50],
        ),
        hint: const Text("Select Pod"),
      );
    }
    if (pod == "") {
      return DropdownButton<String>(
        items: namespace2pods[namespace]!
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_value) => podSelected(_value),
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.brown),
        underline: Container(
          height: 2,
          color: Colors.brown[50],
        ),
        hint: const Text("Select Pod"),
      );
    }
    return DropdownButton<String>(
      items: namespace2pods[namespace]!
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (_value) => podSelected(_value),
      value: pod,
      icon: const Icon(Icons.arrow_drop_down),
      elevation: 16,
      style: const TextStyle(color: Colors.brown),
      underline: Container(
        height: 2,
        color: Colors.brown[50],
      ),
      hint: const Text("Select Pod"),
    );
  }

  Widget containerssDropdown(
      BuildContext context, Function(String?) containerSelected) {
    if (pod == "") {
      return DropdownButton<String>(
        items: <String>[].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_value) => containerSelected(_value),
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.brown),
        underline: Container(
          height: 2,
          color: Colors.brown[50],
        ),
        hint: const Text("Select Container"),
      );
    }
    if (container == "") {
      return DropdownButton<String>(
        items:
            pod2Containers[pod]!.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (_value) => containerSelected(_value),
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.brown),
        underline: Container(
          height: 2,
          color: Colors.brown[50],
        ),
        hint: const Text("Select Pod"),
      );
    }
    return DropdownButton<String>(
      items: pod2Containers[pod]!.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (_value) => containerSelected(_value),
      value: container,
      icon: const Icon(Icons.arrow_drop_down),
      elevation: 16,
      style: const TextStyle(color: Colors.brown),
      underline: Container(
        height: 2,
        color: Colors.brown[50],
      ),
      hint: const Text("Select Container"),
    );
  }

  @override
  Widget build(BuildContext context) {
    // double width = MediaQuery.of(context).size.width;

    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: const Text('Log Viewer'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                onPressed: () async {
                  //see https://docs.flutter.dev/cookbook/navigation/named-routes
                  Navigator.pushNamed(context, '/clusters');
                },
                icon: const Icon(Icons.settings),
                tooltip: 'Prefrences',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                onPressed: () async {
                  await _authService.signOut();
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
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
                        namespacesDropdown(context, namespaceSelected),
                        podsDropdown(context, podSelected),
                        containerssDropdown(context, containerSelected),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              //iconSize: 42,
                              color: Colors.brown[400],
                              icon: const Icon(Icons.post_add),
                              tooltip: 'Add to track logs',
                              onPressed: addListener,
                            ),
                            IconButton(
                              //iconSize: 36,
                              color: Colors.brown[400],
                              icon: const Icon(Icons.delete),
                              tooltip: "Remove tracking",
                              onPressed: removeListener,
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
                          child: const Text(" Message "),
                          onPressed: testMessage,
                        ),
                        //TODO: #1 Multiselect, use multi_select_flutter or DropDownMultiSelect

                        // SizedBox(
                        //   height: 50.0,
                        //   width: 100.0,
                        //   child: DropDownMultiSelect(
                        //     onChanged: (List<String> x) {
                        //       setState(() {
                        //         //selected = x;
                        //       });
                        //     },
                        //     options: const ['a', 'b', 'c', 'd'],
                        //     selectedValues: const ['a'],
                        //     whenEmpty: 'Select Something',
                        //   ),
                        // )
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
