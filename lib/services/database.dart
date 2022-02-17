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
      'secret': cluster.secret,
    });
  }

  //see: https://stackoverflow.com/questions/59017373/how-to-update-collection-documents-in-firebase-in-flutter
  // var collection = FirebaseFirestore.instance.collection('collection');
  // collection
  //     .doc('some_id') // <-- Doc ID where data should be updated.
  //     .update({'key' : 'value'}) // <-- Updated data
  //     .then((_) => print('Updated'))
  //     .catchError((error) => print('Update failed: $error'));
  Future updateCluster(Cluster cluster) async {
    return await clusters.doc(cluster.docid).update({
      'uid': cluster.uid,
      'domain': cluster.domain,
      'name': cluster.name,
      'port': cluster.port,
      'secret': cluster.secret,
    });
  }
}
