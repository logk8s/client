import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logk8s/models/logk8s_user.dart';
import 'package:logk8s/screens/clusters/cluster.dart';
import 'package:logk8s/services/auth.dart';
import 'package:logk8s/services/database.dart';
import 'package:provider/provider.dart';

class Clusters extends StatefulWidget {
  const Clusters({Key? key}) : super(key: key);

  @override
  ClustersState createState() => ClustersState();
}

class ClusterFromDialog extends StatefulWidget {
  final String title;
  final Cluster cluster;

  ClusterFromDialog(this.title, this.cluster);

  @override
  State<ClusterFromDialog> createState() => _ClusterFromDialogState();
}

class _ClusterFromDialogState extends State<ClusterFromDialog> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final clusterAddformKey = GlobalKey<FormState>();
  //Cluster cluster = Cluster();
  late bool loading;
  late String error;

  _addClusterForm() => Container(
        color: Colors.brown[50],
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        child: Form(
          key: clusterAddformKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: widget.cluster.name,
                decoration: const InputDecoration(labelText: 'Cluster Name'),
                validator: (val) => val!.isEmpty
                    ? 'Name can not be empty'
                    : val.length < 3
                        ? 'Name should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => widget.cluster.name = val!),
              ),
              TextFormField(
                initialValue: widget.cluster.domain,
                decoration: const InputDecoration(labelText: 'IP/Domain'),
                validator: (val) => val!.isEmpty
                    ? 'IP/Domain can not be empty'
                    : val.length < 3
                        ? 'IP/Domain should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => widget.cluster.domain = val!),
              ),
              TextFormField(
                initialValue: widget.cluster.port.toString(),
                decoration: const InputDecoration(labelText: 'Port'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                validator: (val) =>
                    int.parse(val!) < 0 || int.parse(val) > 65535
                        ? 'Should be between 0 and 65535'
                        : null,
                onSaved: (val) =>
                    setState(() => widget.cluster.port = int.parse(val!)),
              ),
              TextFormField(
                initialValue: widget.cluster.secrete,
                decoration: const InputDecoration(labelText: 'Secrete'),
                validator: (val) => val!.isEmpty
                    ? 'Secrete can not be empty'
                    : val.length < 3
                        ? 'Secrete should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => widget.cluster.secrete = val!),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () async {
                    var form = clusterAddformKey.currentState;
                    if (form!.validate()) {
                      form.save();

                      setState(() {
                        loading = true;
                      });
                      var result = await _authService.updateCluster();
                      if (result == null) {
                        setState(() {
                          error = 'Failed to register';
                          loading = false;
                        });
                      }
                      form.reset();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update cluster'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.brown[900], // background
                    onPrimary: Colors.white, // foreground
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[50],
        title: Text(widget.title),
      ),
      body: Center(
        child: _addClusterForm(),
      ),
    );
  }
}

