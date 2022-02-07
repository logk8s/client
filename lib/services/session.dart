import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logk8s/screens/clusters/cluster.dart';
import 'package:logk8s/services/auth.dart';

class LogCluster {
  String name;
  String cid;
  late List<LogNamespace> namespaces;

  LogCluster(this.cid, this.name, this.namespaces);
  LogCluster.empty(this.cid, this.name) {
    namespaces = [];
  }

  LogNamespace getNamespace(String name) {
    return namespaces.firstWhere((cluster) => cluster.name == name,
        orElse: () => LogNamespace("", []));
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cid': cid,
      'namespaces': namespaces.map((namespace) {
        return namespace.toMap();
      }).toList(),
    };
  }

  LogCluster.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        cid = map['cid'],
        namespaces = map['namespaces'].map<LogNamespace>((namespace) {
          return LogNamespace.fromMap(namespace);
        }).toList();

  bool add(String namespace, String pod, String container) {
    bool changed = false;
    LogNamespace logNamespace = getNamespace(namespace);
    if (namespace != logNamespace.name) {
      logNamespace = LogNamespace.empty(namespace);
      namespaces.add(logNamespace);
      changed = true;
    }
    return logNamespace.add(pod, container) || changed;
  }
}

class LogNamespace {
  String name;
  late List<LogPod> pods;

  LogNamespace(this.name, this.pods);
  LogNamespace.empty(this.name) {
    pods = [];
  }

  LogPod getPod(String name) {
    return pods.firstWhere((cluster) => cluster.name == name,
        orElse: () => LogPod("", []));
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pods': pods.map((pod) {
        return pod.toMap();
      }).toList(),
    };
  }

  LogNamespace.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        pods = map['pods'].map<LogPod>((pod) {
          return LogPod.fromMap(pod);
        }).toList();

  bool add(String pod, String container) {
    bool changed = false;
    LogPod logPod = getPod(pod);
    if (pod != logPod.name) {
      logPod = LogPod.empty(pod);
      pods.add(logPod);
      changed = true;
    }
    return logPod.add(container) || changed;
  }
}

class LogPod {
  String name;
  late List<LogContainer> containers;

  LogPod(this.name, this.containers);
  LogPod.empty(this.name) {
    containers = [];
  }

  LogContainer getContainer(String name) {
    return containers.firstWhere((cluster) => cluster.name == name,
        orElse: () => LogContainer(""));
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'containers': containers.map((container) {
        return container.toMap();
      }).toList(),
    };
  }

  LogPod.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        containers = map['containers'].map<LogContainer>((c) {
          final lc = LogContainer.fromMap(c);
          return lc;
        }).toList();

  bool add(String container) {
    LogContainer logContainer = getContainer(container);
    if (container != logContainer.name) {
      logContainer = LogContainer(container);
      containers.add(logContainer);
      return true;
    }
    return false;
  }
}

class LogContainer {
  String name;

  LogContainer(this.name);

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  LogContainer.fromMap(Map<dynamic, dynamic> map) : name = map['name'];
}

class LogSession {
  String uid;
  String name;
  String docid = "";
  List<LogCluster> clusters;

  LogSession(this.uid, this.name, this.clusters);

  LogCluster getCluster(String name) {
    return clusters.firstWhere((cluster) => cluster.name == name,
        orElse: () => LogCluster("", "", []));
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'clusters': clusters.map((cluster) {
        return cluster.toMap();
      }).toList(),
    };
  }

  LogSession.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        uid = map['uid'],
        clusters = map['clusters'].map<LogCluster>((cluster) {
          return LogCluster.fromMap(cluster);
        }).toList();

  bool add(Cluster cluster, String namespace, String pod, String container) {
    bool changed = false;
    LogCluster logCluster = getCluster(cluster.name);
    if (cluster.name != logCluster.name) {
      logCluster = LogCluster.empty(cluster.name, cluster.docid);
      clusters.add(logCluster);
      changed = true;
    }
    return logCluster.add(namespace, pod, container) || changed;
  }
}

class SessionService {
  late final String? uid;
  late final AuthService authService;
  SessionService() {
    authService = AuthService();
    uid = authService.uid;
  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference get sessions => firestore.collection('sessions');

  Future createUserSession(LogSession session) async {
    return await sessions.add(session.toMap());
  }

  Future updateUserSession(LogSession session) async {
    return await sessions.doc(session.docid).update(session.toMap());
  }

  Future<List<LogSession>> getUserSessions() async {
    return sessions.where('uid', isEqualTo: uid).get().then((value) {
      List<LogSession> userSessions = [];
      for (final document in value.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        var s = LogSession.fromMap(data);
        userSessions.add(s);
      }
      return userSessions;
    });
  }
}
