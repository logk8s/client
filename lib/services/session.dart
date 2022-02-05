import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logk8s/services/auth.dart';

class LogCluster {
  String name;
  String cid;
  List<LogNamespace> namespaces;

  LogCluster(this.cid, this.name, this.namespaces);

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
}

class LogNamespace {
  String name;
  List<LogPod> pods;

  LogNamespace(this.name, this.pods);

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
}

class LogPod {
  String name;
  List<LogContainer> containers;

  LogPod(this.name, this.containers);

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
  String docid = "";
  String name;
  List<LogCluster> clusters;

  LogSession(this.uid, this.name, this.clusters);

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
