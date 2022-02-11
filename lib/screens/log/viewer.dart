//https://stackoverflow.com/a/43486389
import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logk8s/models/log_line.dart';
import 'package:logk8s/models/selected_listener.dart';
import 'package:logk8s/models/selected_listeners.dart';
import 'package:logk8s/screens/clusters/cluster.dart';
import 'package:logk8s/services/auth.dart';
import 'package:logk8s/services/structures.dart';
import 'package:socket_io_client/socket_io_client.dart';

const maxLinesInMem = 100;
const msg =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum";

class LogsViewer extends StatefulWidget {
  const LogsViewer({Key? key}) : super(key: key);

  @override
  LogsViewerState createState() => LogsViewerState();
}

class LogsViewerState extends State<LogsViewer> {
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
  SelectedListeners listeners = SelectedListeners();
  Cluster cluster = Cluster();
  List<Cluster> clusters = [];
  SessionService sessionService = SessionService();
  List<Structure> clusterLogSessions = [];
  Structures structures = Structures.empty();

  LogsViewerState() {
    fetchUserState();
  }

  connectClusterSocket(Cluster cluster) {
    String wsURL = 'ws://' + cluster.domain + ':' + cluster.port.toString();
    socket = io(
        wsURL, //'ws://localhost:3000',
        OptionBuilder()
            .setExtraHeaders({'Authorization': _authService.userId}).build());

    socket.on('logline', (data) {
      //debugPrint(data);
      final ll = LogLine.fromJson(json.decode(data));
      addLogLine(ll);
    });

    socket.on('connect', (data) {
      debugPrint('connect');
      setState(() {});
    });

    socket.on("disconnect", (reason) {
      debugPrint('disconnect reason ' + reason);
      setState(() {
        resetState();
      });
    });

    socket.on('connected', (data) {
      debugPrint('connected as ' + data);
      structure(cluster);
      fetchSessions();
    });

    socket.on('structure', (data) {
      setState(() {
        k8sStructure = json.encode(data);
        namespaces = [];
        namespace2pods = {};
        pod2Containers = {};
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
        structures = Structures(cluster.name, namespaces, namespace2pods, pod2Containers);
      });
    });
  }

  fetchUserState() async {
    var uid = FirebaseAuth.instance.currentUser?.uid;
    CollectionReference clustersCollection =
        FirebaseFirestore.instance.collection('clusters');
    await clustersCollection
        .where('uid', isEqualTo: uid)
        .get()
        .then((value) => {
              value.docs.forEach((document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                setState(() {
                  var c = Cluster();
                  c.docid = document.id;
                  c.uid = data['uid'];
                  c.domain = data['domain'];
                  c.secret = data['secret'];
                  c.port = data['port'];
                  c.name = data['name'];
                  clusters.add(c);
                });
              })
            });
    if (clusters.isNotEmpty) {
      setState(() {
        cluster = clusters.first;
        connectClusterSocket(cluster);
      });
    }
  }

  fetchSessions() async {
    clusterLogSessions = await sessionService.getUserSessions();
    for (final logSession in clusterLogSessions) {
      Structure ls = logSession;
      if (ls.clusters.isNotEmpty) {
        var logCluster = ls.clusters.first;
        Cluster cluster = clusters.first;
        if (cluster.name == logCluster.name) {
          for (var ns in logCluster.namespaces) {
            for (var pd in ns.pods) {
              for (var ct in pd.containers) {
                var sl = SelectedListener(
                    cluster: cluster.name,
                    namespace: ns.name,
                    pod: pd.name,
                    container: ct.name);
                listeners.addSelectedListener(sl);
                //debugPrint('addListener - ' + json.encode({'subject': 'listen', 'listener': sl}));
                socket.emit('structure',
                    json.encode({'subject': 'listen', 'listener': sl}));
              }
            }
          }
        }
      }
    }
  }

  void resetState() {
    namespace = "";
    pod = "";
    container = "";
    namespaces = [];
    selectedNamespases = [];
    namespace2pods = {};
    pod2Containers = {};
    //listeners = SelectedListeners();
    cluster = Cluster();
    //clusters = [];
  }

