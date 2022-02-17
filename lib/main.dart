import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logk8s/models/logk8s_user.dart';
import 'package:logk8s/screens/clusters/structure-graph-test.dart';
import 'package:logk8s/screens/init.dart';
import 'package:logk8s/screens/clusters/clusters.dart';
import 'package:logk8s/screens/error/error.dart';
import 'package:logk8s/screens/settings/preferences/prefrences.dart';
import 'package:logk8s/screens/structure/structure-view.dart';
import 'package:logk8s/screens/wrapper.dart';
import 'package:logk8s/services/auth.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

/// We are using a StatefulWidget such that we only create the [Future] once,
/// no matter how many times our widget rebuild.
/// If we used a [StatelessWidget], in the event where [App] is rebuilt, that
/// would re-initialize FlutterFire and make our application re-enter loading state,
/// which is undesired.
class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  // Create the initialization Future outside of `build`:
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  /// The future is part of the state of our widget. We should not call `initializeApp`
  /// directly inside [build].
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return const Error();
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return StreamProvider<Logk8sUser>.value(
              value: AuthService().user,
              initialData: Logk8sUser(""),
              child: MaterialApp(
                title: 'LogK8S',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  // This is the theme of your application.
                  //
                  // Try running your application with "flutter run". You'll see the
                  // application has a blue toolbar. Then, without quitting the app, try
                  // changing the primarySwatch below to Colors.green and then invoke
                  // "hot reload" (press "r" in the console where you ran "flutter run",
                  // or simply save your changes to "hot reload" in a Flutter IDE).
                  // Notice that the counter didn't reset back to zero; the application
                  // is not restarted.
                  primarySwatch: Colors.brown,
                ),
                //home: Wrapper(),
                initialRoute: '/',
                routes: {
                  '/': (context) => Wrapper(),
                  '/prefrences': (context) => const Prefrences(),
                  '/clusters': (context) => const Clusters(),
                  '/graph': (context) => StructuresViewPage(),
                  '/structures': (context) => const StructuresPage(),
                },
                onGenerateRoute: (settings) {
                  // If you push the PassArguments route
                  if (settings.name == StructuresViewPage.routeName) {
                    // Cast the arguments to the correct
                    // type: ScreenArguments.
                    //final args = settings.arguments as Structures;

                    // Then, extract the required data from
                    // the arguments and pass the data to the
                    // correct screen.
                    return MaterialPageRoute(
                      builder: (context) {
                        return StructuresViewPage();//args);
                      },
                    );
                  }
                  assert(false, 'Need to implement ${settings.name}');
                  return null;
                },

              ));
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return const Init();
      },
    );
  }
}
