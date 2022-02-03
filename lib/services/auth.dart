import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logk8s/models/logk8s_user.dart';
import 'package:logk8s/services/database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSignedIn = false;
  String uid = "";

  AuthService() {
    try {
      uid = FirebaseAuth.instance.currentUser!.uid;
    } catch (e) {
      uid = "";
    }
    _auth.userChanges().listen((User? user) {
      if (user == null) {
        uid = '';
        _isSignedIn = false;
      } else {
        uid = user.uid;
        _isSignedIn = true;
      }
    });
  }
  Logk8sUser _createUser(User? firebaseUser) {
    if (firebaseUser != null) {
      return Logk8sUser(firebaseUser.uid);
    }
    return Logk8sUser("");
  }

  Stream<Logk8sUser> get user {
    return _auth.authStateChanges().map(_createUser);
  }

  String get userId {
    return _auth.currentUser!.uid;
  }

  // anon sign in
  Future signInAnon() async {
    try {
      UserCredential authResult = await _auth.signInAnonymously();
      return _createUser(authResult.user);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // sign in
  Future signIn(String email, String password) async {
    try {
      UserCredential authResult = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return _createUser(authResult.user);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // sign in
  Future register(String email, String password) async {
    try {
      UserCredential credentials = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await DatabaseService(uid: credentials.user!.uid).addUser();
      return _createUser(credentials.user);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  signOut() async {
    return await _auth.signOut();
  }

  bool get isSignedIn {
    return _isSignedIn;
  }

  addCluster() {
    return true;
  }

  updateCluster() {
    return true;
  }
}