  @override
  void dispose() {
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

  testSession() {
    debugPrint('Sessions test');
    Structure logSession = Structure(_authService.uid, 'Default', [
      ClusterData('q0faItIC4nZHbyoWEY3i', 'moshe mac', [
        NamespaceData('emitters', [
          PodData('pod_emitter', [ContainerData('container_emitter')])
        ])
      ])
    ]);
    SessionService sessionService = SessionService();
    sessionService.createUserSession(logSession);
    //setState(() {});
  }

  structure(Cluster cluster) {
    socket.emit('structure', json.encode({'subject': 'structure'}));
  }

  testMessage() {
    socket.emit('message', 'test');
  }

  addListener() async {
    final uid = _authService.uid;
    var listener = SelectedListener(
        cluster: cluster.name,
        namespace: namespace,
        pod: pod,
        container: container);
    if (listeners.contains(listener)) {
      debugPrint('listener already exist');
    } else {
      debugPrint('addListener - ' +
          json.encode({'subject': 'listen', 'listener': listener}));
      listeners.addSelectedListener(listener);
      socket.emit('structure',
          json.encode({'subject': 'listen', 'listener': listener}));

      if (clusterLogSessions.isEmpty) {
        List<ContainerData> logContainer = [ContainerData(container)];
        List<PodData> logPods = [PodData(pod, logContainer)];
        List<NamespaceData> logNamespace = [NamespaceData(namespace, logPods)];
        List<ClusterData> logClusters = [
          ClusterData(cluster.docid, cluster.name, logNamespace)
        ];
        sessionService
            .createUserSession(Structure(uid, 'default', logClusters));
      } else {
        List<Structure> sessions = await sessionService.getUserSessions();
        if (sessions.length > 1) {
          debugPrint('sessions.length > 1');
        } else {
          Structure logSession = sessions.first;
          bool changed = logSession.add(cluster, namespace, pod, container);
          if (changed) {
            sessionService.updateUserSession(logSession);
          }
        }
      }
    }
  }

  removeListener() {
    var listener = SelectedListener(
        cluster: cluster.name,
        namespace: namespace,
        pod: pod,
        container: container);
    if (!listeners.contains(listener)) {
      debugPrint('listener not exist');
    } else {
      debugPrint('removeListener - ' +
          json.encode({'subject': 'stop', 'listener': listener}));
      listeners.removeSelectedListener(listener);
      socket.emit(
          'structure', json.encode({'subject': 'stop', 'listener': listener}));
    }
  }

  final ScrollController _scrollController = ScrollController();

  clusterSelected(String? value) {
    debugPrint('clusterSelected: ' + value!);
    // setState(() {
    //   cluster = clusters.firstWhere((cluster) => cluster.name == value);
    //   debugPrint('cluster name Selected: ' + cluster.name);
    //   structure(cluster);
    //   namespace = "";
    //   pod = "";
    //   container = "";
    // });
  }

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

  Widget clustersDropdown(
      BuildContext context, Function(String?) clusterSelected) {
    var clustersDropdown = DropdownButton<String>(
      items: clusters.map<DropdownMenuItem<String>>((Cluster cluster) {
        return DropdownMenuItem<String>(
          value: cluster.name,
          child: Text(cluster.name),
        );
      }).toList(),
      onChanged: (_value) => clusterSelected(_value),
      icon: const Icon(Icons.arrow_drop_down),
      elevation: 16,
      style: const TextStyle(color: Colors.brown),
      underline: Container(
        height: 2,
        color: Colors.brown[50],
      ),
      hint: const Text("Select Cluster"),
    );

    if (cluster.name != "") {
      clustersDropdown = DropdownButton<String>(
        items: clusters.map<DropdownMenuItem<String>>((Cluster cluster) {
          return DropdownMenuItem<String>(
            value: cluster.name,
            child: Text(cluster.name),
          );
        }).toList(),
        onChanged: (_value) => clusterSelected(_value),
        value: cluster.name,
        icon: const Icon(Icons.arrow_drop_down),
        elevation: 16,
        style: const TextStyle(color: Colors.brown),
        underline: Container(
          height: 2,
          color: Colors.brown[50],
        ),
        hint: const Text("Select Cluster"),
      );
    }
    return clustersDropdown;
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
                  var res = await Navigator.pushNamed(context, '/clusters');
                  debugPrint('Im back ' + res.toString());
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
                        clustersDropdown(context, clusterSelected),
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
                          child: const Text("Session"),
                          onPressed: testSession,
                        ),
                        ElevatedButton(
                          child: const Text("Structure"),
                          onPressed: () {
                            Navigator.pushNamed(context, '/structures',
                                arguments: structures);
                          },
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
