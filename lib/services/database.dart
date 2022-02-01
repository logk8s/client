import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logk8s/screens/clusters/cluster.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference get clusters => firestore.collection('clusters');
  CollectionReference get logs => firestore.collection('logs');
  CollectionReference get filters => firestore.collection('filters');
  CollectionReference get users => firestore.collection('users');

  Future updateUserData(int fico, double line) async {
    return await users.doc(uid).update({'fico': fico, 'line': line});
  }

  Future addUser() async {
    return await users.add({'userId': uid, 'created': DateTime.now()});
  }

  Future createCluster(Cluster cluster) async {
    return await clusters.add({
      'uid': cluster.uid,
      // 'docid': cluster.docid,
      'domain': cluster.domain,
      'name': cluster.name,
      'port': cluster.port,
      'secrete': cluster.secrete,
    });
  }

  // Future updateCluster(String id, Cluster cluster) async {
  //   return await clusters.doc(cluster.id).({'userId': uid});
  // }

  Future getClusters(String name) async {
    return await clusters.add({'userId': uid});
  }


}