class ClustersState extends State<Clusters> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final clusterAddformKey = GlobalKey<FormState>();
  Cluster cluster = Cluster();
  List<Cluster> clusters = [];

  late bool loading;
  late String error;

  ClustersState() {
    loading = false;
    error = '';
    // for (int i = 0; i < 10; i++) {
    //   Cluster newCluster = Cluster();
    //   newCluster.domain = 'domain' + i.toString();
    //   newCluster.name = 'name' + i.toString();
    //   newCluster.port = i + 1000;
    //   newCluster.secrete = 'secrete' + i.toString();
    //   clusters.add(newCluster);
    // }
  }

  printState() {}

  navigatePreferences(String to) {
    setState(() {
      switch (to) {
        case "User":
          break;
        case "Organization":
          break;
        case "Account":
          break;
        case "Usage":
          break;
        case "Clusters":
          break;
      }
    });
  }

  Widget prefrenceTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
      child: Text(title,
          style: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.brown)),
    );
  }

  Widget ipPortStr(String ip, int port) {
    return RichText(
      text: TextSpan(
        text: ip,
        style: const TextStyle(color: Colors.brown),
        children: <TextSpan>[
          const TextSpan(
            text: ':',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: port.toString(),
            style: const TextStyle(color: Colors.brown),
          ),
        ],
      ),
    );
  }

  _crudClusterList() => Expanded(
        child: Card(
          margin: const EdgeInsets.fromLTRB(20, 30, 20, 0),
          child: Scrollbar(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                return Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(
                        Icons.dns_rounded,
                        color: Colors.brown,
                        size: 40.0,
                      ),
                      title: Text(
                        clusters[index].name,
                        style: const TextStyle(
                            color: Colors.brown, fontWeight: FontWeight.bold),
                      ),
                      subtitle: ipPortStr(
                          clusters[index].domain, clusters[index].port),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 20.0,
                              color: Colors.brown[900],
                            ),
                            onPressed: () {
                              debugPrint('index:' + index.toString());

                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      ClusterFromDialog(
                                          "Edit cluster", clusters[index]),
                                  //, _addClusterForm),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20.0,
                              color: Colors.brown[900],
                            ),
                            onPressed: () {
                              debugPrint('index:' + index.toString());

                              //   _onDeleteItemPressed(index);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        debugPrint('ontap');
                      },
                    ),
                    const Divider(
                      height: 5.0,
                    )
                  ],
                );
              },
              itemCount: clusters.length,
            ),
          ),
        ),
      );

  _addClusterForm() => Container(
        color: Colors.brown[50],
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        child: Form(
          key: clusterAddformKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Cluster Name'),
                validator: (val) => val!.isEmpty
                    ? 'Name can not be empty'
                    : val.length < 3
                        ? 'Name should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => cluster.name = val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'IP/Domain'),
                validator: (val) => val!.isEmpty
                    ? 'IP/Domain can not be empty'
                    : val.length < 3
                        ? 'IP/Domain should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => cluster.domain = val!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Port'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
                validator: (val) =>
                    int.parse(val!) < 0 || int.parse(val) > 65535
                        ? 'Should be between 0 and 65535'
                        : null,
                onSaved: (val) =>
                    setState(() => cluster.port = int.parse(val!)),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Secrete'),
                validator: (val) => val!.isEmpty
                    ? 'Secrete can not be empty'
                    : val.length < 3
                        ? 'Secrete should be at least 3 charecters long'
                        : null,
                onSaved: (val) => setState(() => cluster.secrete = val!),
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () async {
                    var form = clusterAddformKey.currentState;
                    if (form!.validate()) {
                      form.save();

                      setState(() {
                        loading = true;
                      });

                      cluster.uid = _authService.uid;
                      var docRef = await _db.createCluster(cluster);
                      setState(() {
                        if (docRef == null) {
                          error = 'Failed to register';
                          return;
                        }
                        loading = false;
                        cluster.docid = docRef.id;
                        clusters.add(cluster);
                        form.reset();
                      });
                    }
                  },
                  child: const Text('Add cluster'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.brown[900], // background
                    onPrimary: Colors.white, // foreground
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget buildPrefrence(String title, List<Widget> children) {
    return Container(
        color: Colors.brown[50],
        child: Column(children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [prefrenceTitle(title)]),
          ...children
        ]));
  }

  Widget getClustersPreference() {
    return buildPrefrence(
        "Clusters Clusters", [_addClusterForm(), _crudClusterList()]);
  }

  Widget clustersMenuButton(Icon icon, String text, onPressed) {
    return Column(children: [
      IconButton(
        iconSize: 40,
        color: Colors.brown[400],
        icon: icon,
        tooltip: text,
        onPressed: onPressed,
      ),
      Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    //final ScrollController _scrollController = ScrollController();
    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
          title: const Text('Clusters'),
          backgroundColor: Colors.brown[400],
          elevation: 0.0,
          actions: <Widget>[
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
              Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.brown[100],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              clustersMenuButton(
                                  const Icon(Icons.group_add), "User", () {
                                debugPrint('Display User Clusters');
                                navigatePreferences("User");
                              }),
                              clustersMenuButton(
                                  const Icon(Icons.business), "Organization",
                                  () {
                                debugPrint('Display Organization Clusters');
                                navigatePreferences("Organization");
                              }),
                              clustersMenuButton(
                                  const Icon(Icons.manage_accounts), "Account",
                                  () {
                                debugPrint('Display Account Clusters');
                                navigatePreferences("Account");
                              }),
                              clustersMenuButton(
                                  const Icon(Icons.analytics), "Usage", () {
                                debugPrint('Display Usage Clusters');
                                navigatePreferences("Usage");
                              }),
                              clustersMenuButton(
                                  const Icon(Icons.dns), "Clusters", () {
                                debugPrint('Display Clusters Clusters');
                                navigatePreferences("Clusters");
                              }),
                            ])
                      ],
                    ),
                  )),
              Expanded(flex: 20, child: getClustersPreference()),
              Expanded(
                flex: 2,
                child: Container(
                    color: Colors.brown[100],
                    child: Center(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [],
                    ))),
              )
            ],
          ),
        ));
  }
}
