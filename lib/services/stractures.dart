import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logk8s/screens/clusters/cluster.dart';
import 'package:logk8s/services/auth.dart';

class ClusterData {
  String name;
  String cid;
  late List<NamespaceData> namespaces;

  ClusterData(this.cid, this.name, this.namespaces);
  ClusterData.empty(this.cid, this.name) {
    namespaces = [];
  }

  NamespaceData getNamespace(String name) {
    return namespaces.firstWhere((cluster) => cluster.name == name,
        orElse: () => NamespaceData("", []));
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

  ClusterData.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        cid = map['cid'],
        namespaces = map['namespaces'].map<NamespaceData>((namespace) {
          return NamespaceData.fromMap(namespace);
        }).toList();

  bool add(String namespace, String pod, String container) {
    bool changed = false;
    NamespaceData logNamespace = getNamespace(namespace);
    if (namespace != logNamespace.name) {
      logNamespace = NamespaceData.empty(namespace);
      namespaces.add(logNamespace);
      changed = true;
    }
    return logNamespace.add(pod, container) || changed;
  }
}

class NamespaceData {
  String name;
  late List<PodData> pods;

  NamespaceData(this.name, this.pods);
  NamespaceData.empty(this.name) {
    pods = [];
  }

  PodData getPod(String name) {
    return pods.firstWhere((cluster) => cluster.name == name,
        orElse: () => PodData("", []));
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pods': pods.map((pod) {
        return pod.toMap();
      }).toList(),
    };
  }

  NamespaceData.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        pods = map['pods'].map<PodData>((pod) {
          return PodData.fromMap(pod);
        }).toList();

  bool add(String pod, String container) {
    bool changed = false;
    PodData logPod = getPod(pod);
    if (pod != logPod.name) {
      logPod = PodData.empty(pod);
      pods.add(logPod);
      changed = true;
    }
    return logPod.add(container) || changed;
  }
}

class PodData {
  String name;
  late List<ContainerData> containers;

  PodData(this.name, this.containers);
  PodData.empty(this.name) {
    containers = [];
  }

  ContainerData getContainer(String name) {
    return containers.firstWhere((cluster) => cluster.name == name,
        orElse: () => ContainerData(""));
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'containers': containers.map((container) {
        return container.toMap();
      }).toList(),
    };
  }

  PodData.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        containers = map['containers'].map<ContainerData>((c) {
          final lc = ContainerData.fromMap(c);
          return lc;
        }).toList();

  bool add(String container) {
    ContainerData logContainer = getContainer(container);
    if (container != logContainer.name) {
      logContainer = ContainerData(container);
      containers.add(logContainer);
      return true;
    }
    return false;
  }
}

class ContainerData {
  String name;

  ContainerData(this.name);

  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  ContainerData.fromMap(Map<dynamic, dynamic> map) : name = map['name'];
}

class Stracture {
  String uid;
  String name;
  String docid = "";
  List<ClusterData> clusters;

  Stracture(this.uid, this.name, this.clusters);

  ClusterData getCluster(String name) {
    return clusters.firstWhere((cluster) => cluster.name == name,
        orElse: () => ClusterData("", "", []));
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

  Stracture.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'],
        uid = map['uid'],
        clusters = map['clusters'].map<ClusterData>((cluster) {
          return ClusterData.fromMap(cluster);
        }).toList();

  bool add(Cluster cluster, String namespace, String pod, String container) {
    bool changed = false;
    ClusterData logCluster = getCluster(cluster.name);
    if (cluster.name != logCluster.name) {
      logCluster = ClusterData.empty(cluster.name, cluster.docid);
      clusters.add(logCluster);
      changed = true;
    }
    return logCluster.add(namespace, pod, container) || changed;
  }
}

class Stractures {
  String cluster;
  List<String> namespaces;
  Map<String, List<String>> namespace2pods;
  Map<String, List<String>> pod2containers;

  Stractures(final this.cluster, final this.namespaces, final this.namespace2pods, final this.pod2containers);

  static Stractures empty() {
    return Stractures('', [], {}, {});
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

  Future createUserSession(Stracture session) async {
    return await sessions.add(session.toMap());
  }

  Future updateUserSession(Stracture session) async {
    return await sessions.doc(session.docid).update(session.toMap());
  }

  Future<List<Stracture>> getUserSessions() async {
    return sessions.where('uid', isEqualTo: uid).get().then((value) {
      List<Stracture> userSessions = [];
      for (final document in value.docs) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        var s = Stracture.fromMap(data);
        userSessions.add(s);
      }
      return userSessions;
    });
  }
}
